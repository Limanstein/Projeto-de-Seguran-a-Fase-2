# =============================================================
# SETUP - Fase 2: Criação de Keystores e Certificados
# =============================================================
# Cria os pares de chaves RSA-2048 para todos os utilizadores
# e estabelece as relações de confiança necessárias para os testes.
#
# Relações de confiança estabelecidas:
#   keystore.lima   <- afonso.cer   (TLS + lima cifra para afonso)
#   keystore.afonso <- lima.cer     (afonso verifica assinatura de lima)
#   keystore.afonso <- duarte.cer   (afonso verifica assinatura de duarte)
#   keystore.duarte <- afonso.cer   (TLS + duarte cifra para afonso)
#   keystore.alexandre <- afonso.cer (TLS)
#
# INTENCIONAL - NÃO importado (para testar Ponto E - fetch automático):
#   keystore.lima NAO tem duarte.cer
#
# Executar UMA VEZ antes de criar_users.ps1 e server.ps1.
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$PASS = "123456"

Write-Host "`n=== CRIAÇÃO DE KEYSTORES ===" -ForegroundColor Cyan

Write-Host "A criar keystore de afonso..." -ForegroundColor Yellow
keytool -genkeypair -alias afonso -keyalg RSA -keysize 2048 -storetype JKS `
        -keystore keystore.afonso -validity 365 `
        -storepass $PASS -keypass $PASS -dname "CN=afonso" 2>&1 | Out-Null

Write-Host "A criar keystore de lima..." -ForegroundColor Yellow
keytool -genkeypair -alias lima -keyalg RSA -keysize 2048 -storetype JKS `
        -keystore keystore.lima -validity 365 `
        -storepass $PASS -keypass $PASS -dname "CN=lima" 2>&1 | Out-Null

Write-Host "A criar keystore de duarte..." -ForegroundColor Yellow
keytool -genkeypair -alias duarte -keyalg RSA -keysize 2048 -storetype JKS `
        -keystore keystore.duarte -validity 365 `
        -storepass $PASS -keypass $PASS -dname "CN=duarte" 2>&1 | Out-Null

Write-Host "A criar keystore de alexandre..." -ForegroundColor Yellow
keytool -genkeypair -alias alexandre -keyalg RSA -keysize 2048 -storetype JKS `
        -keystore keystore.alexandre -validity 365 `
        -storepass $PASS -keypass $PASS -dname "CN=alexandre" 2>&1 | Out-Null

Write-Host "`n=== EXPORTAÇÃO DE CERTIFICADOS ===" -ForegroundColor Cyan
keytool -exportcert -alias afonso    -keystore keystore.afonso    -file afonso.cer    -storepass $PASS 2>&1 | Out-Null
keytool -exportcert -alias lima      -keystore keystore.lima      -file lima.cer      -storepass $PASS 2>&1 | Out-Null
keytool -exportcert -alias duarte    -keystore keystore.duarte    -file duarte.cer    -storepass $PASS 2>&1 | Out-Null
keytool -exportcert -alias alexandre -keystore keystore.alexandre -file alexandre.cer -storepass $PASS 2>&1 | Out-Null
Write-Host "Exportados: afonso.cer  lima.cer  duarte.cer  alexandre.cer" -ForegroundColor Green

Write-Host "`n=== RELAÇÕES DE CONFIANÇA ===" -ForegroundColor Cyan
# Lima confia em Afonso (TLS + cifrar para afonso)
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.lima      -storepass $PASS -noprompt 2>&1 | Out-Null
# Afonso confia em Lima (verificar assinatura de lima + cifrar para lima)
keytool -importcert -alias lima   -file lima.cer   -keystore keystore.afonso    -storepass $PASS -noprompt 2>&1 | Out-Null
# Afonso confia em Duarte (verificar assinatura de duarte)
keytool -importcert -alias duarte -file duarte.cer -keystore keystore.afonso    -storepass $PASS -noprompt 2>&1 | Out-Null
# Duarte confia em Afonso (TLS + cifrar para afonso)
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.duarte    -storepass $PASS -noprompt 2>&1 | Out-Null
# Alexandre confia em Afonso (TLS)
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.alexandre -storepass $PASS -noprompt 2>&1 | Out-Null
Write-Host "Confiança estabelecida." -ForegroundColor Green

Write-Host "`n=== SETUP DE CHAVES CONCLUÍDO ===" -ForegroundColor Green
Write-Host "Próximo passo: executar criar_users.ps1" -ForegroundColor White
