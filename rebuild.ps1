# =============================================================
# RECOMPILAR - Todos os ficheiros Java do projeto
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

Write-Host "A compilar servidor e cliente..." -ForegroundColor Cyan

javac -encoding UTF-8 `
    server/PasswordManager.java `
    server/MacManager.java `
    server/CriarUser.java `
    server/MySaudeServer.java `
    client/KeyUtils.java `
    client/CryptoUtils.java `
    client/MySaude.java

if ($LASTEXITCODE -eq 0) {
    Write-Host "Compilação concluída com sucesso." -ForegroundColor Green
} else {
    Write-Host "ERRO de compilação. Verifique os ficheiros .java." -ForegroundColor Red
}
