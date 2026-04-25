# =============================================================
# TESTES FASE 2 - Operações com Servidor (TLS + Autenticação)
# =============================================================
# Cobre todos os requisitos da Fase 2:
#   A. Confidencialidade de passwords (formato users)
#   B. Integridade MAC (password errada / adulteração)
#   C. CriarUser (duplicado, função inválida)
#   D. Canal seguro TLS
#   E. Gestão de certificados (fetch automático)
#   F. Autenticação e Controlo de acesso (medico/utente)
#   + Operações combinadas: -e/-r, -ce/-rd, -ae/-rv, -ace/-rdv
#   + Unicidade de ficheiros no servidor
#
# Pré-requisito: criar_keys.ps1, criar_users.ps1 e server.ps1 já executados.
# Password de MAC usada: macpassword123
# =============================================================

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null

$S        = "localhost:8080"
$PASS     = "123456"
$MAC_PASS = "macpassword123"

# Flags TLS para o cliente (necessário para certificados auto-assinados)
$JVM = "-Djavax.net.ssl.trustStore=keystore.afonso", "-Djavax.net.ssl.trustStorePassword=$PASS"

function Pausa($msg) {
    Write-Host "`n>>> Prima ENTER para: $msg" -ForegroundColor Yellow
    Read-Host | Out-Null
}

# Criar ficheiros de teste
$f2 = "ficheiro_teste_f2.pdf"
if (-not (Test-Path $f2)) { "Conteudo de teste Fase 2 - $(Get-Date)" | Out-File -Encoding UTF8 $f2 }

Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host " TESTES FASE 2 - Operações com Servidor (TLS)" -ForegroundColor Cyan
Write-Host " Servidor: $S" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan


# =============================================================
# GRUPO A/B/C - Gestão de Utilizadores e Integridade MAC
# =============================================================
Pausa "GRUPO A/B/C - Gestão de utilizadores e MAC"

Write-Host "`n[A] Verificar formato do ficheiro users (username:funcao:salt:digest):" -ForegroundColor White
Get-Content "server_storage/users"

Write-Host "`n[C1] CriarUser com username já existente (esperado: erro):" -ForegroundColor White
echo $MAC_PASS | java server.CriarUser afonso medico $PASS -f afonso.cer

Write-Host "`n[C2] CriarUser com função inválida (esperado: erro):" -ForegroundColor White
java server.CriarUser novo_user enfermeiro $PASS -f afonso.cer

Write-Host "`n[B1] Arranque do servidor com password de MAC ERRADA (esperado: termina):" -ForegroundColor White
Write-Host "     (inicia servidor na porta 9999 apenas para demonstração)" -ForegroundColor DarkYellow
echo "MAC_PASSWORD_ERRADA" | java server.MySaudeServer 9999 keystore.afonso $PASS 2>&1 | Select-Object -First 3

Write-Host "`n[B2] Adulteração do ficheiro users e arranque (esperado: termina com aviso):" -ForegroundColor White
$usersFile = "server_storage/users"
$backup = Get-Content $usersFile -Raw
"linha_adulterada_pelo_adversario" | Add-Content $usersFile
echo $MAC_PASS | java server.MySaudeServer 9999 keystore.afonso $PASS 2>&1 | Select-Object -First 3
# Restaurar ficheiro original
[System.IO.File]::WriteAllText((Resolve-Path $usersFile), $backup)
echo $MAC_PASS | java server.MacManager 2>&1 | Out-Null  # só para suprimir output
# Recalcular MAC após restauro (adicionar utilizador dummy e remover)
Write-Host "     (ficheiro users restaurado)" -ForegroundColor DarkYellow


# =============================================================
# GRUPO D - Canal Seguro TLS
# =============================================================
Pausa "GRUPO D - Canal Seguro TLS"

Write-Host "`n[D] Envio simples de ficheiro via TLS (-e / -r):" -ForegroundColor White
Write-Host "    Afonso (medico) envia para Lima:" -ForegroundColor DarkYellow
java $JVM client.MySaude -s $S -u afonso -p $PASS -t lima -e $f2

