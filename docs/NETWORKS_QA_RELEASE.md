# Fluuix 0.3.0 QA — redes EVM configurables

APK ARM64 de AW, con pantalla nativa para agregar, editar, guardar y seleccionar redes EVM mediante nombre, RPC HTTPS, chain ID decimal/hexadecimal, símbolo, decimales y explorador opcional. La red sólo se activa después de consultar su identidad y bloque y guardar el perfil. Los errores no se muestran como saldo cero. Arc y Monad Testnet vienen configuradas mediante la API Fluuix; ZonaFranca sigue siendo un respaldo no configurado, sin conmutación automática.

## Instalación y uso

1. Utilizar Android ARM64, API 26 (Android 8) o posterior. Este requisito de manifest no equivale a aceptación de todos los dispositivos.
2. Verificar el SHA-256 del APK contra SHA256SUMS.txt. Instalar el archivo Fluuix-0.3.0-networks-qa-arm64.apk. Es firma QA temporal, NO identidad de producción del operador.
3. Abrir Fluuix. Seleccionar Arc/Monad y pulsar Verificar conexión, o Agregar red para ingresar los parámetros del RPC. Se requiere consentimiento antes de consultar un nuevo proveedor.
4. Ingresar una dirección pública para consultar saldo NATIVO. ERC-20 arbitrarios, NFT y Solana/otras chains no EVM no están incluidos. MON no es USDC; Arc USDC nativo usa 18 decimales.
5. Para cambiar el RPC de una red ya registrada, usar Editar RPC. No se crean duplicados de chain ID. Máximo 16 perfiles. Editar un perfil no permite modificar su chain ID: agregar otra red para eso.

Paquete: io.fluuix.aw.qa, versión 0.3.0-qa, versionCode 3. Si existe un QA firmado con otro certificado, Android puede rechazar la actualización. DETENERSE: no desinstalar ni borrar datos de wallet, pagos o ajustes para forzar la instalación. Este release no incluye migración entre claves de firma.

## Lo que cambia y lo que no

Es una extensión del mismo repositorio AW. El entry point de este APK es lib/networked_main.dart; el entry point original lib/main.dart y su workspace Arc siguen disponibles mediante el botón explícito Abrir Caja y Agente · Arc Testnet. Los perfiles nuevos son exclusivos de la lectura en la pantalla Redes. NO modifican permisos WalletConnect, el RPC de pagos ni las herramientas arc_* del agente; esas capacidades mantienen Arc Testnet. No se anuncia un runtime agéntico multichain ni se amplían sus permisos.

El modo AW_LAB_TEXT_ONLY continúa usando la aplicación original sin construir el gestor de redes. No se solicitan semillas o claves privadas. Los RPC personalizados se consultan DIRECTAMENTE desde el teléfono, no mediante un proxy abierto en Fluuix. Sólo los dos perfiles preconfigurados utilizan la API de Fluuix. Configurar un RPC no autoriza una transacción, no agrega un activo a otra cadena ni implementa un bridge.

Este release no corrige ni certifica la contabilidad empresarial del workspace original. El defecto de restauración del contador de tesorería documentado previamente continúa fuera del gestor de lectura. No usar esa política local como un límite empresarial autoritativo. Este APK es QA, no un release aprobado para dinero real.

## Seguridad y datos

HTTPS obligatorio, sin redirecciones ni fallback. Identidad eth_chainId verificada antes de leer bloque/saldo. Lectura de saldo fijada al bloque observado. Plazo total 15 s y respuesta limitada a 64 KiB. Métodos disponibles en el cliente: eth_chainId, eth_blockNumber, eth_getBalance; no método RPC genérico. Datos de cantidades procesados con BigInt.

Las URLs RPC con claves del proveedor en path/query se guardan en FlutterSecureStorage; se ocultan en el formulario hasta pedir mostrarlas y no aparecen completas en diagnósticos. No guardar semillas ni claves de firma en esos campos. El operador del RPC conoce la dirección pública consultada y datos de conexión. El tipo de red, nombre y metadatos no conocidos son declarados por el usuario, no atestados por eth_chainId. Un RPC malicioso puede devolver información falsa.

La restauración de perfiles corruptos falla de forma cerrada. Restablecer redes requiere confirmación y sólo reemplaza la clave fluuix_evm_network_profiles_v1; no toca wallet, inferencia o pagos. Al cambiar de red se retiran resultados previos antes de la validación y se publica el estado nuevo sólo después de persistirlo.

## Build y evidencia

La pipeline ejecuta análisis y pruebas Flutter (normal y laboratorio), regresiones existentes del inspector, lecturas reales desde el cliente Dart en el host de CI, compilación AOT nueva, manifest binario, ocho exports nativos, ELF/alineación y firma QA. Las pruebas unitarias usan fixtures; el smoke Dart consulta los dos RPC a través de Fluuix y la dirección pública cero, no la wallet del usuario.

El bridge ARM64 de OpenHuman se REUTILIZA del artifact 11812527906/run 38393284826/commit 7768c172c38f674c8903f2e35a192167b9b4ee78. Antes de usarlo se verifica el SHA-256 del ZIP (e1405bc4ca49e69194350e9259be25b3698c83615d5dcea99fc0e29767bd0ed0), APK, entrada nativa, locks y ausencia de diferencias en las fuentes nativas. No se atribuye una nueva compilación Rust ni una ejecución nativa a este run. Se reconstruye Flutter/Dart y se inspecciona el APK resultante. Un cambio nativo futuro debe obligar a reconstruir esa biblioteca.

La aceptación desde un dispositivo Android real, sus callbacks y el proveedor de inferencia real siguen siendo pruebas separadas. No se infiere su ejecución de un build o un widget test. El archivo SOURCE_COMMIT.txt identifica la revisión y native-reuse.json registra la procedencia del bridge. La fuente empaquetada incluye los componentes inventariados por el empaquetador existente; no afirma reproducibilidad binaria ni un build completamente offline de Gradle/SDK/toolchains.

## Reconstrucción y rollback

Mantener Flutter 3.47.7, Rust 1.96.1 y los pins/locks existentes. Para reconstruir todo: preparar submódulos/parches, compilar el bridge con scripts/build_android_rust.sh arm64-v8a, resolver Flutter con --enforce-lockfile y ejecutar:

```sh
flutter build apk --release --flavor qa --target-platform android-arm64 --target lib/networked_main.dart
```

No usar flutter create ni actualizar indiscriminadamente dependencias. No modificar main para probar este release. Conservar la versión y el certificado instalado; no prescribir una desinstalación destructiva como rollback.

Referencias técnicas revisadas: EIP-3085 y EIP-3326 (validación de identidad, consentimiento y separación de selección); https://docs.arc.io/arc/references/connect-to-arc; documentación Flutter Android; OWASP MASVS-NETWORK-1. Estas referencias guían controles y no representan certificación integral OWASP ni implementación de una wallet MetaMask.
