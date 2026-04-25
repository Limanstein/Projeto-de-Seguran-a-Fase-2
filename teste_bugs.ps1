$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$S = "localhost:8080"
$PDF = "teste_ace.pdf"

Write-Host "`n=== SETUP: Compilar ===" -ForegroundColor Cyan
javac server/MySaudeServer.java client/MySaude.java client/CryptoUtils.java client/KeyUtils.java
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO DE COMPILACAO" -ForegroundColor Red; exit 1 }

Write-Host "`n=== SETUP: Criar Keystores ===" -ForegroundColor Cyan
keytool -genkeypair -alias afonso -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.afonso -validity 365 -storepass 123456 -keypass 123456 -dname "CN=afonso" 2>&1 | Out-Null
keytool -genkeypair -alias lima   -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.lima   -validity 365 -storepass 123456 -keypass 123456 -dname "CN=lima"   2>&1 | Out-Null

keytool -exportcert -alias afonso -keystore keystore.afonso -file afonso.cer -storepass 123456 2>&1 | Out-Null
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.lima   -storepass 123456 -noprompt 2>&1 | Out-Null

keytool -exportcert -alias lima -keystore keystore.lima -file lima.cer -storepass 123456 2>&1 | Out-Null
keytool -importcert -alias lima -file lima.cer -keystore keystore.afonso -storepass 123456 -noprompt 2>&1 | Out-Null

Write-Host "Keystores criadas (afonso <-> lima com confianca mutua)" -ForegroundColor Green

Write-Host "`n=== SETUP: Iniciar Servidor em background ===" -ForegroundColor Cyan
$servidor = Start-Process -FilePath "java" -ArgumentList "server.MySaudeServer 8080" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2
Write-Host "Servidor iniciado (PID $($servidor.Id))" -ForegroundColor Green

# Limpar ficheiros recebidos e storage de testes anteriores
Remove-Item -ErrorAction SilentlyContinue "recebido_*"
Remove-Item -ErrorAction SilentlyContinue -Recurse "server_storage"
Remove-Item -ErrorAction SilentlyContinue "*.envelope", "*.chave.*", "*.assinatura.*"

# ============================================================
# TESTE 1: Envelope Seguro - envio (Lima -> Afonso)
# ============================================================
Write-Host "`n=== TESTE 1: Envelope Seguro - Lima envia para Afonso (-ace) ===" -ForegroundColor Cyan
java client.MySaude -s $S -u lima -p 123456 -t afonso -ace $PDF

# ============================================================
# TESTE 2: Receber envelope (Afonso recebe de Lima)
# PROBLEMA 1: verificar que o ficheiro recebido termina com extensao correta
# ============================================================
Write-Host "`n=== TESTE 2: Afonso recebe e valida envelope (-rdv) ===" -ForegroundColor Cyan
java client.MySaude -s $S -u afonso -p 123456 -t lima -rdv $PDF

$nomesperado = "teste_ace.decifrado"
$envelopeRecebido = "recebido_teste_ace.pdf.envelope"

Write-Host "`n--- Verificacao PROBLEMA 1 (nomes de ficheiros) ---" -ForegroundColor Yellow

if (Test-Path $nomesperado) {
    Write-Host "PASSOU - Ficheiro decifrado existe como '$nomesperado'" -ForegroundColor Green
} else {
    Write-Host "FALHOU - Ficheiro '$nomesperado' nao encontrado. Ficheiros recebidos:" -ForegroundColor Red
    Get-ChildItem "recebido_*" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.Name)" }
    Get-ChildItem "*.decifrado" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.Name)" }
}

if (Test-Path $envelopeRecebido) {
    Write-Host "PASSOU - Envelope recebido com nome correto: '$envelopeRecebido'" -ForegroundColor Green
} else {
    Write-Host "FALHOU - Envelope recebido sem extensao correta. Ficheiros recebidos:" -ForegroundColor Red
    Get-ChildItem "recebido_*" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.Name)" }
}

# ============================================================
# TESTE 3: PROBLEMA 2 - download duplicado (lado cliente)
# Afonso tenta fazer download de novo do mesmo envelope
# ============================================================
Write-Host "`n=== TESTE 3: PROBLEMA 2 - Afonso tenta receber o mesmo envelope outra vez ===" -ForegroundColor Cyan
Write-Host "(Esperado: mensagem de erro - ficheiro ja existe localmente)"
$output3 = java client.MySaude -s $S -u afonso -p 123456 -t lima -rdv $PDF 2>&1 | Out-String
Write-Host $output3

if ($output3 -match "existe localmente" -or $output3 -match "already exists") {
    Write-Host "PASSOU - Mensagem de duplicado local corretamente emitida" -ForegroundColor Green
} else {
    Write-Host "FALHOU - Nao houve mensagem de duplicado local" -ForegroundColor Red
}

# ============================================================
# TESTE 4: PROBLEMA 2 - upload duplicado (lado servidor)
# Lima tenta enviar o mesmo ficheiro outra vez
# ============================================================
Write-Host "`n=== TESTE 4: PROBLEMA 2 - Lima tenta enviar o mesmo envelope outra vez ===" -ForegroundColor Cyan
Write-Host "(Esperado: servidor rejeita com ERRO)"
$output4 = java client.MySaude -s $S -u lima -p 123456 -t afonso -ace $PDF 2>&1 | Out-String
Write-Host $output4

if ($output4 -match "ERRO" -or $output4 -match "ja existe" -or $output4 -match "ja existe") {
    Write-Host "PASSOU - Servidor rejeitou reenvio corretamente" -ForegroundColor Green
} else {
    Write-Host "FALHOU - Servidor nao rejeitou o reenvio" -ForegroundColor Red
}

# ============================================================
# LIMPEZA
# ============================================================
Write-Host "`n=== LIMPEZA ===" -ForegroundColor Cyan
Stop-Process -Id $servidor.Id -ErrorAction SilentlyContinue
Write-Host "Servidor parado."

Write-Host "`n=== TESTES CONCLUIDOS ===" -ForegroundColor Cyan