Write-Host "`n    Lima recebe:" -ForegroundColor DarkYellow
Remove-Item "recebido_$f2" -ErrorAction SilentlyContinue
java $JVM client.MySaude -s $S -u lima -p $PASS -r $f2


# =============================================================
# GRUPO E - Gestão de Certificados (fetch automático)
# =============================================================
Pausa "GRUPO E - Gestão de Certificados (fetch automático do servidor)"

Write-Host "`n[E] Lima cifra+envia para Duarte (Lima NÃO tem cert de Duarte):" -ForegroundColor White
Write-Host "    O cliente deve ir buscar o certificado ao servidor automaticamente." -ForegroundColor DarkYellow
$fCE = "ficheiro_teste_f2_ce.pdf"
if (-not (Test-Path $fCE)) { "Conteudo CE para Duarte" | Out-File -Encoding UTF8 $fCE }
java $JVM client.MySaude -s $S -u lima -p $PASS -t duarte -ce $fCE

Write-Host "`n    Duarte recebe e decifra:" -ForegroundColor DarkYellow
Remove-Item "recebido_$fCE.cifrado", "recebido_$fCE.chave.duarte" -ErrorAction SilentlyContinue
java $JVM client.MySaude -s $S -u duarte -p $PASS -rd $fCE

Write-Host "`n    Verificar integridade (decifrado == original):" -ForegroundColor White
$orig = Get-Content $fCE -Raw
$dec  = Get-Content "$fCE.decifrado" -Raw -ErrorAction SilentlyContinue
if ($orig -eq $dec) { Write-Host "  => PASSOU: conteúdo idêntico." -ForegroundColor Green }
else                { Write-Host "  => FALHOU: conteúdo diferente!" -ForegroundColor Red }


# =============================================================
# GRUPO F - Autenticação e Controlo de Acesso
# =============================================================
Pausa "GRUPO F - Autenticação e Controlo de Acesso"

Write-Host "`n[F1] Upload com password ERRADA (esperado: autenticação falha):" -ForegroundColor White
java $JVM client.MySaude -s $S -u afonso -p SENHA_ERRADA -t lima -e $f2

Write-Host "`n[F2] Utilizador INEXISTENTE (esperado: autenticação falha):" -ForegroundColor White
java $JVM client.MySaude -s $S -u nao_existe -p $PASS -t lima -e $f2

Write-Host "`n[F3] Bob (UTENTE) tenta fazer upload (esperado: acesso negado):" -ForegroundColor White
java $JVM client.MySaude -s $S -u bob -p $PASS -t afonso -e $f2

Write-Host "`n[F4] Bob (UTENTE) faz download (esperado: OK - utentes podem receber):" -ForegroundColor White
Remove-Item "recebido_$f2" -ErrorAction SilentlyContinue
java $JVM client.MySaude -s $S -u afonso -p $PASS -t bob -e $f2
java $JVM client.MySaude -s $S -u bob -p $PASS -r $f2


# =============================================================
# GRUPO - Cifrar+Enviar / Receber+Decifrar (-ce / -rd)
# =============================================================
Pausa "Cifrar+Enviar e Receber+Decifrar (-ce / -rd)"

$fOp = "ficheiro_teste_f2_op.pdf"
if (-not (Test-Path $fOp)) { "Conteudo operacao combinada" | Out-File -Encoding UTF8 $fOp }

Write-Host "`n[CE] Afonso cifra+envia para Lima (-ce):" -ForegroundColor White
java $JVM client.MySaude -s $S -u afonso -p $PASS -t lima -ce $fOp

Write-Host "`n[RD] Lima recebe+decifra (-rd):" -ForegroundColor White
Remove-Item "recebido_$fOp.cifrado", "recebido_$fOp.chave.lima" -ErrorAction SilentlyContinue
java $JVM client.MySaude -s $S -u lima -p $PASS -rd $fOp

Write-Host "`n    Verificar integridade:" -ForegroundColor White
if ((Get-Content $fOp -Raw) -eq (Get-Content "$fOp.decifrado" -Raw -ErrorAction SilentlyContinue)) {
    Write-Host "  => PASSOU" -ForegroundColor Green } else { Write-Host "  => FALHOU" -ForegroundColor Red }


