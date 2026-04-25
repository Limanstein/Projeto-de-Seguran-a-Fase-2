# =============================================================
# TESTES FASE 1 - Operações Locais (sem servidor)
# =============================================================
# Testa as operações criptográficas que funcionam localmente:
#   -c  Cifrar ficheiro (AES/CBC + RSA)
#   -d  Decifrar ficheiro
#   -a  Assinar ficheiro (RSA/SHA-256)
#   -v  Verificar assinatura
#
# Pré-requisito: criar_keys.ps1 já executado (keystores criados).
# NÃO precisa do servidor a correr.
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$PASS = "123456"

function Pausa($msg) {
    Write-Host "`n>>> Prima ENTER para: $msg" -ForegroundColor Yellow
    Read-Host | Out-Null
}

function Resultado($esperado) {
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  => OK ($esperado)" -ForegroundColor Green
    } else {
        Write-Host "  => FALHOU (esperado: $esperado)" -ForegroundColor Red
    }
}

# Criar ficheiros de teste
if (-not (Test-Path "ficheiro_teste_f1.pdf")) { "Conteudo de teste - Fase 1" | Out-File -Encoding UTF8 "ficheiro_teste_f1.pdf" }

Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host " TESTES FASE 1 - Operações Locais" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan


# =============================================================
# TESTE 1: Cifrar e Decifrar (-c / -d)
# Lima cifra para Afonso; Afonso decifra.
# =============================================================
Pausa "TESTE 1 - Cifrar e Decifrar (-c / -d)"

Write-Host "`n[1a] Lima cifra 'ficheiro_teste_f1.pdf' para Afonso (-c):" -ForegroundColor White
java client.MySaude -u lima -p $PASS -t afonso -c ficheiro_teste_f1.pdf

Write-Host "`n[1b] Afonso decifra o ficheiro cifrado (-d):" -ForegroundColor White
java client.MySaude -u afonso -p $PASS -d ficheiro_teste_f1.pdf.cifrado

Write-Host "`n[1c] Verificar integridade (decifrado == original):" -ForegroundColor White
$orig     = Get-Content "ficheiro_teste_f1.pdf"    -Raw
$decifrado = Get-Content "ficheiro_teste_f1.pdf.decifrado" -Raw -ErrorAction SilentlyContinue
if ($orig -eq $decifrado) {
    Write-Host "  => PASSOU: conteúdo decifrado é idêntico ao original." -ForegroundColor Green
} else {
    Write-Host "  => FALHOU: conteúdo diferente após decifração!" -ForegroundColor Red
}


# =============================================================
# TESTE 2: Assinar e Verificar (-a / -v)
# Duarte assina; Afonso verifica.
# =============================================================
Pausa "TESTE 2 - Assinar e Verificar (-a / -v)"

Write-Host "`n[2a] Duarte assina 'ficheiro_teste_f1.pdf' (-a):" -ForegroundColor White
java client.MySaude -u duarte -p $PASS -a ficheiro_teste_f1.pdf

Write-Host "`n[2b] Afonso verifica a assinatura de Duarte (-v):" -ForegroundColor White
java client.MySaude -u afonso -p $PASS -t duarte -v ficheiro_teste_f1.pdf

Write-Host "`n[2c] Afonso verifica assinatura de Lima (Lima não assinou - esperado INVÁLIDA):" -ForegroundColor White
java client.MySaude -u afonso -p $PASS -t lima -v ficheiro_teste_f1.pdf


# =============================================================
# TESTE 3: Erros de autenticação local
# =============================================================
Pausa "TESTE 3 - Erros (password errada / utilizador sem keystore)"

Write-Host "`n[3a] Password de keystore errada - deve falhar:" -ForegroundColor White
java client.MySaude -u afonso -p SENHA_ERRADA -a ficheiro_teste_f1.pdf

Write-Host "`n[3b] Utilizador sem keystore ('fantasma') - deve falhar:" -ForegroundColor White
java client.MySaude -u fantasma -p $PASS -a ficheiro_teste_f1.pdf

Write-Host "`n[3c] Lima tenta cifrar para Alexandre (sem certificado local, sem servidor):" -ForegroundColor White
Write-Host "     (esperado: erro - certificado não encontrado)" -ForegroundColor DarkYellow
java client.MySaude -u lima -p $PASS -t alexandre -c ficheiro_teste_f1.pdf


# =============================================================
# RESUMO
# =============================================================
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host " TESTES FASE 1 CONCLUÍDOS" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Ficheiros gerados:" -ForegroundColor White
Get-ChildItem "ficheiro_teste_f1.pdf*" | ForEach-Object { Write-Host "  $($_.Name)" }
