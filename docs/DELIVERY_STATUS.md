# Estado de entrega · AW 0.2.0

**Corte de esta revisión: 10 de octubre de 2026, 18:19:14 UTC. El uso final en producción para Arc Testnet sigue pendiente de aceptación Android, E2E real, configuración del operador e integración Fluuix.** Este registro distingue resultados observados, verificaciones anteriores y pasos que todavía deben cerrarse. Los controles no ejecutados y los bloqueos observados se identifican con su alcance. La publicación y los archivos de distribución se vinculan mediante el manifiesto externo de entrega. Los APK QA ya cuentan con cierre estático; esa aceptación no se extiende a la interfaz ni a los servicios externos.

## Implementación disponible en fuente

La aplicación Flutter integra el runtime real de OpenHuman mediante un bridge Rust y una interfaz C ABI. OpenHuman está fijado al commit `036b13e79e4e555ae249f6245966f384d15f35ba`; sus submódulos conservan revisiones concretas y los cambios locales se distribuyen como parches verificables. La aplicación opera sobre Arc Testnet. El agente puede proponer una transferencia; la revisión de la aplicación y la firma de una wallet externa siguen siendo pasos obligatorios.

La fuente incluye configuración de inferencia compatible con OpenAI, almacenamiento seguro de la API key, controles de endpoint, límites de respuesta y timeout, conservación de intenciones de transferencia pendientes, recuperación por hash y variantes Android separadas para QA y firma del operador. La existencia de esas implementaciones no demuestra que un proveedor, wallet o servicio externo haya completado un flujo real.

Actualmente hay **cinco parches autorizados**, descritos y asociados a sus revisiones y SHA-256 en [patches/manifest.json](../patches/manifest.json):

| Parche | Propósito |
|---|---|
| `tinyinference-no-redirect.patch` | Impedir que el transporte de inferencia siga redirecciones. |
| `tinyinference-response-bound.patch` | Acotar la respuesta HTTP antes del ensamblado JSON/SSE. |
| `tinyhosts-shared-tinybus.patch` | Unificar la ruta de TinyBus para que Cargo reconstruya el mismo grafo con `--locked`. |
| `tinytools-android-executable-access.patch` | Corregir la comprobación de ejecutables para las capacidades disponibles en Android. |
| `openhuman-android-updater-policy.patch` | Reconocer los triples Android y rechazar el actualizador nativo en esa plataforma. |

## Verificaciones observadas

| Área | Resultado confirmado | Alcance y límite |
|---|---|---|
| Flutter | Repetición final a las **16:54:34 UTC**: formato sin cambios, análisis sin incidencias y **19/19 pruebas PASS**. | Identifica la fuente local comprobada; no equivale a ejecución del APK. `lib/main.dart` SHA-256: `1f5e56a507794835b80caee111c77f1d9403e52d37eccd07502bdf328eed5df0`. |
| Rust en Linux host | **13/13 pruebas PASS** antes de los parches 4 y 5. | Debe cerrarse la regresión sobre la fuente definitiva; no equivale a ejecución Android. |
| Smoke del bridge nativo | **12 comprobaciones distribuidas en cinco ejecuciones PASS**, con fixture HTTP de inferencia en Linux. | Demuestran los comportamientos ejercitados por esas fixtures. No son inferencia comercial, ejecución Android ni una transacción real. |
| Resolución Cargo | Metadatos con `--locked` verificados en host y para Android; se corrigió la ambigüedad de rutas sin alterar las versiones de los paquetes resueltos. | No acredita binarios idénticos entre máquinas ni sustituye la compilación del destino. |
| Preflight Android | **PASS**. | Verificación previa de la preparación Android; no acredita instalación ni funcionamiento en dispositivo. |
| Optimización Android R8 | **PASS** en los dos APK finales. | La compilación conservó R8 y el encogimiento de recursos. |
| Compilaciones nativas Android | **ARM64 y x86_64 PASS**, con sus cuatro LOAD alineados a 16 KiB, seis exports y dependencias libc/libdl/libm. | ARM64 final comprobado a las 17:08:39 UTC; x86_64 terminó en 23 min 17 s. El rechazo RELRO inicial fue un falso positivo. |
| Filtro ABI | Los dos APK finales contienen **sólo su ABI solicitada**, con cinco bibliotecas en cada destino, incluidas Flutter, AOT y bridge. | Controles separados para arm64-v8a y x86_64. |
| Inspector APK | **21/21 regresiones PASS**. Ambos APK finales pasan el manifiesto, inventario, ELF y ZIP; firma QA y zipalign verificados. | Los dos candidatos previos siguen preservados como rechazados por recursos obsoletos. |
| Recursos en sesión aislada | Preflight **8/8 PASS** a las 17:51:15 UTC, en 48,573 s; después los dos APK completos pasaron. | Input AAPT correcto y temporal .rsync-tmp observado en el intento anterior. El productor de la sustitución previa sigue no identificado. |
| Runtime Android por C ABI | **14/14 aserciones PASS**, seis respuestas, Android 11/API 30/x86_64/páginas de 4096 bytes. | Proceso shell con fixture HTTP sintético; no es Flutter, sandbox del APK, proveedor real ni E2E Arc. |
| Protección de firma `production` | **PASS por rechazo esperado** cuando faltan las credenciales de firma del operador. | Confirma que esa variante no utiliza silenciosamente la firma de QA. No se generó ni aprobó una versión de producción. |
| Verificador de distribución fuente | **10/10 pruebas PASS**; comprobación de los cinco parches sobre **49 repositorios upstream y 19.050 archivos PASS**. | Pruebas del verificador y del árbol local. La creación y extracción del archivo final todavía deben registrarse. |
| Fuentes locales de dependencias | Inventario estricto **PASS**: **412/412 Cargo**, **113/113 Dart**, sin ausencias; 33.557 archivos y 831.725.652 bytes. | El archivo final y su extracción siguen pendientes. No incluye todas las fuentes de Gradle/Maven, motor Flutter, runtime Dart ni toolchains Android; no acredita build sin red ni conformidad legal completa. |

