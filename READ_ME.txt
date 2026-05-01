GRUPO 016
- 62239 Lourenco Lima
- 62238 Afonso Paulo
- 62235 Duarte Alberto

================================================================================
CONFIGURACAO — 3 MAQUINAS (SERVIDOR + CLIENTE 1 + CLIENTE 2)
================================================================================

Esta e a forma correta de correr o projeto (como pedido no enunciado).
O servidor corre numa maquina e os dois clientes correm em maquinas separadas.

--- FICHEIROS NECESSARIOS EM CADA MAQUINA ---

    PC SERVIDOR:
        - Todo o codigo compilado (pastas server/ e client/)
        - keystore.afonso  (keystore TLS do servidor)
        - server_storage/  (criado automaticamente)

    PC CLIENTE 1 (ex: Lima):
        - Todo o codigo compilado (pasta client/)
        - keystore.afonso  (necessario para confiar no servidor via TLS)
        - keystore.lima    (chave privada + certificado do utilizador)

    PC CLIENTE 2 (ex: Duarte):
        - Todo o codigo compilado (pasta client/)
        - keystore.afonso  (necessario para confiar no servidor via TLS)
        - keystore.duarte  (chave privada + certificado do utilizador)

NOTA: O keystore.afonso serve de truststore nos clientes porque o servidor
      usa o certificado de 'afonso' para o TLS. Todos os clientes precisam
      dele para validar a identidade do servidor.

--- ORDEM DE EXECUCAO COM SCRIPTS POWERSHELL ---

IMPORTANTE: Para correr scripts .ps1 fazer:   .\nome_do_script.ps1
            Se nao correr, executar primeiro:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

PASSO 1 — No PC SERVIDOR, correr o script de preparacao:
    .\preparar_servidor.ps1
    (faz tudo: compila, cria chaves, cria utilizadores, arranca o servidor)
    (insere a password de MAC automaticamente: macpassword123)
    (NO FINAL mostra os ficheiros a copiar para cada cliente e arranca o servidor)

PASSO 2 — Copiar para os PCs CLIENTE (via pen drive ou rede):

    Para PC CLIENTE 1 (Lima):
        keystore.afonso   <- truststore TLS
        keystore.lima     <- keystore do utilizador Lima
        pasta client/     <- codigo compilado

    Para PC CLIENTE 2 (Duarte):
        keystore.afonso   <- truststore TLS
        keystore.duarte   <- keystore do utilizador Duarte
        pasta client/     <- codigo compilado

PASSO 3 — Em cada PC CLIENTE, correr o script de preparacao:
    .\preparar_cliente.ps1
    (verifica ficheiros, compila se necessario, cria ficheiro de teste)
    (mostra automaticamente os comandos prontos para esse utilizador)

PASSO 4 — Nos PCs CLIENTE, correr os testes (alterar IP_SERVIDOR):

    .\testes_fase1.ps1   (operacoes locais, sem servidor)

    Abrir testes_fase2.ps1, alterar a linha:
        $S = "localhost:8080"   ->   $S = "IP_DO_SERVIDOR:8080"
    Depois correr:
    .\testes_fase2.ps1   (operacoes com servidor)

PASSO 5 — No final, limpar tudo (no servidor):
    .\limpeza.ps1

--- DESCRICAO DOS SCRIPTS ---

    preparar_servidor.ps1 - NOVO: faz tudo no servidor de uma vez
                            (compila + chaves + utilizadores + arranca servidor)
    preparar_cliente.ps1  - NOVO: faz tudo no cliente de uma vez
                            (verifica ficheiros + compila + cria teste + mostra comandos)
    rebuild.ps1           - Recompila todos os ficheiros .java (server + client)
    limpeza.ps1           - Limpa keystores, certificados, ficheiros gerados e server_storage
                            (tambem para o servidor se estiver a correr na porta 8080)
    criar_keys.ps1        - Cria keystores RSA-2048 e certificados (usado pelo preparar_servidor)
    criar_users.ps1       - Regista os utilizadores no servidor (usado pelo preparar_servidor)
    server.ps1            - Inicia o servidor TLS na porta 8080 (separado, se necessario)
    testes_fase1.ps1      - Testa as operacoes locais sem servidor (-c, -d, -a, -v)
    testes_fase2.ps1      - Testa todas as funcionalidades com servidor
                            (autenticacao, MAC, TLS, certificados, operacoes combinadas)


================================================================================
SEM POWERSHELL — EXECUCAO MANUAL NAS 3 MAQUINAS
================================================================================

NOTA ANTES DE COMECAR:
  Substituir IP_SERVIDOR pelo IP real do servidor em todos os comandos dos clientes.
  Para saber o IP do servidor correr (Linux):   hostname -I | awk '{print $1}'
  Para saber o IP do servidor correr (Windows): ipconfig


================================================================================
PC SERVIDOR — TODOS OS COMANDOS DO TERMINAL (por ordem)
================================================================================

--- PASSO 1: Compilar ---

