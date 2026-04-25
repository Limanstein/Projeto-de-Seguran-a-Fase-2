GRUPO 016
- 62239 Lourenço Lima
- 62238 Afonso Paulo
- 62235 Duarte Alberto

================================================================================
SCRIPTS POWERSHELL
================================================================================

IMPORTANTE: Para rodar qualquer ficheiro .ps1 (powershell), fazer: .\nome.ps1

NOTA: Caso os comandos do powershell não estejam a correr é necessário correr
primeiro este comando, em cada terminal, para que os mesmos funcionem:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

--- DESCRIÇÃO DOS SCRIPTS ---

rebuild.ps1      - Recompila todos os ficheiros .java do projeto (server + client)
limpeza.ps1      - Limpa keystores, certificados, ficheiros gerados e server_storage
                   (também para o servidor se estiver a correr na porta 8080)
criar_keys.ps1   - Cria keystores e certificados para todos os utilizadores
                   e estabelece as relações de confiança necessárias
criar_users.ps1  - Cria os utilizadores no servidor (ficheiro users + MAC)
                   Requer que criar_keys.ps1 tenha sido executado antes
server.ps1       - Inicia o servidor TLS na porta 8080
                   (pede a password de MAC ao arrancar: macpassword123)
testes_fase1.ps1 - Testa as operações locais sem servidor (-c, -d, -a, -v)
testes_fase2.ps1 - Testa todas as funcionalidades da Fase 2 com servidor
                   (autenticação, MAC, TLS, certificados, operações combinadas)

--- ORDEM DE EXECUÇÃO (MÁQUINAS SEPARADAS) ---

1 - Correr rebuild.ps1 (em ambos os PCs)
2 - Correr criar_keys.ps1 (no PC SERVIDOR)
3 - Correr criar_users.ps1 (no PC SERVIDOR)
4 - Copiar keystores e certificados para o PC CLIENTE (pen drive):
        keystore.afonso, keystore.lima, keystore.duarte, keystore.alexandre
        afonso.cer, lima.cer, duarte.cer, alexandre.cer
5 - No PC SERVIDOR, correr server.ps1 (inserir password de MAC: macpassword123)
6 - No PC CLIENTE, correr testes_fase1.ps1 e/ou testes_fase2.ps1
7 - Correr limpeza.ps1 para deixar o projeto limpo

NOTA: Mudar a variável $S nos scripts de teste para o IP do servidor!
      Exemplo: $S = "192.168.1.10:8080"

--- ORDEM DE EXECUÇÃO (MÁQUINA LOCAL / localhost) ---

1 - rebuild.ps1
2 - criar_keys.ps1
3 - criar_users.ps1
4 - server.ps1  (numa janela separada; inserir password de MAC: macpassword123)
5 - testes_fase1.ps1  (sem servidor a correr)
    testes_fase2.ps1  (com servidor a correr)
6 - limpeza.ps1


================================================================================
SEM POWERSHELL — EXECUÇÃO MANUAL
================================================================================

1. COMPILAÇÃO
--------------------------------------------------------------------------------
Certifique-se de que está na raiz do projeto (onde se encontram as pastas
'client' e 'server'). Execute os seguintes comandos:

    javac -encoding UTF-8 server/PasswordManager.java server/MacManager.java ^
          server/CriarUser.java server/MySaudeServer.java ^
          client/KeyUtils.java client/CryptoUtils.java client/MySaude.java

(No Linux/Mac substituir ^ por \ ou colocar tudo numa linha)


2. CONFIGURAÇÃO DE CHAVES E CERTIFICADOS
--------------------------------------------------------------------------------
Gerar keystores RSA-2048 para cada utilizador:

    keytool -genkeypair -alias afonso -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.afonso -validity 365 -storepass 123456 -keypass 123456 -dname "CN=afonso"
    keytool -genkeypair -alias lima -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.lima -validity 365 -storepass 123456 -keypass 123456 -dname "CN=lima"
    keytool -genkeypair -alias duarte -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.duarte -validity 365 -storepass 123456 -keypass 123456 -dname "CN=duarte"
    keytool -genkeypair -alias alexandre -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.alexandre -validity 365 -storepass 123456 -keypass 123456 -dname "CN=alexandre"

Exportar certificados:

    keytool -exportcert -alias afonso    -keystore keystore.afonso    -file afonso.cer    -storepass 123456
    keytool -exportcert -alias lima      -keystore keystore.lima      -file lima.cer      -storepass 123456
    keytool -exportcert -alias duarte    -keystore keystore.duarte    -file duarte.cer    -storepass 123456
    keytool -exportcert -alias alexandre -keystore keystore.alexandre -file alexandre.cer -storepass 123456

Importar certificados (relações de confiança):

    keytool -importcert -alias afonso -file afonso.cer -keystore keystore.lima      -storepass 123456 -noprompt
    keytool -importcert -alias lima   -file lima.cer   -keystore keystore.afonso    -storepass 123456 -noprompt
    keytool -importcert -alias duarte -file duarte.cer -keystore keystore.afonso    -storepass 123456 -noprompt
    keytool -importcert -alias afonso -file afonso.cer -keystore keystore.duarte    -storepass 123456 -noprompt
    keytool -importcert -alias afonso -file afonso.cer -keystore keystore.alexandre -storepass 123456 -noprompt

NOTA: Lima NÃO importa o certificado de Duarte intencionalmente.
      O cliente vai buscá-lo automaticamente ao servidor quando necessário (Ponto E).


3. CRIAR UTILIZADORES (FASE 2)
--------------------------------------------------------------------------------
O programa CriarUser regista utilizadores no servidor.
Pede a password de MAC ao ser executado (usar sempre a mesma: macpassword123).

