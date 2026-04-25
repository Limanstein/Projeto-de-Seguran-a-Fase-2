GRUPO 016
- 62239 Lourenço Lima
- 62238 Afonso Paulo
- 62235 Duarte Alberto

Existem alguns ficheiros powershell que servem para agilizar a criação e a elaboração de
um ambiente de testes/outras coisas

IMPORTANTE: Para rodar qualquer ficheiro .ps1 (powershell), fazer: .\nome.ps1

NOTA: Caso os comandos do powershell não estejam a correr é necessário correr primeiro este comando, 
em cada terminal, para que os mesmo funcionem 
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

rebuild.ps1 - Cria novos ficheiros .class (não elimina os .class, isso tem que ser feito manualmente)
limpeza.ps1 - Limpa as chaves, mensagens e os dados dentro de servidor
criar_keys.ps1 - Cria certeficados e keystores
server.ps1 - Inicia o server
testes.ps1 - Roda alguns testes simples com um ficheiro .pdf pesado
testesProf.ps1 - Roda todos os testes referentes ao enunciado do projeto

ORDEM DE RODAGEM DOS POWERSHELL:
1 - Correr criar_keys.ps1
2 - Pegar no projeto e transferi-lo para outro PC (Pen drive recomendada)
3 - No PC SERVIDOR, rodar server.ps1
4 - No PC CLIENTE, rodar testes.ps1 ou testesProf.p1
5 - Fechar o server pelo PC SERVER (Ctrl + C no terminal do mesmo)
6 - Correr limpeza.ps1 para deixar o projeto limpo e operacional

NOTA: MUDAR O IP DOS POWERSHELLS DE TESTE PARA O PRIMEIRO IPV4 DO PC SERVIDOR!

SEM POWERSHELL:

1. COMPILAÇÃO
Certifique-se de que está na raiz do projeto (onde se encontram as
pastas 'client' e 'server'). Execute os seguintes comandos:

javac server/MySaudeServer.java
javac client/MySaude.java


2. CONFIGURAÇÃO DE SEGURANÇA (KEYSTORES E CERTIFICADOS)
Para o correto funcionamento, cada utilizador deve possuir a sua KeyStore
e os certificados públicos dos utilizadores em quem confia.

Exemplo de configuração para AFONSO e LIMA (Trust Mútuo):

A) Criar as KeyStores
keytool -genkeypair -alias afonso -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.afonso -storepass 123456 -keypass 123456 -dname "CN=afonso"
keytool -genkeypair -alias lima -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.lima -storepass 123456 -keypass 123456 -dname "CN=lima"

B) Exportar e Importar Certificados
keytool -exportcert -alias afonso -keystore keystore.afonso -file afonso.cer -storepass 123456
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.lima -storepass 123456 -noprompt

keytool -exportcert -alias lima -keystore keystore.lima -file lima.cer -storepass 123456
keytool -importcert -alias lima -file lima.cer -keystore keystore.afonso -storepass 123456 -noprompt


3. EXECUÇÃO DO SERVIDOR
Inicie o servidor num terminal dedicado:
java server.MySaudeServer 8080

O servidor criará a pasta 'server_storage' automaticamente para
armazenamento dos ficheiros.


4. EXECUÇÃO DO CLIENTE (EXEMPLOS DE COMANDOS)
Substitua <IP> pelo endereço do servidor (ex: localhost).

A) ENVIAR E RECEBER FICHEIROS (SEM CIFRA)
Afonso envia ficheiros para Lima:
java client.MySaude -s localhost:8080 -u afonso -e teste.pdf -t lima

Lima recebe os ficheiros enviados por Afonso:
java client.MySaude -s localhost:8080 -u lima -r teste.pdf

B) CIFRAR E DECIFRAR LOCALMENTE (SEM SERVIDOR)
Afonso cifra para Lima:
java client.MySaude -u afonso -p 123456 -c teste_c.pdf -t lima
Lima decifra:
java client.MySaude -u lima -p 123456 -d teste_c.pdf.cifrado

C) CIFRAR E ENVIAR / RECEBER E DECIFRAR
Afonso envia cifrado para Lima:
java client.MySaude -s localhost:8080 -u afonso -p 123456 -ce teste_ce.pdf -t lima
Lima recebe e decifra:
java client.MySaude -s localhost:8080 -u lima -p 123456 -rd teste_ce.pdf

D) ASSINAR E VALIDAR LOCALMENTE
Lima assina um ficheiro:
java client.MySaude -u lima -p 123456 -a teste_a.pdf
Afonso valida a assinatura do Lima:
java client.MySaude -u afonso -p 123456 -t lima -v teste_a.pdf

E) ASSINAR/ENVIAR E RECEBER/VALIDAR
Assinar e enviar (-ae):
java client.MySaude -s localhost:8080 -u afonso -p 123456 -ae teste_ae.pdf -t lima
Receber e validar (-rv):
java client.MySaude -s localhost:8080 -u lima -p 123456 -t afonso -rv teste_ae.pdf

F) ENVELOPE SEGURO
Afonso envia envelope completo para Lima:
java client.MySaude -s localhost:8080 -u afonso -p 123456 -ace teste_ace.pdf -t lima
Lima abre o envelope e valida a assinatura do Afonso:
java client.MySaude -s localhost:8080 -u lima -p 123456 -t afonso -rdv teste_ace.pdf


5. NOTAS DE SEGURANÇA E UNICIDADE
- Unicidade: O servidor impede o upload de ficheiros com o mesmo nome
  base para o mesmo destinatário para evitar sobreposição de dados.
- Algoritmos: O sistema utiliza AES em modo CBC com IV aleatório para
  cifra de dados e RSA para cifra de chaves e assinaturas.
- Confiança: Se tentar enviar um ficheiro para um destinatário cujo
  certificado não foi importado para a sua KeyStore, o sistema
  retornará um erro de segurança.
