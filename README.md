# FluuiX · AW on Monad

Android treasury app. **Monad Testnet is a first-class network.** OpenHuman stays on the phone. The language model is optional.

## Features on Monad

| Feature | What it does |
|---|---|
| Monad Testnet | Chain ID `10143`. Native asset **MON**, 18 decimals. Not USDC. |
| Fluuix read gateway | Preconfigured profile `https://fluuix-chain-access-testnet.up.railway.app/v1/rpc/monad-testnet`. Upstream is `https://testnet-rpc.monad.xyz`. The app checks `eth_chainId` before a balance read. A failed read stays unknown; it is not shown as zero. |
| Arc Testnet payments | Chain ID `5042002`, USDC. Review, simulation and gas estimate, then an external WalletConnect signature. Monad reads do not sign, swap or bridge. |
| Network screen | Arc and Monad ship as profiles. More EVM HTTPS profiles can be added after the chain identity check. No automatic failover. Entry point: `lib/networked_main.dart`. |
| Optional agent model | **Kimi** (`kimi-k3` at `https://api.moonshot.ai/v1`) is the model for the Monad track narrative. Ollama on loopback and any other OpenAI-compatible `/v1` model are valid too. The model may fill a transfer proposal. It never signs and it does not write to Monad. No API key is shipped in the app. |

Esta iteración de la app de redes es **0.3.0+3**. Consulte [DELIVERY_STATUS.md](DELIVERY_STATUS.md) para conocer las pruebas ejecutadas y las pendientes. `release` describe el modo de compilación; no constituye una aprobación para operar con dinero real.

## Laboratorio de texto local

La misma AW incluye una configuración aislada de laboratorio mediante `--dart-define=AW_LAB_TEXT_ONLY=true`: endpoint loopback y modelo explícitos, sin wallet ni herramientas, y correlación por consulta. El modo Arc sigue siendo el predeterminado. El primer hito **Android → modelo real del laboratorio → respuesta visible en AW** requiere aceptación en los equipos del operador; una build o una fixture no lo acreditan.

La [guía del laboratorio](docs/LOCAL_LLM_LAB.md) comienza con un inventario sin sondeos de red implícitos y documenta configuración, arranque, detención y rollback. La [auditoría](docs/LOCAL_LLM_LAB_AUDIT.md) contrasta los antecedentes con el código fijado; la [matriz de pruebas](docs/LOCAL_LLM_LAB_TEST_MATRIX.md) distingue resultados PASS, FAIL, BLOCKED y NOT RUN. Esta configuración conserva los pins y locks existentes.

## Capacidades y fronteras

- Un único saldo USDC. En Arc, el saldo nativo y la interfaz ERC-20 representan el mismo activo; no se suman.
- Importes con `BigInt`: hasta seis decimales para la transferencia ERC-20 y dieciocho para saldo nativo/comisión. Una entrada con precisión excesiva se rechaza sin redondearla.
- Validación de red, simulación, estimación de gas y revisión inmutable con vencimiento de dos minutos. Un cambio de cuenta, sesión o red invalida la revisión.
- Conexión Reown Sign / WalletConnect y firma externa. La aplicación no pide frases semilla ni importa claves privadas.
- Estado pendiente persistido antes de pedir la firma. Un resultado incierto no se reenvía automáticamente. El recibo y la transacción se cotejan contra lo revisado antes de declarar confirmación.
- OpenHuman real, fijado a una revisión de upstream, con ABI C versionada, sesiones en memoria, cancelación y reinicio. Las llamadas bloqueantes se ejecutan fuera del isolate de interfaz de Flutter.
- Dos herramientas Rust: `arc_network_status` y `arc_balance`. Solo consultan el RPC fijo de Arc Testnet y comprueban el identificador de red.
- Propuestas del modelo con esquema estricto: únicamente pueden llenar el formulario; nunca autorizan o firman por sí mismas.
- Vista normal y misiones sobre el mismo estado. Las misiones reflejan eventos observados y no transacciones simuladas.

**Fluuix/ZonaFranca:** no hay un servidor privado autenticado en esta versión. El contrato para incorporar sus API/MCP está en [docs/FLUUIX_INTEGRATION.md](docs/FLUUIX_INTEGRATION.md). No hace falta clonar sus repositorios privados ni abrir acceso MCP arbitrario.

