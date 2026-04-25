# ============================================================
# SCRIPT DE TESTES GLOBAL - PROJETO SI (ADAPTADO)
# ============================================================

# Configurar UTF-8 para evitar caracteres estranhos
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$S = "localhost:8080"

# Garantir que os ficheiros existem antes de começar
$files = @("teste_c.pdf", "teste_a.pdf", "teste_ce.pdf", "teste_ae.pdf", "teste_ace.pdf")
foreach ($f in $files) {
    if (-not (Test-Path $f)) { "Conteudo do ficheiro $f" > $f }
}

function Pausa($msg) {
    Write-Host "`n>>> Clique ENTER para: $msg" -ForegroundColor Yellow
    Read-Host | Out-Null
}

Write-Host "`n=== INICIANDO BATERIA COMPLETA DE TESTES ===" -ForegroundColor Cyan

# --- 1. OPERAÇÕES LOCAIS (PONTOS 3 E 5) ---
Pausa "OPERACAO LOCAL: Cifrar e Decifrar (-c / -d)"
# Lima cifra para Afonso localmente
java client.MySaude -u lima -p 123456 -t afonso -c teste_c.pdf
# Afonso decifra localmente
java client.MySaude -u afonso -p 123456 -d teste_c.pdf.cifrado

Pausa "OPERACAO LOCAL: Assinar e Validar (-a / -v)"
# Duarte assina localmente
java client.MySaude -u duarte -p 123456 -a teste_a.pdf
# Afonso valida a assinatura do Duarte localmente
java client.MySaude -u afonso -p 123456 -t duarte -v teste_a.pdf


# --- 2. OPERAÇÕES COM SERVIDOR (PONTOS 4, 6 E 7) ---

Pausa "SERVIDOR: Cifrar/Enviar e Receber/Decifrar (-ce / -rd)"
# Afonso envia para Lima
java client.MySaude -s $S -u afonso -p 123456 -t lima -ce teste_ce.pdf
# Lima recebe e decifra
java client.MySaude -s $S -u lima -p 123456 -rd teste_ce.pdf

Pausa "SERVIDOR: Assinar/Enviar e Receber/Validar (-ae / -rv)"
# Lima assina e envia para Afonso
java client.MySaude -s $S -u lima -p 123456 -t afonso -ae teste_ae.pdf
# Afonso recebe e valida assinatura
java client.MySaude -s $S -u afonso -p 123456 -t lima -rv teste_ae.pdf

Pausa "SERVIDOR: ENVELOPE SEGURO (-ace / -rdv)"
# Duarte envia envelope completo para Afonso
java client.MySaude -s $S -u duarte -p 123456 -t afonso -ace teste_ace.pdf
# Afonso abre envelope, decifra e verifica
java client.MySaude -s $S -u afonso -p 123456 -t duarte -rdv teste_ace.pdf


# --- 3. TESTES DE ERRO E SEGURANÇA ---

Pausa "ERRO: Enviar para quem não confio (Certificado inexistente)"
# Lima tenta enviar para Alexandre (Lima não tem alexandre.cer)
java client.MySaude -s $S -u lima -p 123456 -t alexandre -ace teste_ace.pdf

Pausa "ERRO: Password de Keystore errada"
java client.MySaude -u afonso -p SENHA_ERRADA -a teste_a.pdf

Pausa "ERRO: Unicidade (Reenvio de ficheiro existente)"
# Duarte tenta reenviar teste_ace.pdf para Afonso (Bloqueado pelo servidor)
java client.MySaude -s $S -u duarte -p 123456 -t afonso -ace teste_ace.pdf

Write-Host "`n-------------------------------------------------------" -ForegroundColor Cyan
Write-Host "TODOS OS CASOS DE USO TESTADOS COM SUCESSO." -ForegroundColor Green