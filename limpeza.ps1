echo "--- A limpar ambiente e server_storage ---"
Remove-Item keystore.*, *.cer, *.cifrado, *.chave.*, *.assinatura.*, *.envelope, *.decifrado, recebido_* -ErrorAction SilentlyContinue
if (Test-Path "server_storage") { Remove-Item -Recurse -Force "server_storage" }