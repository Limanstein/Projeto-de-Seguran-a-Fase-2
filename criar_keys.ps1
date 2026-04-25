# 1. Utilizador COMPLETO (Afonso)
echo "--- Criando Keystore para AFONSO (Pass: 123456) ---"
keytool -genkeypair -alias afonso -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.afonso -validity 365 -storepass 123456 -keypass 123456 -dname "CN=afonso"

# 2. Utilizador REMETENTE (Lima)
echo "--- Criando Keystore para LIMA (Pass: 123456) ---"
keytool -genkeypair -alias lima -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.lima -validity 365 -storepass 123456 -keypass 123456 -dname "CN=lima"

# 3. Utilizador ERRO (Duarte)
echo "--- Criando Keystore para DUARTE (Pass: 123456) ---"
keytool -genkeypair -alias duarte -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.duarte -validity 365 -storepass 123456 -keypass 123456 -dname "CN=duarte"

# 4. Utilizador MISTÉRIO (Alexandre)
echo "--- Criando Keystore para ALEXANDRE (Pass: 123456) ---"
keytool -genkeypair -alias alexandre -keyalg RSA -keysize 2048 -storetype JKS -keystore keystore.alexandre -validity 365 -storepass 123456 -keypass 123456 -dname "CN=alexandre"

# 5. Troca de Certificados (Lima <-> Afonso, Afonso <-> Duarte)
echo "--- Estabelecendo confiança entre Lima/Afonso e Afonso/Duarte (certs) ---"

# Afonso exporta, Lima importa
keytool -exportcert -alias afonso -keystore keystore.afonso -file afonso.cer -storepass 123456
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.lima -storepass 123456 -noprompt

# Lima exporta, Afonso importa
keytool -exportcert -alias lima -keystore keystore.lima -file lima.cer -storepass 123456
keytool -importcert -alias lima -file lima.cer -keystore keystore.afonso -storepass 123456 -noprompt

# Duarte exporta, Afonso importa
keytool -exportcert -alias duarte -keystore keystore.duarte -file duarte.cer -storepass 123456
keytool -importcert -alias duarte -file duarte.cer -keystore keystore.afonso -storepass 123456 -noprompt

# Afonso exporta, Duarte importa
keytool -importcert -alias afonso -file afonso.cer -keystore keystore.duarte -storepass 123456 -noprompt

echo "--- SETUP CONCLUiDO ---"