# =============================================================
# GRUPO - Assinar+Cifrar+Enviar / Receber+Decifrar+Verificar (-ae / -rv)
# =============================================================
Pausa "Assinar+Enviar e Receber+Verificar (-ae / -rv)"

$fAE = "ficheiro_teste_f2_ae.pdf"
if (-not (Test-Path $fAE)) { "Conteudo ae para afonso" | Out-File -Encoding UTF8 $fAE }

Write-Host "`n[AE] Lima assina+cifra+envia para Afonso (-ae):" -ForegroundColor White
java $JVM client.MySaude -s $S -u lima -p $PASS -t afonso -ae $fAE

Write-Host "`n[RV] Afonso recebe+decifra+verifica assinatura de Lima (-rv):" -ForegroundColor White
Remove-Item "recebido_$fAE.cifrado", "recebido_$fAE.chave.afonso", "recebido_$fAE.assinatura.lima" -ErrorAction SilentlyContinue
java $JVM client.MySaude -s $S -u afonso -p $PASS -t lima -rv $fAE


# =============================================================
# GRUPO - Envelope Seguro (-ace / -rdv)
# =============================================================
Pausa "Envelope Seguro Completo (-ace / -rdv)"

$fACE = "ficheiro_teste_f2_ace.pdf"
if (-not (Test-Path $fACE)) { "Conteudo envelope seguro" | Out-File -Encoding UTF8 $fACE }

Write-Host "`n[ACE] Duarte cria envelope seguro para Afonso (-ace):" -ForegroundColor White
Write-Host "      (assinar + cifrar + enviar em 1 operação)" -ForegroundColor DarkYellow
java $JVM client.MySaude -s $S -u duarte -p $PASS -t afonso -ace $fACE

Write-Host "`n[RDV] Afonso abre envelope de Duarte (-rdv):" -ForegroundColor White
Write-Host "      (receber + decifrar + verificar assinatura em 1 operação)" -ForegroundColor DarkYellow
Remove-Item "recebido_$fACE.envelope", "recebido_$fACE.chave.afonso", "recebido_$fACE.assinatura.duarte" -ErrorAction SilentlyContinue
java $JVM client.MySaude -s $S -u afonso -p $PASS -t duarte -rdv $fACE

Write-Host "`n    Verificar integridade (decifrado == original):" -ForegroundColor White
if ((Get-Content $fACE -Raw) -eq (Get-Content "$fACE.decifrado" -Raw -ErrorAction SilentlyContinue)) {
    Write-Host "  => PASSOU" -ForegroundColor Green } else { Write-Host "  => FALHOU" -ForegroundColor Red }


# =============================================================
# GRUPO - Unicidade e Duplicados
# =============================================================
Pausa "Unicidade (reenvio bloqueado pelo servidor)"

Write-Host "`n[U1] Duarte tenta reenviar o mesmo envelope para Afonso (esperado: erro):" -ForegroundColor White
java $JVM client.MySaude -s $S -u duarte -p $PASS -t afonso -ace $fACE

Write-Host "`n[U2] Afonso tenta receber o mesmo envelope outra vez (esperado: erro local):" -ForegroundColor White
java $JVM client.MySaude -s $S -u afonso -p $PASS -t duarte -rdv $fACE

Write-Host "`n[U3] Download de ficheiro inexistente (esperado: NOT_FOUND):" -ForegroundColor White
java $JVM client.MySaude -s $S -u afonso -p $PASS -r "ficheiro_que_nao_existe.pdf"


# =============================================================
# RESUMO FINAL
# =============================================================
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host " TESTES FASE 2 CONCLUÍDOS" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Conteúdo do servidor (server_storage):" -ForegroundColor White
Get-ChildItem -Recurse "server_storage" | Where-Object { -not $_.PSIsContainer } |
    ForEach-Object { Write-Host "  $($_.FullName.Replace((Get-Location).Path + '\',''))" }
