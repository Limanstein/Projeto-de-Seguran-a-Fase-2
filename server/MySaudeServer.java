package server;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import javax.net.ssl.*;

public class MySaudeServer {

    // Instância partilhada do MacManager — inicializada no arranque com a password de MAC
    private static MacManager macManager;

    public static void main(String[] args) throws Exception {
        System.setOut(new PrintStream(System.out, true, StandardCharsets.UTF_8));

        if (args.length != 3) {
            System.out.println("Uso: java server.MySaudeServer <porto> <keystore> <keystorePassword>");
            return;
        }

        int port            = Integer.parseInt(args[0]);
        String keystorePath = args[1];
        String keystorePass = args[2];

        File base = new File("server_storage");
        if (!base.exists()) base.mkdirs();

        // -------------------------------------------------------
        //  PONTO B — Pedir password de MAC e verificar integridade
        // -------------------------------------------------------
        System.out.print("Introduza a password de MAC do servidor: ");
        BufferedReader consoleReader = new BufferedReader(new InputStreamReader(System.in));
        String macPassword = consoleReader.readLine();
        if (macPassword == null || macPassword.trim().isEmpty()) {
            System.out.println("Erro: password de MAC não pode ser vazia.");
            return;
        }

        macManager = new MacManager(macPassword);
        // Verifica o MAC no arranque — termina o servidor se estiver errado
        macManager.verificarArranque(PasswordManager.USERS_FILE);

        // -------------------------------------------------------
        //  PONTO D — Canal seguro TLS
        //  O servidor usa a sua keystore para se autenticar ao cliente.
        //  O cliente verifica o certificado do servidor através da sua truststore.
        //  (autenticação one-way: apenas o servidor se autentica via TLS)
        // -------------------------------------------------------
        System.setProperty("javax.net.ssl.keyStore", keystorePath);
        System.setProperty("javax.net.ssl.keyStorePassword", keystorePass);

        SSLServerSocketFactory ssf = (SSLServerSocketFactory) SSLServerSocketFactory.getDefault();
        ServerSocket serverSocket = ssf.createServerSocket(port);

        System.out.println("Servidor MySaude (TLS) a correr no porto " + port);

        while (true) {
            try {
                Socket socket = serverSocket.accept();
                new Thread(() -> handleClient(socket)).start();
            } catch (IOException e) {
                // Se uma conexão falhar, o erro é preso aqui
                // O loop continua e o servidor NÃO FECHA
                System.err.println("Erro ao aceitar conexão: " + e.getMessage());
            }
        }
    }

    private static void handleClient(Socket socket) {
        try {
            // ORDEM CORRETA DOS STREAMS
            ObjectOutputStream out = new ObjectOutputStream(socket.getOutputStream());
            out.flush(); // ESSENCIAL
            ObjectInputStream in = new ObjectInputStream(socket.getInputStream());

            String command = (String) in.readObject();

            switch (command) {
                case "UPLOAD":
                    handleUpload(in, out);
                    break;

                case "DOWNLOAD":
                    handleDownload(in, out);
                    break;

                default:
                    System.out.println("Comando desconhecido: " + command);
            }

            socket.close();

        } catch (Exception e) {
            System.out.println("Erro no cliente: " + e.getMessage());
        }
    }

    private static void handleUpload(ObjectInputStream in, ObjectOutputStream out) {
        try {
            String username     = (String) in.readObject();
            String destinatario = (String) in.readObject();
            String filename     = (String) in.readObject();
            long size           = (long) in.readObject();

            File userDir = new File("server_storage/" + destinatario);
            if (!userDir.exists()) userDir.mkdirs();

            // 1. Extrair o nome base (ex: "teste.pdf")
            // Usamos um regex que remove apenas as extensões finais de segurança
            String baseName = filename.replaceAll("\\.(cifrado|assinatura|envelope|assinado|chave).*$", "");

            // 2. Definir os tipos de ficheiros "principais" que não podem coexistir
            // aa.pdf, aa.pdf.cifrado, aa.pdf.assinado e aa.pdf.envelope são mutuamente exclusivos
            String[] mainTypes = {"", ".cifrado", ".assinado", ".envelope"};

            // 3. Determinar o tipo do ficheiro que está a entrar agora
            String incomingType = "";
            if (filename.endsWith(".cifrado"))       incomingType = ".cifrado";
            else if (filename.endsWith(".assinado")) incomingType = ".assinado";
            else if (filename.endsWith(".envelope")) incomingType = ".envelope";

            // 4. VERIFICAÇÃO DE UNICIDADE
            // Se o ficheiro atual for um tipo principal, não pode existir nenhum OUTRO tipo principal
            if (!incomingType.isEmpty() || filename.equals(baseName)) {
                for (String type : mainTypes) {
                    File existing = new File(userDir, baseName + type);
                    // Bloqueia se existir um tipo diferente OU se o ficheiro for exatamente igual (reenvio)
                    if (existing.exists() && !filename.equals(existing.getName())) {
                        out.writeObject("ERRO: Unicidade violada. Já existe uma versão de " + baseName);
                        out.flush();
                        return;
                    }
                }
            }

            // 5. Bloqueio de reenvio exato (evita carregar o mesmo ficheiro duas vezes)
            File file = new File(userDir, filename);
            if (file.exists()) {
                out.writeObject("ERRO: O ficheiro " + filename + " já existe no servidor.");
                out.flush();
                return;
            }

            // 6. Escrita do ficheiro
            FileOutputStream fos = new FileOutputStream(file);
            byte[] buffer = new byte[4096];
            long remaining = size;

            while (remaining > 0) {
                int read = in.read(buffer, 0, (int) Math.min(buffer.length, remaining));
                if (read == -1) throw new IOException("Upload incompleto");
                fos.write(buffer, 0, read);
                remaining -= read;
            }

            fos.close();
            out.writeObject("OK");
            out.flush();

            System.out.println("UPLOAD de " + filename + " para " + destinatario);

        } catch (Exception e) {
            try { out.writeObject("ERRO"); out.flush(); } catch (Exception ignored) {}
            System.out.println("Erro no upload: " + e.getMessage());
        }
    }

    private static void handleDownload(ObjectInputStream in, ObjectOutputStream out) {
        try {
            String destinatario = (String) in.readObject();
            String filename     = (String) in.readObject();

            File file = new File("server_storage/" + destinatario + "/" + filename);

            if (!file.exists()) {
                out.writeObject("NOT_FOUND");
                out.flush();
                System.out.println("DOWNLOAD falhou: ficheiro não encontrado -> " + file.getPath());
                return;
            }

            out.writeObject("OK");
            out.writeObject(file.getName()); // Nome real do ficheiro (com extensão)
            out.writeObject(file.length());
            out.flush(); // ESSENCIAL

            FileInputStream fis = new FileInputStream(file);
            byte[] buffer = new byte[4096];
            int read;

            while ((read = fis.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }

            out.flush(); // ESSENCIAL
            fis.close();

            System.out.println("DOWNLOAD de " + filename + " para " + destinatario);

        } catch (Exception e) {
            System.out.println("Erro no download: " + e.getMessage());
        }
    }
}