### APK QA: identidad y controles estáticos

La primera secuencia aislada produjo los dos APK con controles estáticos aprobados. Una revisión posterior encontró dos productos nativos auxiliares en ARM64; se añadió una exclusión explícita de esos nombres en Gradle y un rechazo en el inspector. ARM64 se volvió a empaquetar con tareas forzadas, sin caché y sin daemon. El x86_64 ya carecía de esas bibliotecas y volvió a pasar el inspector actualizado, sin reconstrucción. Los **25 archivos identificados de aplicación/runtime conservan sus hashes** respecto de la primera secuencia; la diferencia de política de empaquetado x86_64 afecta únicamente nombres que ya estaban ausentes. La revisión de fuente se consulta con **git rev-parse HEAD** en el checkout y en **SOURCE_MANIFEST.json** dentro del paquete materializado; el manifiesto externo relaciona esos datos con los APK.

| Archivo | Final de creación UTC | Bytes | SHA-256 |
|---|---|---:|---|
| AW-0.2.0-qa-arm64.apk | 18:08:08 | 81.638.024 | 08afee7aa3dc734fa462c863eb8fc4d3e33259d1fabd0a858c2bdd79ba984f1a |
| AW-0.2.0-qa-x86_64.apk | 17:56:51 | 90.986.113 | cf970629c171729ac3689e78326659d72cc71a5a54daadf347926b4aec7ea824 |

Ambos son **io.fluuix.aw.qa**, versión **0.2.0-qa / código 2**, minSdk **26** y targetSdk **36**, release no depurable. Cada APK incluye únicamente su ABI y **cinco bibliotecas**. Ninguno contiene libtinyconnectors.so ni libtinymcp.so; sus capacidades necesarias permanecen enlazadas en el bridge según el grafo de Rust, sin dependencia dinámica adicional de esos productos. El manifiesto conserva callback en launcher, singleTop, flutter_deeplinking_enabled=false, backup deshabilitado y cleartext deshabilitado. Pasaron la inspección ELF/FFI, **zipalign -c -P 16 4** y **apksigner verify**. La firma QA usa un certificado Android Debug, esquema v2, SHA-256 **fd01d8251d48869dc1f90cd7afa7370b0af57fd106ba3a16f4a1a25b12486578**. Esa firma se identifica como QA y no representa la identidad de firma del operador.

