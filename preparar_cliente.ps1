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
$ip = Read-Host "Inserir o IP do servidor (ex: 192.168.1.10)"
if ($ip -eq "") {
    Write-Host "IP nao inserido. A usar localhost." -ForegroundColor DarkYellow
    $ip = "localhost"
}
$servidor = $ip + ":8080"
Write-Host "  Servidor: $servidor" -ForegroundColor Green


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

$ksUser = "keystore." + $user
if (-not (Test-Path $ksUser)) {
    Write-Host "  FALTA: $ksUser  (copiar do servidor)" -ForegroundColor Red
    $ok = $false
} else {
    Write-Host "  OK: $ksUser" -ForegroundColor Green
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
# GERAR SCRIPT demo.ps1 COM OS COMANDOS PRONTOS A EXECUTAR
# =============================================================
$demo = @"
`$PASS  = "$PASS"
`$user  = "$user"
`$outro = "$outro"
`$S     = "$servidor"
`$JVM   = "-Djavax.net.ssl.trustStore=keystore.afonso", "-Djavax.net.ssl.trustStorePassword=`$PASS"

function Pausa(`$msg) {
    Write-Host ""
    Write-Host ">>> Prima ENTER para: `$msg" -ForegroundColor Yellow
    Read-Host | Out-Null
}

Pausa "Enviar ficheiro simples para `$outro (-e)"
java `$JVM client.MySaude -s `$S -u `$user -p `$PASS -t `$outro -e teste.txt

Pausa "Receber ficheiro simples (-r)"
java `$JVM client.MySaude -s `$S -u `$user -p `$PASS -r teste.txt

Pausa "Cifrar e enviar para `$outro (-ce)"
java `$JVM client.MySaude -s `$S -u `$user -p `$PASS -t `$outro -ce teste.txt

Pausa "Receber e decifrar (-rd)"
java `$JVM client.MySaude -s `$S -u `$user -p `$PASS -rd teste.txt

Pausa "Assinar, cifrar e enviar para `$outro (-ae)"
java `$JVM client.MySaude -s `$S -u `$user -p `$PASS -t `$outro -ae teste.txt

Pausa "Receber, decifrar e verificar assinatura de `$outro (-rv)"
java `$JVM client.MySaude -s `$S -u `$user -p `$PASS -t `$outro -rv teste.txt

Pausa "Envelope seguro - enviar para `$outro (-ace)"
java `$JVM client.MySaude -s `$S -u `$user -p `$PASS -t `$outro -ace teste.txt

Pausa "Envelope seguro - receber de `$outro (-rdv)"
java `$JVM client.MySaude -s `$S -u `$user -p `$PASS -t `$outro -rdv teste.txt

Pausa "Assinar localmente sem servidor (-a)"
java client.MySaude -u `$user -p `$PASS -a teste.txt

Write-Host ""
Write-Host "Demo concluida." -ForegroundColor Green
"@

$demo | Out-File -Encoding UTF8 "demo.ps1"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  CLIENTE PRONTO - $user" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Script de demo gerado: demo.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Para correr a demo:" -ForegroundColor White
Write-Host "    .\demo.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
