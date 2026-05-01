# =============================================================
# PREPARACAO DO CLIENTE - Script unico para cada maquina cliente
# =============================================================
# Correr em cada PC cliente depois de copiar os ficheiros do servidor.
#
# PRE-REQUISITO: copiar do servidor para esta pasta:
#   - keystore.afonso        (truststore TLS - obrigatorio em ambos os clientes)
#   - keystore.lima          (so no PC do Lima)
#   - keystore.duarte        (so no PC do Duarte)
#   - pasta client/ completa (com os ficheiros .java e/ou .class)
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$PASS = "123456"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  PREPARACAO DO CLIENTE MySaude" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan


# =============================================================
# PASSO 1 - Perguntar qual o utilizador deste PC
# =============================================================
Write-Host ""
Write-Host "Qual o utilizador deste PC?" -ForegroundColor Yellow
Write-Host "  1 - lima" -ForegroundColor White
Write-Host "  2 - duarte" -ForegroundColor White
Write-Host ""
$escolha = Read-Host "Inserir 1 ou 2"

if ($escolha -eq "1") {
    $user  = "lima"
    $outro = "duarte"
} elseif ($escolha -eq "2") {
    $user  = "duarte"
    $outro = "lima"
} else {
    Write-Host "Opcao invalida. Inserir 1 (lima) ou 2 (duarte)." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  Este PC: $user  |  Destinatario: $outro" -ForegroundColor Green

Write-Host ""
$ipServidor = Read-Host "Inserir o IP do servidor (ex: 192.168.1.10)"
if ($ipServidor -eq "") {
    Write-Host "IP nao inserido. A usar localhost." -ForegroundColor DarkYellow
    $ipServidor = "localhost"
}
Write-Host "  Servidor: $ipServidor`:8080" -ForegroundColor Green


# =============================================================
# PASSO 2 - Verificar ficheiros necessarios
# =============================================================
Write-Host "`n[1/3] A verificar ficheiros necessarios..." -ForegroundColor Yellow

$ok = $true

if (-not (Test-Path "keystore.afonso")) {
    Write-Host "  FALTA: keystore.afonso  (copiar do servidor)" -ForegroundColor Red
    $ok = $false
} else {
    Write-Host "  OK: keystore.afonso" -ForegroundColor Green
}

if (-not (Test-Path "keystore.$user")) {
    Write-Host "  FALTA: keystore.$user  (copiar do servidor)" -ForegroundColor Red
    $ok = $false
} else {
    Write-Host "  OK: keystore.$user" -ForegroundColor Green
}

if (-not (Test-Path "client")) {
    Write-Host "  FALTA: pasta client/  (copiar do servidor)" -ForegroundColor Red
    $ok = $false
} else {
    Write-Host "  OK: pasta client/" -ForegroundColor Green
}

if (-not $ok) {
    Write-Host "`nCopiar os ficheiros em falta do servidor e voltar a correr este script." -ForegroundColor Red
    exit 1
}


# =============================================================
# PASSO 3 - Compilar
# =============================================================
Write-Host "`n[2/3] A compilar codigo do cliente..." -ForegroundColor Yellow

javac -encoding UTF-8 client/KeyUtils.java client/CryptoUtils.java client/MySaude.java

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO de compilacao." -ForegroundColor Red
    exit 1
}
Write-Host "  Compilacao concluida." -ForegroundColor Green


# =============================================================
# PASSO 4 - Criar ficheiro de teste
# =============================================================
Write-Host "`n[3/3] A criar ficheiro de teste..." -ForegroundColor Yellow

"documento de teste mySaude" | Out-File -Encoding UTF8 "teste.txt"
Write-Host "  Criado: teste.txt" -ForegroundColor Green


# =============================================================
# COMANDOS PRONTOS A USAR
# =============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  CLIENTE PRONTO - $user" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Substituir $ipServidor pelo IP real do servidor." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Enviar ficheiro simples para $outro (-e):" -ForegroundColor White
Write-Host "    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=$PASS client.MySaude -s $ipServidor:8080 -u $user -p $PASS -t $outro -e teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Receber ficheiro simples (-r):" -ForegroundColor White
Write-Host "    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=$PASS client.MySaude -s $ipServidor:8080 -u $user -p $PASS -r teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Cifrar e enviar para $outro (-ce):" -ForegroundColor White
Write-Host "    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=$PASS client.MySaude -s $ipServidor:8080 -u $user -p $PASS -t $outro -ce teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Receber e decifrar (-rd):" -ForegroundColor White
Write-Host "    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=$PASS client.MySaude -s $ipServidor:8080 -u $user -p $PASS -rd teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Assinar, cifrar e enviar para $outro (-ae):" -ForegroundColor White
Write-Host "    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=$PASS client.MySaude -s $ipServidor:8080 -u $user -p $PASS -t $outro -ae teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Receber, decifrar e verificar assinatura de $outro (-rv):" -ForegroundColor White
Write-Host "    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=$PASS client.MySaude -s $ipServidor:8080 -u $user -p $PASS -t $outro -rv teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Envelope seguro enviar para $outro (-ace):" -ForegroundColor White
Write-Host "    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=$PASS client.MySaude -s $ipServidor:8080 -u $user -p $PASS -t $outro -ace teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Envelope seguro receber de $outro (-rdv):" -ForegroundColor White
Write-Host "    java -Djavax.net.ssl.trustStore=keystore.afonso -Djavax.net.ssl.trustStorePassword=$PASS client.MySaude -s $ipServidor:8080 -u $user -p $PASS -t $outro -rdv teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Assinar localmente sem servidor (-a):" -ForegroundColor White
Write-Host "    java client.MySaude -u $user -p $PASS -a teste.txt" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