La referencia canónica es **android-final-delivery.json**, junto con ambos **android-apk-*-build.json** y los directorios **android-arm64-accepted/** y **android-x86_64-accepted/**. El ARM64 anterior, de SHA-256 **e0986a21feaee964ff33e67ceca081d257547838f5ce407e8f8aa3d56f833b34**, queda preservado en **android-preliminary/arm64-with-auxiliary-products/** como artefacto sustituido. Había pasado los controles estáticos anteriores; el nuevo guard rechaza precisamente sus dos productos auxiliares. La identidad de entrega es exclusivamente la de la tabla anterior. Los controles estáticos no acreditan la interfaz Android, cuyo intento final se describe abajo.

### Bibliotecas nativas y derivación por strip

La biblioteca JNI ARM64 final tiene **61.022.256 bytes**, SHA-256 **319af9fa4bc1553838e1f71059581dd5b86249109db43d2504921ffa025c323d**, cuatro LOAD alineados a 16384 y final RELRO 60964864. La x86_64 tiene **68.823.448 bytes**, SHA-256 **e6ca7c178e03e52f29f35507f4ca445eaf7035574a58d1fdc5e1fccca2224b63**, cuatro LOAD alineados a 16384 y final RELRO 68763648. Ambas exportan los seis símbolos C esperados y dependen dinámicamente sólo de libc, libdl y libm.

Se comprobó que **llvm-strip --strip-unneeded**, del NDK **28.2.13676358**, transforma cada entrada JNI en una biblioteca **idéntica byte a byte** a la del APK final. Los hashes empaquetados son **d9308f2fe3ee5c6b9b9817ef0490b0f88f1367dcf38bcd213bbaeac32cb91ac9** para ARM64 y **6f04aac66069d72def7a0c1e36c8e082cecdaa9637bda0cfd9c97a9c6f3ae468** para x86_64. La diferencia respecto del hash JNI queda explicada por esa derivación verificada.

El inspector original rechazaba todo final RELRO no divisible por 16384. La regla era demasiado estricta: [Bionic, phdr_table_get_relro_min_align](https://android.googlesource.com/platform/bionic/+/android16-qpr2-release/linker/linker_phdr_16kib_compat.cpp) exime la comprobación adicional cuando RELRO empieza en la misma dirección que un PT_LOAD y cubre toda su memoria. Los ELF intermedios, Flutter y DataStore 1.1.7 cumplen ese caso; el redondeo tampoco invade el siguiente segmento escribible. El diagnóstico inicial de incompatibilidad queda **superado como falso positivo** y se conserva en la evidencia. El reenlace con common-page-size=16384 mantiene alineación explícita, sin afirmar un fallo de ejecución del binario anterior.

ARM64 usa **thin LTO**. La compilación x86_64 de aceptación usó **CARGO_PROFILE_RELEASE_LTO=false**, sin LTO entre crates; Cargo puede conservar thin LTO local entre unidades de codegen. [La documentación de Cargo](https://doc.rust-lang.org/cargo/reference/profiles.html#lto) distingue ese valor de off. Son perfiles distintos, registrados por destino. Las versiones fijadas y los hashes de fuentes no acreditan un APK idéntico byte a byte en otro entorno: la clave QA y la metadata de compilación pueden diferir. El TAR tiene su procedimiento determinista, que se verifica por separado.

### Recursos obsoletos: evidencia y cierre operacional

Dos candidatos previos conservaron versión **1 / 1.0-qa** y carecían de flutter_deeplinking_enabled=false, aunque sus manifiestos de entrada ya contenían **2 / 0.2.0-qa** y la opción correcta. Ambos se preservaron fuera de los entregables. Un clean exitoso y una reconstrucción de 90 tareas con **--rerun-tasks --no-build-cache --info** no resolvieron inicialmente la divergencia.

El trazado posterior confirmó que AAPT2 recibió el manifiesto actualizado. El capturador encontró un temporal **.rsync-tmp** que desapareció durante la lectura y falló por ese motivo; AAPT2 terminó con salida 0 y el payload antiguo presentó un ctime nuevo. ctime no identifica a un productor. No se acreditó un hook de pub, una extracción del empaquetador de fuentes ni una causa interna de Gradle/AAPT2. Los controles directos de enlace y sobrescritura con ambas herramientas AAPT2 produjeron los valores sintéticos correctos.

Tras cerrar las sesiones concurrentes y ejecutar en aislamiento, el preflight terminó con salida 0 a las **17:51:15 UTC**, en **48,573 s**, con **8/8 comprobaciones del manifiesto PASS**. Su .ap_ tiene SHA-256 **beedcfd1f1609654264d883e5e11cd80dc59a2362f4b4ad0800387e37cc2d1cf**. Después pasaron los dos APK completos en una sola sesión. La intervención produjo un resultado correcto sin cambios al código del proyecto ni a R8; el productor de la sustitución previa permanece **no determinado**. Se conservan el trazado inicial, sus errores y el control aislado en el expediente.

### Ejecución nativa en Android

La prueba de **android-native-fixture/android_execution.json**, terminada a las **17:45:34 UTC**, cargó la biblioteca JNI x86_64 en Android **11 / API 30**, ABI **x86_64**, páginas de **4096 bytes**. Las seis respuestas C ABI —estado inicial, init, estado inicializado, turno, reset y estado posterior— fueron correctas y las **14 aserciones** pasaron. El runtime indicó Android, ABI 1 y el pin OpenHuman; el fixture recibió el modelo y la credencial sintéticos y sólo las dos herramientas permitidas, sin lecturas Arc.

Es ejecución real de OpenHuman desde un **proceso shell** Android con inferencia sintética. No es aceptación de Flutter ni del sandbox de la aplicación. No acredita proveedor comercial, transacción, cancelación desde la interfaz ni ejecución en un dispositivo de 16 KiB. Esos resultados deben registrarse con su evidencia propia.

### Intento final de instalación e interfaz

La sesión aislada final alcanzó el arranque de Android **11 / API 30 / x86_64 / páginas de 4096 bytes** a las **18:16:01 UTC**. A las **18:16:12 UTC**, antes del intento de instalación, el log registró **FATAL EXCEPTION IN SYSTEM PROCESS** y **Lost network stack**, seguidos de DeadSystemException en componentes del sistema. La instalación del APK x86_64 se inició a las **18:16:47 UTC** y terminó con **salida 20** y **Can't find service: package**. El listado posterior de servicios confirmó la ausencia del servicio package.

**AW no quedó instalada ni se ejecutó su interfaz.** La prueba UI queda **bloqueada por el sistema Android del emulador**, sin atribuir ese fallo a AW. No se obtuvieron estado nativo desde Flutter, turno desde la interfaz ni resultados de pausa, reanudación o cancelación de la app. La captura negra conservada corresponde al sistema del emulador, no a una pantalla de AW. Este resultado no invalida la prueba C ABI shell anterior, que mantiene su propio registro y alcance.

La evidencia está en **android-device-final/session.json**, **apk_install.txt**, **android_crash_log.txt**, **android_services_after_install_attempt.txt** y la captura PNG. La consulta adicional del log de sistema alcanzó un timeout con salida **124**, conservando salida parcial; el cierre con salida 0 del controlador a las **18:19:14 UTC** sólo confirma su terminación ordenada, no una aceptación de UI. La instalación y aceptación deben repetirse en un entorno Android operativo.


## Publicación y CI

La ejecución original de GitHub Actions **38039342817 terminó FAILED y no produjo artefactos**. Los cambios locales corrigen problemas identificados en aquella entrega, pero todavía no existe en este registro una nueva ejecución remota satisfactoria que valide el código corregido.

Después de errores HTTP 403 históricos, la creación de la rama remota `work/android-release-audit-20261010` **sí tuvo éxito el 10 de octubre de 2026 a las 16:40:30 UTC**. Ese resultado acredita la creación de la rama. **El código corregido todavía no se había publicado en el corte de esta revisión.** La revisión publicada, su CI y los enlaces posteriores a este corte se registran en el manifiesto externo de entrega, vinculados al SHA real del commit. Esa actualización de publicación no requiere modificar esta fuente ni el corte de evidencia local aquí descrito.

## Validaciones externas sin evidencia de ejecución

No se acredita en esta revisión una llamada real al RPC público de Arc, una sesión de wallet externa aprobada, una firma, un envío o una confirmación en cadena. Tampoco se acredita inferencia con un proveedor comercial ni una conexión funcional a Fluuix/ZonaFranca. Las pruebas locales y los documentos de integración conservan sus respectivos alcances; no se presentan como prueba E2E de esos servicios.

La compilación y ejecución iOS no forman parte de los resultados aprobados. La presencia de un script iOS es únicamente soporte en fuente pendiente de validar en su entorno.

## Estado de aceptación y registro de distribución

| Campo | Estado al corte |
|---|---|
| Revisión de la fuente local | Consultar **git rev-parse HEAD** y **SOURCE_MANIFEST.json**; relación con APK en el manifiesto externo de entrega |
| Revisión publicada y URL de la rama o PR | Consultar el manifiesto externo de entrega y comprobar el SHA remoto; publicación posterior a este corte local |
| Nueva ejecución remota de CI y artefactos | Resultado y head SHA en el manifiesto externo; no se acredita una nueva ejecución satisfactoria en este corte local |
| Repetición final de análisis y pruebas Flutter | **PASS**, 16:54:34 UTC; 19/19 sobre la fuente identificada arriba |
| Regresión Rust después de los cinco parches | No repetida en host; se conservan las 13 pruebas anteriores, ambas compilaciones Android y la prueba C ABI Android posterior con sus alcances |
| Compilación nativa ARM64 y x86_64 | **PASS** en ambos destinos; salidas, perfiles y hashes identificados arriba |
| RELRO: alcance del verificador y alineación explícita | Diagnóstico inicial superado; 21 regresiones y ELF/ZIP de ambos APK **PASS**. Ejecución en páginas de 16 KiB no realizada |
| APK QA: archivo, tamaño, SHA-256, versión y application ID | **PASS** para ARM64 y x86_64; identidad completa arriba |
| Inspección ELF/ZIP, exports FFI, firma QA y zipalign -P 16 | **PASS** en ambos APK; derivación por strip **PASS** |
| Instalación y aceptación de la interfaz Flutter en Android | **BLOQUEADA** antes de instalar AW: fallo del sistema Android y servicio package ausente; C ABI shell anterior **PASS** |
| Fuente materializada: archivo, checksum, inventario y extracción | Resultados del empaquetado en SOURCE_MANIFEST.json y en el manifiesto externo; el procedimiento y las pruebas del verificador están identificados arriba |
| Cobertura de fuentes de dependencias | Inventario local Cargo/Dart **PASS**; cobertura, ausencias externas y contenido del archivo en los manifiestos de distribución |
| RPC Arc, proveedor de inferencia, wallet, firma y recibo reales | **PENDIENTE; no ejecutados en esta revisión** |
| Integración Fluuix/ZonaFranca y criterios de aceptación | **PENDIENTE; sin validación funcional** |
| Configuración/firma del operador y uso final en producción · Arc Testnet | **PENDIENTE; sujeto a los cierres Android, E2E y Fluuix** |

## Adenda de CI remoto · 18:31 UTC

La revisión `4c28b49e4e3204d9e20340075dd5f98a57231034` se publicó en la rama de trabajo y se abrió el [PR #1](https://github.com/hnasar99/AW/pull/1) como borrador. El [run de push 38075599575](https://github.com/hnasar99/AW/actions/runs/38075599575), job 114281794776, completó checkout, Java, Flutter y preparación de Rust; falló a las 18:27:29 UTC al instalar paquetes Android porque `sdkmanager` no estaba disponible en PATH (salida 127). La compilación de AW no llegó a ejecutarse en ese run.

El workflow ahora prepara explícitamente el SDK mediante `android-actions/setup-android` v4.0.4, fijado al commit `be39fa834029ff78f1a44aa3bb0819b8fc2bd8fd`, con Command-line Tools `15859902` / 22.0 y `platform-tools`. [El código de esa revisión](https://github.com/android-actions/setup-android/blob/be39fa834029ff78f1a44aa3bb0819b8fc2bd8fd/src/main.ts) instala o localiza `sdkmanager`, exporta las rutas del SDK y añade el ejecutable a PATH. La instalación posterior registra ubicación y versión antes de solicitar los paquetes fijados. No solicita el paquete obsoleto `tools`.

Esta corrección de infraestructura no cambia los APK locales, sus fuentes de aplicación/runtime ni los resultados estáticos documentados. El resultado de la nueva ejecución debe comprobarse en el expediente externo vinculado al commit de cierre; todavía no se declara CI remoto satisfactorio en esta adenda.

## Criterio de aceptación

El procedimiento de pruebas está en [OPERATIONS.md](OPERATIONS.md), el alcance de Fluuix en [FLUUIX_INTEGRATION.md](FLUUIX_INTEGRATION.md) y la preparación de fuentes en [SOURCE_DISTRIBUTION.md](SOURCE_DISTRIBUTION.md). Mantenga los logs y los hashes del artefacto al que se atribuye cada resultado. La inspección estática, la firma de QA y los tests automatizados permiten avanzar en la evaluación, pero la aprobación final requiere cerrar las pruebas del dispositivo y de los servicios que formen parte del uso previsto.