javac -encoding UTF-8 server/PasswordManager.java server/MacManager.java server/CriarUser.java server/MySaudeServer.java client/KeyUtils.java client/CryptoUtils.java client/MySaude.java


--- PASSO 2: Criar keystores RSA-2048 para cada utilizador ---

keytool -genkeypair -alias afonso    -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.afonso    -validity 365 -storepass 123456 -keypass 123456 -dname "CN=afonso"
keytool -genkeypair -alias lima      -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.lima      -validity 365 -storepass 123456 -keypass 123456 -dname "CN=lima"
keytool -genkeypair -alias duarte    -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.duarte    -validity 365 -storepass 123456 -keypass 123456 -dname "CN=duarte"
keytool -genkeypair -alias alexandre -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.alexandre -validity 365 -storepass 123456 -keypass 123456 -dname "CN=alexandre"


--- PASSO 3: Exportar certificados ---

keytool -exportcert -alias afonso    -keystore keystore.afonso    -file afonso.cer    -storepass 123456
keytool -exportcert -alias lima      -keystore keystore.lima      -file lima.cer      -storepass 123456
keytool -exportcert -alias duarte    -keystore keystore.duarte    -file duarte.cer    -storepass 123456
keytool -exportcert -alias alexandre -keystore keystore.alexandre -file alexandre.cer -storepass 123456


--- PASSO 4: Importar relacoes de confianca entre utilizadores ---

keytool -importcert -alias lima   -file lima.cer   -keystore keystore.afonso    -storepass 123456 -noprompt
keytool -importcert -alias duarte -file duarte.cer -keystore keystore.afonso    -storepass 123456 -noprompt
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.lima      -storepass 123456 -noprompt
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.duarte    -storepass 123456 -noprompt
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.alexandre -storepass 123456 -noprompt

    NOTA: Lima NAO importa o certificado de Duarte de proposito.
          Quando Lima precisar do cert de Duarte, o cliente vai busca-lo
          automaticamente ao servidor (Ponto E do enunciado).


--- PASSO 5: Criar utilizadores no sistema ---
    (cada comando pede a password de MAC — inserir: macpassword123)

java server.CriarUser afonso medico 123456 -f afonso.cer
java server.CriarUser lima   medico 123456 -f lima.cer
java server.CriarUser duarte medico 123456 -f duarte.cer
java server.CriarUser bob    utente 123456 -f alexandre.cer


--- PASSO 6: Copiar para os PCs cliente (via pen drive ou rede) ---

    Para PC CLIENTE 1 (Lima):
        keystore.afonso  keystore.lima  e toda a pasta client/

    Para PC CLIENTE 2 (Duarte):
        keystore.afonso  keystore.duarte  e toda a pasta client/


--- PASSO 7: Arrancar o servidor (fica a correr nesta janela) ---
    (pede a password de MAC — inserir: macpassword123)

java server.MySaudeServer 8080 keystore.afonso 123456


================================================================================
PC CLIENTE 1 (Lima) — TODOS OS COMANDOS DO TERMINAL (por ordem)
================================================================================

    NOTA: Garantir que os ficheiros keystore.afonso e keystore.lima estao
          na mesma pasta de onde se correm os comandos.
          Substituir IP_SERVIDOR pelo IP real do servidor.


--- PASSO 1: Compilar ---

javac -encoding UTF-8 client/KeyUtils.java client/CryptoUtils.java client/MySaude.java


--- PASSO 2: Criar ficheiro de teste ---

    (Linux)   echo "documento de teste" > teste.txt
    (Windows) echo documento de teste > teste.txt


--- PASSO 3: Enviar ficheiro simples para Duarte (-e) ---

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u lima -p 123456 -t duarte -e teste.txt


--- PASSO 4: Cifrar localmente para Afonso e depois decifrar (-c e -d) ---
    (operacoes locais: sem servidor, sem flags TLS)

java client.MySaude -u lima -p 123456 -t afonso -c teste.txt
java client.MySaude -u lima -p 123456 -d teste.txt.cifrado


--- PASSO 5: Cifrar e enviar para Duarte (-ce) ---
    (Lima nao tem o cert de Duarte — vai busca-lo ao servidor automaticamente: Ponto E)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u lima -p 123456 -t duarte -ce teste.txt


--- PASSO 6: Assinar ficheiro localmente (-a) ---

java client.MySaude -u lima -p 123456 -a teste.txt


--- PASSO 7: Assinar, cifrar e enviar para Duarte (-ae) ---

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u lima -p 123456 -t duarte -ae teste.txt


--- PASSO 8: Receber e decifrar ficheiro enviado por Duarte (-rd) ---
    (Duarte tem de ter enviado um ficheiro para Lima com -ce antes deste passo)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u lima -p 123456 -rd teste.txt


--- PASSO 9: Receber, decifrar e verificar assinatura de Duarte (-rv) ---
    (Duarte tem de ter enviado um ficheiro para Lima com -ae antes deste passo)
    (Lima nao tem o cert de Duarte — vai busca-lo ao servidor automaticamente: Ponto E)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u lima -p 123456 -t duarte -rv teste.txt