## Inicio en Android

1. Instale el APK de QA en un teléfono **ARM64 con Android 8.0 (API 26) o posterior**. Su identificador es `io.fluuix.aw.qa`. La compatibilidad declarada por el manifest requiere complementarse con la prueba del dispositivo concreto.
2. En **Ajustes**, configure su **Project ID de Reown**. Es un identificador público del proyecto, no una clave privada.
3. Abra **Wallet** y apruebe una sesión en una wallet que admita WalletConnect y redes EVM personalizadas. Use QR desde otro dispositivo, copie la URI o abra una wallet compatible en el mismo teléfono.
4. Agregue Arc Testnet cuando sea necesario y obtenga USDC de prueba desde el faucet oficial. Compruebe el saldo, ingrese el destinatario y el importe y revise la comisión máxima.
5. Verifique de nuevo los campos en la wallet externa antes de firmar. La app comprueba hash, transacción y recibo. Un timeout se muestra como pendiente o incierto, sin autorizar un segundo envío.
6. En **Agente**, pulse **Verificar ejecución nativa de Rust**. El ABI responde desde la biblioteca cargada; este resultado por sí solo no demuestra inferencia ni una operación on-chain.
7. En **Ajustes**, el modelo es opcional. **Completar con Kimi** carga `https://api.moonshot.ai/v1` y `kimi-k3` para la narrativa de Monad. Ollama usa un loopback como `http://127.0.0.1:11434/v1` y el ID del modelo local. Cualquier otra raíz compatible con `/v1` también sirve. No añada `/chat/completions`. La API key, si el proveedor la pide, la ingresa el operador.

Recordar la API key es optativo. Se conserva junto con su endpoint mediante almacenamiento seguro de Android; editar el endpoint limpia la clave de la interfaz. Los mensajes y resultados de herramientas necesarios para responder se envían al proveedor. Reiniciar el agente limpia su sesión en memoria, pero no borra registros que un proveedor remoto pueda conservar. La UI distingue el texto del modelo de las lecturas efectivamente registradas por las herramientas.

## Arc Testnet

| Parámetro | Valor |
|---|---|
| Chain ID decimal / hexadecimal | `5042002` / `0x4cef52` |
| RPC | `https://rpc.testnet.arc.io` |
| Explorador | `https://explorer.testnet.arc.io` |
| Moneda nativa | USDC, 18 decimales para cantidades RPC nativas |
| Interfaz ERC-20 de USDC | `0x3600000000000000000000000000000000000000`, 6 decimales |
| Faucet | `https://faucet.circle.com/` |

