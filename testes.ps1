# ============================================================
# SCRIPT DE STRESS TEST - CORRIGIDO PARA ENCODING UTF-8
# ============================================================

# Forçar o terminal a usar UTF-8 para evitar caracteres estranhos
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$S = "localhost:8080"
$PDF = "teste.pdf"

if (-not (Test-Path $PDF)) { "Dados de stress test 2026" > $PDF }

Write-Host "`n=== INICIANDO BATERIA DE TESTES DE STRESS (CLIENTE) ===" -ForegroundColor Cyan
Write-Host "Certifica-te que o Servidor esta a correr em $S"
Write-Host "-------------------------------------------------------"

# Função auxiliar para pausar entre testes (opcional, mas ajuda na apresentação)
function Pausa($msg) {
    Write-Host "`n>>> Clique ENTER para: $msg" -ForegroundColor Yellow
    Read-Host | Out-Null
}

# --- GRUPO 1: SUCESSOS ---
Pausa "[TESTE 1] Envelope Seguro Completo (Lima -> Afonso)"
java client.MySaude -s $S -u lima -p 123456 -t afonso -ace $PDF

Pausa "[TESTE 2] Receber e Validar Envelope (Afonso <- Lima)"
java client.MySaude -s $S -u afonso -p 123456 -t lima -rdv $PDF

Pausa "[TESTE 3] Envelope Seguro Completo 2 (Afonso -> Duarte)"
java client.MySaude -s $S -u afonso -p 123456 -t duarte -ace $PDF

Pausa "[TESTE 4] Receber e Validar Envelope 2 (Duarte <- Afonso)"
java client.MySaude -s $S -u duarte -p 123456 -t afonso -rdv $PDF

# --- GRUPO 2: FALHAS DE CONFIANÇA ---
Pausa "[TESTE 5] Lima tenta enviar para Duarte (Sem Certificado)"
java client.MySaude -s $S -u lima -p 123456 -t duarte -ace $PDF

Pausa "[TESTE 6] Duarte tenta receber de Lima (Sem Certeficado)"
java client.MySaude -s $S -u duarte -p 123456 -t lima -rdv $PDF

Pausa "[TESTE 7] Lima tenta ENVIAR para Alexandre"
java client.MySaude -s $S -u lima -p 123456 -t alexandre -ce $PDF

Pausa "[TESTE 8] Lima tenta RECEBER (Alexandre)"
java client.MySaude -s $S -u lima -p 123456 -t alexandre -rv $PDF

# --- GRUPO 3: SEGURANÇA E ACESSO ---
Pausa "[TESTE 9] Password Errada (Keystore Afonso)"
java client.MySaude -u afonso -p PASS_TOTALMENTE_ERRADA -a $PDF

Pausa "[TESTE 10] Utilizador Fantasma (Sem Keystore)"
java client.MySaude -u fantasma -p 123456 -a $PDF

# --- GRUPO 4: REGRAS DO SERVIDOR ---
Pausa "[TESTE 11] Teste de Unicidade (Reenvio)"
java client.MySaude -s $S -u lima -p 123456 -t afonso -ace $PDF

Pausa "[TESTE 12] Download de Ficheiro Inexistente"
java client.MySaude -s $S -u afonso -p 123456 -rd ficheiro_que_nao_existe.pdf

Write-Host "`n-------------------------------------------------------" -ForegroundColor Cyan
Write-Host "STRESS TEST FINALIZADO." -ForegroundColor Green