# =============================================================
# PREPARAÇÃO DO SERVIDOR — Script único para a máquina servidor
# =============================================================
# Faz tudo o que é necessário no servidor antes de arrancar:
#   1. Compila todo o código (server + client)
#   2. Cria keystores RSA-2048 e certificados
#   3. Estabelece relações de confiança
#   4. Regista os utilizadores no sistema
#   5. Mostra os ficheiros a copiar para os clientes
#   6. Arranca o servidor TLS
#
# Correr APENAS NO PC SERVIDOR, antes de qualquer cliente.
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$PASS     = "123456"
$MAC_PASS = "macpassword123"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  PREPARACAO DO SERVIDOR MySaude" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan


# =============================================================
# PASSO 1 — Compilar
# =============================================================
Write-Host "`n[1/4] A compilar todo o codigo..." -ForegroundColor Yellow

javac -encoding UTF-8 `
    server/PasswordManager.java `
    server/MacManager.java `
    server/CriarUser.java `
    server/MySaudeServer.java `
    client/KeyUtils.java `
    client/CryptoUtils.java `
    client/MySaude.java

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO de compilacao. Verifique os ficheiros .java." -ForegroundColor Red
    exit 1
}
Write-Host "Compilacao concluida." -ForegroundColor Green


# =============================================================
# PASSO 2 — Criar keystores e certificados
# =============================================================
Write-Host "`n[2/4] A criar keystores e certificados..." -ForegroundColor Yellow

keytool -genkeypair -alias afonso    -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.afonso    -validity 365 -storepass $PASS -keypass $PASS -dname "CN=afonso"    2>&1 | Out-Null
keytool -genkeypair -alias lima      -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.lima      -validity 365 -storepass $PASS -keypass $PASS -dname "CN=lima"      2>&1 | Out-Null
keytool -genkeypair -alias duarte    -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.duarte    -validity 365 -storepass $PASS -keypass $PASS -dname "CN=duarte"    2>&1 | Out-Null
keytool -genkeypair -alias alexandre -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.alexandre -validity 365 -storepass $PASS -keypass $PASS -dname "CN=alexandre" 2>&1 | Out-Null

keytool -exportcert -alias afonso    -keystore keystore.afonso    -file afonso.cer    -storepass $PASS 2>&1 | Out-Null
keytool -exportcert -alias lima      -keystore keystore.lima      -file lima.cer      -storepass $PASS 2>&1 | Out-Null
keytool -exportcert -alias duarte    -keystore keystore.duarte    -file duarte.cer    -storepass $PASS 2>&1 | Out-Null
keytool -exportcert -alias alexandre -keystore keystore.alexandre -file alexandre.cer -storepass $PASS 2>&1 | Out-Null

# Relacoes de confianca
keytool -importcert -alias lima   -file lima.cer   -keystore keystore.afonso    -storepass $PASS -noprompt 2>&1 | Out-Null
keytool -importcert -alias duarte -file duarte.cer -keystore keystore.afonso    -storepass $PASS -noprompt 2>&1 | Out-Null
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.lima      -storepass $PASS -noprompt 2>&1 | Out-Null
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.duarte    -storepass $PASS -noprompt 2>&1 | Out-Null
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.alexandre -storepass $PASS -noprompt 2>&1 | Out-Null

Write-Host "Keystores e certificados criados." -ForegroundColor Green
Write-Host "  (Lima NAO importa cert de Duarte — fetch automatico via Ponto E)" -ForegroundColor DarkYellow


# =============================================================
# PASSO 3 — Criar utilizadores
# =============================================================
Write-Host "`n[3/4] A criar utilizadores (password MAC: $MAC_PASS)..." -ForegroundColor Yellow

echo $MAC_PASS | java server.CriarUser afonso medico $PASS -f afonso.cer
echo $MAC_PASS | java server.CriarUser lima   medico $PASS -f lima.cer
echo $MAC_PASS | java server.CriarUser duarte medico $PASS -f duarte.cer
echo $MAC_PASS | java server.CriarUser bob    utente $PASS -f alexandre.cer

Write-Host "`nFicheiro de utilizadores criado:" -ForegroundColor Green
Get-Content "server_storage/users"


# =============================================================
# PASSO 4 — Instruções de cópia para os clientes
# =============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  [4/4] COPIAR PARA OS PCs CLIENTE (pen drive ou rede)" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Para PC CLIENTE 1 (Lima):" -ForegroundColor White
Write-Host "    keystore.afonso" -ForegroundColor Cyan
Write-Host "    keystore.lima" -ForegroundColor Cyan
Write-Host "    pasta client/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Para PC CLIENTE 2 (Duarte):" -ForegroundColor White
Write-Host "    keystore.afonso" -ForegroundColor Cyan
Write-Host "    keystore.duarte" -ForegroundColor Cyan
Write-Host "    pasta client/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Depois de copiar, correr preparar_cliente.ps1 em cada cliente." -ForegroundColor Yellow
Write-Host ""


# =============================================================
# ARRANCAR O SERVIDOR
# =============================================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  A arrancar o servidor TLS na porta 8080..." -ForegroundColor Cyan
Write-Host "  Password de MAC a inserir: $MAC_PASS" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

java server.MySaudeServer 8080 keystore.afonso $PASS
