# =============================================================
# LIMPEZA - Reset completo do ambiente de testes
# =============================================================
# Remove keystores, certificados, ficheiros gerados e server_storage.
# Após executar, requer criar_keys.ps1 -> criar_users.ps1 -> server.ps1.
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

Write-Host "`n=== LIMPEZA DO AMBIENTE ===" -ForegroundColor Cyan

# Parar processo a usar o porto 8080 (servidor), se existir
$conn = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($conn) {
    $pid8080 = $conn.OwningProcess | Select-Object -First 1
    Stop-Process -Id $pid8080 -Force -ErrorAction SilentlyContinue
    Write-Host "Servidor parado (PID $pid8080)." -ForegroundColor Yellow
}

# Remover keystores e certificados
Remove-Item keystore.* -ErrorAction SilentlyContinue
Remove-Item *.cer      -ErrorAction SilentlyContinue

# Remover ficheiros gerados pelo cliente
Remove-Item *.cifrado     -ErrorAction SilentlyContinue
Remove-Item *.decifrado   -ErrorAction SilentlyContinue
Remove-Item *.envelope    -ErrorAction SilentlyContinue
Remove-Item *.assinado    -ErrorAction SilentlyContinue
Remove-Item "*.chave.*"   -ErrorAction SilentlyContinue
Remove-Item "*.assinatura.*" -ErrorAction SilentlyContinue
Remove-Item "recebido_*"  -ErrorAction SilentlyContinue

# Remover server_storage (users, MAC, ficheiros enviados)
if (Test-Path "server_storage") {
    Remove-Item -Recurse -Force "server_storage"
    Write-Host "server_storage removido." -ForegroundColor Yellow
}

# Remover ficheiros de teste criados pelos scripts
Remove-Item "teste_fase1_*.pdf", "teste_fase2_*.pdf", "ficheiro_teste_*.pdf" -ErrorAction SilentlyContinue

Write-Host "`n=== LIMPEZA CONCLUÍDA ===" -ForegroundColor Green
Write-Host "Para recomeçar: criar_keys.ps1 -> criar_users.ps1 -> server.ps1" -ForegroundColor White
