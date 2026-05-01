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

    PC CLIENTE 1 (Lima):
        - Todo o codigo compilado (pasta client/)
        - keystore.afonso  (necessario para confiar no servidor via TLS)
        - keystore.lima    (chave privada + certificado do utilizador)

    PC CLIENTE 2 (Duarte):
        - Todo o codigo compilado (pasta client/)
        - keystore.afonso  (necessario para confiar no servidor via TLS)
        - keystore.duarte  (chave privada + certificado do utilizador)

NOTA: O keystore.afonso serve de truststore nos clientes porque o servidor
      usa o certificado de 'afonso' para o TLS. Todos os clientes precisam
      dele para validar a identidade do servidor.

--- ORDEM DE EXECUCAO COM SCRIPTS POWERSHELL ---

IMPORTANTE: Para correr scripts .ps1 fazer:   .\nome_do_script.ps1
            Se nao correr, executar primeiro:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

PASSO 1 - No PC SERVIDOR, correr o script de preparacao:
    .\preparar_servidor.ps1
    (faz tudo: compila, cria chaves, cria utilizadores, arranca o servidor)
    (NO FINAL mostra o IP do servidor e os ficheiros a copiar para cada cliente)

PASSO 2 - Copiar para os PCs CLIENTE (via pen drive ou rede):

    Para PC CLIENTE 1 (Lima):
        keystore.afonso   <- truststore TLS
        keystore.lima     <- keystore do utilizador Lima
        pasta client/     <- codigo compilado

    Para PC CLIENTE 2 (Duarte):
        keystore.afonso   <- truststore TLS
        keystore.duarte   <- keystore do utilizador Duarte
        pasta client/     <- codigo compilado

PASSO 3 - Em cada PC CLIENTE, correr o script de preparacao:
    .\preparar_cliente.ps1
    (pergunta qual o utilizador: 1=lima, 2=duarte)
    (pergunta o IP do servidor)
    (verifica ficheiros, compila, cria ficheiro de teste)
    (gera demo.ps1 com todos os comandos prontos a executar)

PASSO 4 - Em cada PC CLIENTE, correr a demo:
    .\demo.ps1

PASSO 5 - No SERVIDOR, para demonstrar pontos A/B/C:
    .\testes_fase2.ps1

PASSO 6 - No final, limpar tudo (no servidor):
    .\limpeza.ps1

--- DESCRICAO DOS SCRIPTS ---

    preparar_servidor.ps1 - Faz tudo no servidor de uma vez
                            (compila + chaves + utilizadores + arranca servidor)
    preparar_cliente.ps1  - Faz tudo no cliente de uma vez
                            (pergunta utilizador + IP, verifica ficheiros,
                             compila, cria teste, gera demo.ps1)
    demo.ps1              - Gerado pelo preparar_cliente.ps1
                            (corre todos os comandos do cliente com pausas)
    rebuild.ps1           - Recompila todos os ficheiros .java (server + client)
    limpeza.ps1           - Limpa keystores, certificados, ficheiros e server_storage
    criar_keys.ps1        - Cria keystores e certificados (usado pelo preparar_servidor)
    criar_users.ps1       - Regista utilizadores no servidor (usado pelo preparar_servidor)
    server.ps1            - Inicia o servidor TLS na porta 8080 (separado, se necessario)
    testes_fase1.ps1      - Testa operacoes locais sem servidor (-c, -d, -a, -v)
    testes_fase2.ps1      - Testa pontos A/B/C/D/E/F com servidor (correr no servidor)


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
    Operacoes locais (-c, -d, -a, -v) nao precisam de servidor.


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