Fuentes: [conexión a Arc](https://docs.arc.io/arc/references/connect-to-arc) y [gas/comisiones](https://docs.arc.io/arc/references/gas-and-fees). La aplicación opera sobre Arc Testnet en todas sus variantes de firma.

## Compilación con versiones fijadas

| Componente | Versión de esta iteración |
|---|---|
| Flutter / Dart | 3.47.7 / 3.13.5 |
| Rust | 1.96.1, fijado en `rust-toolchain.toml` |
| cargo-ndk | 4.1.2 |
| Java | JDK 17 |
| Android SDK / Build-Tools | 36 / 36.0.0; también 35 / 35.0.0 para el plugin JNI |
| CMake | 3.22.1 |
| Android NDK | 28.2.13676358 |
| ABI del APK principal | `arm64-v8a` |
| OpenHuman | `036b13e79e4e555ae249f6245966f384d15f35ba` |

Se incluyen el proyecto Android, `pubspec.lock`, `Cargo.lock`, los submódulos fijados y los hashes de los parches locales. Esto identifica versiones e integridad de fuentes; no garantiza un APK idéntico byte a byte entre entornos, cuyas claves QA y metadata de build pueden diferir. El archivo de fuentes tiene su propio procedimiento determinista, descrito en [SOURCE_DISTRIBUTION.md](docs/SOURCE_DISTRIBUTION.md). No regenere el scaffolding con `flutter create .`: puede reemplazar las decisiones de callback, firma, backup y versiones.

```bash
git clone --recurse-submodules https://github.com/hnasar99/AW.git
cd AW
# Cambie a la revisión exacta de entrega; no asuma que main ya la contiene.
bash scripts/prepare_upstream.sh
cargo install cargo-ndk --version 4.1.2 --locked
rustup target add aarch64-linux-android
flutter pub get --enforce-lockfile
```

Instale el SDK y acepte sus licencias mediante las herramientas oficiales de Android. Defina `ANDROID_HOME` y `ANDROID_NDK_HOME` con sus rutas locales. `android/local.properties` se excluye de Git.

```bash
sdkmanager --install 'platforms;android-35' 'platforms;android-36' \
  'build-tools;35.0.0' 'build-tools;36.0.0' 'cmake;3.22.1' 'ndk;28.2.13676358'
```

```bash
flutter analyze
flutter test
cargo fmt -p arc_openhuman_bridge --check
cargo test --locked -p arc_openhuman_bridge --lib -j 2
bash scripts/build_android_qa.sh
```

El APK se genera en `build/app/outputs/flutter-apk/app-qa-release.apk`. El inspector exige Flutter, Dart AOT y la biblioteca OpenHuman para cada ABI incluida; comprueba los seis símbolos C, la arquitectura, segmentos ELF y final de RELRO para páginas de 16 KiB. Compruebe también firma y empaquetado:

```bash
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --verbose --print-certs \
  build/app/outputs/flutter-apk/app-qa-release.apk
"$ANDROID_HOME/build-tools/36.0.0/zipalign" -c -P 16 -v 4 \
  build/app/outputs/flutter-apk/app-qa-release.apk
```

Las comprobaciones estáticas no sustituyen la instalación y ejecución en Android. En Windows, use `scripts/build_android.ps1`. El script `scripts/build_ios_rust.sh` se conserva como preparación futura: iOS no está soportado ni validado en esta entrega, y aún requiere resolver compatibilidad upstream, Runner, enlace y firma.

## Firma y distribución

`qa` usa un identificador de aplicación separado y una clave de prueba del entorno. Para `productionRelease`, el operador debe configurar `AW_KEYSTORE_PATH`, `AW_KEYSTORE_PASSWORD`, `AW_KEY_ALIAS` y `AW_KEY_PASSWORD`. La tarea falla si falta la configuración o el keystore; no adopta la firma de QA. Las credenciales de firma se mantienen fuera del repositorio y de los logs.

```bash
# Con las variables de firma configuradas de forma segura:
flutter build apk --release --flavor production --target-platform android-arm64
```

El workflow de GitHub Actions genera **QA**. Un workflow corregido localmente no demuestra que se haya ejecutado: su run y sus artefactos se verifican por separado.

## Mapa del código

| Ruta | Responsabilidad |
|---|---|
| `lib/main.dart` | Pantallas, coordinación y revisión explícita |
| `lib/domain/` | Importes, direcciones, propuestas, revisión, recibos y endpoint |
| `lib/services/arc_rpc.dart` | RPC, simulación, comisiones y comprobación de transacción |
| `lib/services/wallet_session.dart` | Sesión Reown, grants, eventos y envío solicitado |
| `lib/openhuman_bridge.dart` | ABI C, tipos, isolates y propiedad de memoria |
| `rust/arc_openhuman_bridge/src/` | OpenHuman, ciclo de vida, validación y herramientas |
| `vendor/openhuman/` | Upstream fijado y sus submódulos |
| `patches/` | Parches locales con procedencia y hashes |
| `scripts/` | Preparación, compilación, inspección y evidencia |
| `docs/` | Operación, integración privada y aceptación |

## Seguridad y licencia

Consulte [docs/OPERATIONS.md](docs/OPERATIONS.md). El agente no tiene herramientas de shell, firma, archivos ni URL arbitraria. Las reglas de ejecución viven en código determinista y la wallet conserva la decisión de firmar.

OpenHuman y el bridge declaran **GPL-3.0-only**. [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) recoge textos y procedencia. La distribución del APK debe acompañarse de las fuentes correspondientes a su revisión exacta, incluidos parches y componentes necesarios para reproducirlo. Un backend independiente consumido por API no se trata aquí como una cesión de sus fuentes.

El uso final en producción se evalúa para Android y Arc Testnet. Los cierres de dispositivo, recorrido E2E, configuración del operador y Fluuix se registran en [DELIVERY_STATUS.md](docs/DELIVERY_STATUS.md).
