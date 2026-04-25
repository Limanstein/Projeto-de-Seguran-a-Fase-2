# =============================================================
# INICIAR SERVIDOR MySaude (Fase 2 - TLS)
# =============================================================
# Pré-requisitos:
#   1. criar_keys.ps1 já executado
#   2. criar_users.ps1 já executado
#
# O servidor pedirá a password de MAC ao arrancar.
# Usar a mesma password definida em criar_users.ps1 (ex: macpassword123)
#
# O certificado do servidor é o de 'afonso' (CN=afonso).
# Os clientes usam keystore.afonso como trustStore para TLS.
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

Write-Host "=== A INICIAR SERVIDOR MySaude (TLS, porto 8080) ===" -ForegroundColor Cyan
Write-Host "Será pedida a password de MAC do servidor." -ForegroundColor Yellow
Write-Host "(Use a mesma password de quando criou os utilizadores)" -ForegroundColor Yellow

java server.MySaudeServer 8080 keystore.afonso 123456