--- PASSO 10: Envelope seguro — enviar para Duarte (-ace) ---

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u lima -p 123456 -t duarte -ace teste.txt


--- PASSO 11: Envelope seguro — receber de Duarte (-rdv) ---
    (Duarte tem de ter enviado um envelope para Lima com -ace antes deste passo)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u lima -p 123456 -t duarte -rdv teste.txt


--- PASSO 12: Demonstrar controlo de acesso (bob e utente, nao pode enviar) ---

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u bob -p 123456 -t duarte -e teste.txt
    (esperado: ERRO — Acesso negado. Apenas 'medico' pode enviar ficheiros)


================================================================================
PC CLIENTE 2 (Duarte) — TODOS OS COMANDOS DO TERMINAL (por ordem)
================================================================================

    NOTA: Garantir que os ficheiros keystore.afonso e keystore.duarte estao
          na mesma pasta de onde se correm os comandos.
          Substituir IP_SERVIDOR pelo IP real do servidor.


--- PASSO 1: Compilar ---

javac -encoding UTF-8 client/KeyUtils.java client/CryptoUtils.java client/MySaude.java


--- PASSO 2: Criar ficheiro de teste ---

    (Linux)   echo "documento de teste" > teste.txt
    (Windows) echo documento de teste > teste.txt


--- PASSO 3: Receber ficheiro simples enviado por Lima (-r) ---
    (Lima tem de ter feito o passo 3 antes deste)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u duarte -p 123456 -r teste.txt


--- PASSO 4: Receber e decifrar ficheiro cifrado por Lima (-rd) ---
    (Lima tem de ter feito o passo 5 antes deste)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u duarte -p 123456 -rd teste.txt


--- PASSO 5: Receber, decifrar e verificar assinatura de Lima (-rv) ---
    (Lima tem de ter feito o passo 7 antes deste)
    (Duarte nao tem o cert de Lima — vai busca-lo ao servidor automaticamente: Ponto E)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u duarte -p 123456 -t lima -rv teste.txt


--- PASSO 6: Cifrar e enviar para Lima (-ce) ---
    (Duarte nao tem o cert de Lima — vai busca-lo ao servidor automaticamente: Ponto E)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u duarte -p 123456 -t lima -ce teste.txt


--- PASSO 7: Assinar, cifrar e enviar para Lima (-ae) ---

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u duarte -p 123456 -t lima -ae teste.txt


--- PASSO 8: Envelope seguro — enviar para Lima (-ace) ---

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u duarte -p 123456 -t lima -ace teste.txt


--- PASSO 9: Envelope seguro — receber de Lima (-rdv) ---
    (Lima tem de ter feito o passo 10 antes deste)

java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s IP_SERVIDOR:8080 -u duarte -p 123456 -t lima -rdv teste.txt


--- PASSO 10: Assinar localmente (-a) e verificar localmente (-v) ---
    (operacoes locais: sem servidor, sem flags TLS)

java client.MySaude -u duarte -p 123456 -a teste.txt
java client.MySaude -u duarte -p 123456 -t duarte -v teste.txt


================================================================================
REFERENCIA RAPIDA
================================================================================

    Username  | Funcao | Password | Keystore
    ----------+--------+----------+------------------
    afonso    | medico | 123456   | keystore.afonso  (tambem e o servidor TLS)
    lima      | medico | 123456   | keystore.lima
    duarte    | medico | 123456   | keystore.duarte
    bob       | utente | 123456   | keystore.alexandre

    Password de MAC do servidor : macpassword123
    Password de todas as keystores : 123456

    So utilizadores com funcao 'medico' podem fazer UPLOAD.
    Todos os utilizadores autenticados podem fazer DOWNLOAD.
    Operacoes locais (-c, -d, -a, -v) nao precisam de servidor nem de autenticacao.


================================================================================
NOTAS DE SEGURANCA
================================================================================

    TLS: A comunicacao entre cliente e servidor e sempre cifrada via TLS/SSL.
         O servidor usa o certificado de 'afonso'. Os clientes precisam de
         keystore.afonso como truststore para validar a identidade do servidor.

    Autenticacao: O servidor verifica a password antes de aceitar qualquer
         operacao. Passwords erradas ou utilizadores inexistentes sao rejeitados.

    MAC (Integridade): O ficheiro 'users' e protegido por HMAC-SHA256.
         O servidor verifica o MAC no arranque e em cada acesso. Se o ficheiro
         tiver sido adulterado, o servidor termina imediatamente.

    Certificados (Ponto E): Se o certificado do destinatario nao existir
         na keystore local do cliente, o cliente vai busca-lo automaticamente
         ao servidor via TLS e guarda-o localmente para uso futuro.
         (Ex: Lima nao tem o certificado de Duarte — vai busca-lo ao servidor)

    Controlo de acesso: So 'medico' pode fazer upload. Utentes so podem
         fazer download dos seus proprios ficheiros.