Formato: java server.CriarUser <username> <funcao> <password> -f <certificado>

    java server.CriarUser afonso medico 123456 -f afonso.cer
    java server.CriarUser lima   medico 123456 -f lima.cer
    java server.CriarUser duarte medico 123456 -f duarte.cer
    java server.CriarUser bob    utente 123456 -f alexandre.cer

Verificar o ficheiro de utilizadores criado:
    cat server_storage/users
    (formato: username:funcao:salt:sintese(salt||password))

Erros tratados pelo CriarUser:
    - Username já existente  -> mensagem de erro e termina
    - Função inválida        -> mensagem de erro e termina (só 'medico' ou 'utente')
    - MAC inválido           -> operação cancelada (ficheiro users pode estar adulterado)


4. EXECUÇÃO DO SERVIDOR (FASE 2 — TLS)
--------------------------------------------------------------------------------
O servidor requer 3 argumentos: porto, keystore e password da keystore.
Pede também a password de MAC ao arrancar.

    java server.MySaudeServer 8080 keystore.afonso 123456
    (inserir quando pedido: macpassword123)

O servidor verifica o MAC do ficheiro users no arranque.
Se o MAC estiver errado, o servidor imprime um aviso e termina imediatamente.

NOTA: O certificado do servidor é o de 'afonso' (CN=afonso).
      Os clientes usam keystore.afonso como trust store para validar o TLS.


5. EXECUÇÃO DO CLIENTE (FASE 2 — com autenticação e TLS)
--------------------------------------------------------------------------------
IMPORTANTE: Todos os comandos que contactam o servidor precisam das flags de TLS:
    -Djavax.net.ssl.trustStore=keystore.afonso
    -Djavax.net.ssl.trustStorePassword=123456

Se o servidor estiver noutra máquina, substituir 'localhost' pelo IP do servidor.

A) ENVIAR E RECEBER FICHEIROS SIMPLES (-e / -r)

    Afonso (medico) envia para Lima:
    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s localhost:8080 -u afonso -p 123456 -t lima -e teste.pdf

    Lima recebe:
    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s localhost:8080 -u lima -p 123456 -r teste.pdf

B) CIFRAR E DECIFRAR LOCALMENTE (SEM SERVIDOR — sem flags TLS)

    Lima cifra para Afonso:
    java client.MySaude -u lima -p 123456 -t afonso -c teste.pdf

    Afonso decifra:
    java client.MySaude -u afonso -p 123456 -d teste.pdf.cifrado

C) CIFRAR + ENVIAR / RECEBER + DECIFRAR (-ce / -rd)

    Afonso cifra e envia para Lima:
    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s localhost:8080 -u afonso -p 123456 -t lima -ce teste.pdf

    Lima recebe e decifra:
    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s localhost:8080 -u lima -p 123456 -rd teste.pdf

D) ASSINAR E VALIDAR LOCALMENTE (SEM SERVIDOR — sem flags TLS)

    Duarte assina:
    java client.MySaude -u duarte -p 123456 -a teste.pdf

    Afonso valida a assinatura de Duarte:
    java client.MySaude -u afonso -p 123456 -t duarte -v teste.pdf

E) ASSINAR + ENVIAR / RECEBER + VERIFICAR (-ae / -rv)

    Lima assina, cifra e envia para Afonso:
    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s localhost:8080 -u lima -p 123456 -t afonso -ae teste.pdf

    Afonso recebe, decifra e verifica a assinatura de Lima:
    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s localhost:8080 -u afonso -p 123456 -t lima -rv teste.pdf

F) ENVELOPE SEGURO (-ace / -rdv)
   (assinar + cifrar + enviar tudo em uma operação / receber + decifrar + verificar)

    Duarte envia envelope seguro para Afonso:
    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s localhost:8080 -u duarte -p 123456 -t afonso -ace teste.pdf

    Afonso abre o envelope e valida a assinatura de Duarte:
    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=123456 client.MySaude -s localhost:8080 -u afonso -p 123456 -t duarte -rdv teste.pdf


6. REFERÊNCIA DE UTILIZADORES
--------------------------------------------------------------------------------
    Username | Função | Password | Certificado
    ---------+--------+----------+---------------
    afonso   | medico | 123456   | afonso.cer
    lima     | medico | 123456   | lima.cer
    duarte   | medico | 123456   | duarte.cer
    bob      | utente | 123456   | alexandre.cer

Password de MAC do servidor: macpassword123
Password das keystores:      123456

Apenas utilizadores com função 'medico' podem fazer upload de ficheiros.
Todos os utilizadores autenticados podem fazer download.


7. NOTAS DE SEGURANÇA
--------------------------------------------------------------------------------
- TLS: A comunicação entre cliente e servidor é sempre cifrada via TLS/SSL.
  O certificado do servidor é o de 'afonso'. Os clientes precisam de ter
  o certificado de 'afonso' na sua keystore para validar a ligação.

- Autenticação: O servidor verifica a password de cada utilizador antes de
  aceitar qualquer operação. Passwords erradas ou utilizadores inexistentes
  são rejeitados com mensagem de erro.

- MAC (Integridade): O ficheiro 'users' é protegido por HMAC-SHA256.
  O servidor verifica o MAC no arranque e em cada acesso. Se o ficheiro
  tiver sido adulterado, o servidor termina imediatamente.

- Certificados (Ponto E): Se o certificado do destinatário não existir
  na keystore local do cliente, o cliente vai buscá-lo automaticamente
  ao servidor via TLS e guarda-o localmente para uso futuro.

- Unicidade: O servidor impede o envio de um ficheiro com o mesmo nome
  base para o mesmo destinatário (evita sobreposição de dados).

- Controlo de acesso: Só utilizadores com função 'medico' podem fazer
  upload. Utentes só podem fazer download dos seus próprios ficheiros.
