# =============================================================
# SETUP - Fase 2: Criar Utilizadores no Servidor
# =============================================================
# Usa o programa CriarUser para adicionar utilizadores ao
# ficheiro server_storage/users e à keystore.users do servidor.
#
# Pré-requisito: criar_keys.ps1 já executado (certs necessários).
#
# Utilizadores criados:
#   afonso  - medico   (keystore.afonso / afonso.cer)
#   lima    - medico   (keystore.lima   / lima.cer)
#   duarte  - medico   (keystore.duarte / duarte.cer)
#   bob     - utente   (keystore.alexandre / alexandre.cer)
#
# Password de MAC: usada para proteger a integridade do ficheiro users.
# Deve ser a mesma em server.ps1 (digitada ao arrancar o servidor).
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$MAC_PASS = "macpassword123"
$PASS     = "123456"

Write-Host "`n=== CRIAR UTILIZADORES (Fase 2) ===" -ForegroundColor Cyan
Write-Host "Password de MAC usada: $MAC_PASS" -ForegroundColor DarkYellow

Write-Host "`nA criar utilizador 'afonso' (medico)..." -ForegroundColor Yellow
echo $MAC_PASS | java server.CriarUser afonso medico $PASS -f afonso.cer

Write-Host "`nA criar utilizador 'lima' (medico)..." -ForegroundColor Yellow
echo $MAC_PASS | java server.CriarUser lima medico $PASS -f lima.cer

Write-Host "`nA criar utilizador 'duarte' (medico)..." -ForegroundColor Yellow
echo $MAC_PASS | java server.CriarUser duarte medico $PASS -f duarte.cer

Write-Host "`nA criar utilizador 'bob' (utente)..." -ForegroundColor Yellow
echo $MAC_PASS | java server.CriarUser bob utente $PASS -f alexandre.cer

Write-Host "`n=== FICHEIRO DE UTILIZADORES ===" -ForegroundColor Cyan
Get-Content server_storage/users

Write-Host "`n=== UTILIZADORES CRIADOS COM SUCESSO ===" -ForegroundColor Green
Write-Host "Próximo passo: executar server.ps1 (password MAC: $MAC_PASS)" -ForegroundColor White
