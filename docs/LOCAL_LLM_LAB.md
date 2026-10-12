# AW: laboratorio de inferencia local

## Objetivo y corte de evidencia

El primer hito es **enviar una consulta desde AW, procesarla con un modelo del laboratorio y mostrar su respuesta en AW, con evidencia correlacionada y sin capacidad de mover fondos**. Ese hito está **BLOCKED**: esta revisión no dispone del Android ni del servidor del laboratorio. No se ha ejecutado inferencia real, instalado un APK nuevo ni reproducido el recorrido de interfaz. No se necesita una blockchain, fondos, una wallet ni una API comercial para este ensayo.

La base inspeccionada es `hnasar99/AW`, commit `f5567e7819cf6c486a2cba9ae6d448ddada054fe`, en la rama de trabajo `work/local-llm-lab-20261012`. La revisión exacta posterior debe registrarse con `git rev-parse HEAD`; si hay cambios sin commit, conservar también el diff y sus hashes. El informe del preflight identifica el commit, si el árbol está modificado y el SHA-256 de su propio script. Un commit con árbol modificado no identifica por sí solo todos sus bytes.

| Clasificación | Evidencia o alcance |
|---|---|
| EXISTENTE Y VERIFICADO | Lectura del baseline: `arc_openhuman_init`, `Provider::openai_compatible`, modelo configurado, herramientas `arc_network_status`/`arc_balance` y validación de transporte. Es comprobación de fuente, no inferencia real. |
| REPORTADO SIN REVERIFICAR | La entrega anterior incluye ensayos Linux y Android shell con respuestas sintéticas. No se trasladan sus resultados a este modo nuevo ni al recorrido de interfaz. Véase [estado de entrega anterior](DELIVERY_STATUS.md). |
| PROPUESTO | Android conectado por USB al host de inferencia, `adb reverse` de un puerto elegido y Ollama con un modelo local adecuado al inventario. No hay un gateway inicial. |
| IMPLEMENTADO SIN PROBAR EN EL LABORATORIO | La UI `AW_LAB_TEXT_ONLY=true` y la integración Android del contrato nativo aditivo requieren un APK propio, instalación y aceptación. Los comandos de esta guía no constituyen evidencia de ejecución. |
| PROBADO | Baseline Python: 31/31. Preflight: 15/15. Rust actualizado: 15/15 y biblioteca host compilada. Regresión nativa Arc seleccionada: 7 comprobaciones PASS, 5 no ejecutadas. Smoke nativo del laboratorio: 17/17 PASS con HTTP sintético. Son pruebas host/sintéticas; no se han probado macOS, Windows, la GPU ni los equipos del usuario. |

La [matriz de pruebas](LOCAL_LLM_LAB_TEST_MATRIX.md) diferencia PASS, FAIL, BLOCKED y NOT RUN. Los resultados de fixtures permanecen identificados como tales.

Este es un **corte local del 12 de octubre de 2026, previo al cierre de CI de la rama**. El [informe nativo del laboratorio](evidence/local-llm-lab/lab-native-smoke.json) conserva 17 PASS, 0 FAIL, 0 BLOCKED y 0 NOT RUN dentro de su suite seleccionada. Sus campos de alcance mantienen Android/UI, Ollama real, laboratorio del usuario, Arc/wallet reales y captura global de red como NOT RUN. Ese conteo no cambia el estado BLOCKED del primer hito.

## 1. Primera acción en el laboratorio: sólo inventario

**Equipo:** el ordenador que podría alojar el modelo y al que se conectaría Android por USB. **Directorio:** la raíz de esta copia de AW, donde existen `pubspec.yaml` y `scripts/`. No ejecutar este comando en otro equipo y atribuirle sus recursos al laboratorio.

Con Python 3 disponible, ejecutar únicamente:

```bash
python3 -B scripts/lab/preflight.py --output ../aw-lab-host-inventory.json
```

En Windows, con el lanzador de Python instalado:

```powershell
py -3 -B scripts/lab/preflight.py --output ../aw-lab-host-inventory.json
```

**Devolver:** `aw-lab-host-inventory.json` y el código de salida. El directorio de salida debe existir; el script rechaza sobrescribir un archivo. Para repetir, elegir otro nombre. No hace falta conectar la wallet, proporcionar claves, arrancar Ollama o conectar Android en este primer paso.

El comando registra OS, arquitectura, CPU, afinidad, RAM y límites visibles de contenedor; inventaría herramientas y consulta las versiones locales seguras de Git/Java/OpenSSL. No ejecuta versiones de Flutter/Cargo/Ollama que puedan inicializar SDKs o contactar servicios. No recoge hostname, interfaces/IP, variables de entorno completas ni claves. Los resultados desconocidos permanecen vacíos o NOT RUN. Los límites cgroup se leen de rutas estándar; no se asegura descubrir toda restricción anidada ni disponibilidad para un modelo concreto.

Un código de salida **0** significa que los inventarios solicitados terminaron sin FAIL/BLOCKED; no significa que el laboratorio esté listo ni que AW haya inferido. **1** indica al menos un FAIL; **2**, un BLOCKED o un error de uso. El JSON contiene el detalle; un error de uso no genera un resultado de prueba. El inventario GPU es optativo mediante `--gpu`; Linux DRM o `nvidia-smi` pueden identificar dispositivos visibles. Otras rutas sin consulta disponible quedan BLOCKED, no se interpretan como ausencia de GPU.

El executor de esta revisión es Linux x86_64, con 9 CPU visibles, cuota cgroup de 8 CPU, RAM visible de 10.451.464.192 bytes y límite cgroup de 8.589.934.592 bytes. Esos datos **no son el hardware del laboratorio del usuario**. No se selecciona ni descarga un modelo a partir de ellos. Evidencia: `aw-lab-evidence/preflight/executor-inventory.json`, fuera del repositorio.

## 2. Recorrido y configuración que se deben comprobar

| Componente | Equipo | Responsabilidad |
|---|---|---|
| AW Flutter | Android seleccionado | Interfaz de laboratorio y evidencia de solicitud/respuesta. |
| OpenHuman y bridge Rust | Proceso de AW en Android | Turno limitado, política sin herramientas, transporte al endpoint aprobado. |
| `adb reverse` | Cliente adb en el host y dispositivo USB seleccionado | Mapear un puerto loopback del teléfono al puerto loopback del host. |
| Ollama y pesos elegidos | Host del laboratorio | Ejecutar la inferencia local; conservar evidencia de modelo, digest y proceso. |

`127.0.0.1` designa el propio equipo en cada lado. El reenvío USB es lo que relaciona ambos loopbacks; configurar esa dirección en AW sin el reenvío no conecta el teléfono con el host. Los puertos, el dispositivo, el modelo y el estado del servicio deben verificarse antes de ejecutar los pasos siguientes. No se presuponen una LAN, un overlay, certificados ni puertos accesibles.

El baseline construye el proveedor con una **raíz compatible**, como `http://127.0.0.1:PUERTO/v1`, y el transporte añade `/chat/completions`. No introducir esa ruta completa en Ajustes. `InitOptions::new` exige una key no vacía; para Ollama local puede usarse un marcador sintético, por ejemplo `ollama`. **Ese marcador no autentica**: Ollama documenta que su API local no requiere autenticación. Véanse [validación del bridge](../rust/arc_openhuman_bridge/src/validation.rs), [inicialización](../rust/arc_openhuman_bridge/src/agent.rs), [compatibilidad OpenAI de Ollama](https://docs.ollama.com/api/openai-compatibility) y [autenticación de Ollama](https://docs.ollama.com/api/authentication).

El modo de laboratorio exige loopback **literal** y la raíz `/v1`; no selecciona automáticamente otro proveedor. El preflight usa un argumento diferente, `--ollama-origin`, **sin `/v1`**, para consultar las rutas de inventario `/api/version`, `/api/tags` y `/api/ps`. Esos GET no cargan un modelo ni generan una respuesta. La lista de modelos y su digest apoyan el inventario, pero no prueban por sí solos procesamiento local. Fuentes: [modelos disponibles](https://docs.ollama.com/api/tags), [modelos cargados](https://docs.ollama.com/api/ps), [referencia API del mantenedor](https://github.com/ollama/ollama/blob/main/docs/api.md).

El sondeo optativo no sigue redirecciones, no hereda proxies del entorno, no envía credenciales y acota cada cuerpo a 256 KiB. La espera de socket es de 5 s. HTTPS mantiene la validación de certificados de Python; un PASS de ese cliente no acredita el almacén de confianza del transporte Rust. Instalar una CA en Android o modificar su XML no demuestra que Rust confíe en ella. La primera topología usa HTTP sólo sobre los loopbacks unidos por USB; no requiere desactivar TLS ni ampliar HTTP a una red.

## 3. Después del inventario: comprobar el servicio elegido

Estos pasos están **pendientes** y deben aplicarse a la configuración real que devuelva el laboratorio. Ollama es un candidato, no una dependencia del producto. Elegir modelo, licencia, tamaño, cuantización, digest, contexto y concurrencia con el hardware observado. El tamaño del archivo de pesos no es el consumo total de RAM/VRAM. Empezar con una sola consulta y medir; no se establece aquí un mínimo de hardware certificado ni un modelo por defecto.

Si se elige Ollama, comprobar que el proceso que atenderá AW tiene cloud deshabilitado. La [FAQ oficial](https://docs.ollama.com/faq) documenta `OLLAMA_NO_CLOUD=1`, o `disable_ollama_cloud: true` en su configuración, reinicio y el registro `Ollama cloud disabled: true`. Una variable en la terminal del preflight no acredita la configuración de un daemon ya arrancado. Tampoco basta con que su URL sea local: un servidor local puede ofrecer modelos remotos.

Para un proceso dedicado al ensayo en Linux/Bash, una vez verificado y asignado `AW_LAB_PORT`:

```bash
: "${AW_LAB_PORT:?Defina el puerto loopback verificado para este ensayo}"
OLLAMA_NO_CLOUD=1 OLLAMA_CONTEXT_LENGTH=4096 OLLAMA_HOST="127.0.0.1:$AW_LAB_PORT" ollama serve
```

Esto es un arranque en primer plano del proceso elegido. Si ya existe un servicio, comprobar su configuración y gestionarlo según su instalación; no lanzar un segundo proceso sobre el mismo puerto. En otra terminal, con la misma variable de puerto verificada:

```bash
python3 -B scripts/lab/preflight.py --ollama-origin "http://127.0.0.1:$AW_LAB_PORT" --output ../aw-lab-ollama-inventory.json
```

Devolver ese JSON y la evidencia de cloud deshabilitado del proceso, sin credenciales ni el volcado de prompts. Si la lista está vacía, detener la secuencia y seleccionar/materializar un modelo antes del ensayo. Si un modelo hace referencia a un proveedor remoto, no usarlo para acreditar inferencia local. La guía no descarga modelos ni activa APIs comerciales.

El bridge fija un presupuesto de contexto de **4096 tokens** para el ID seleccionado; esto evita el descubrimiento automático de metadatos del proveedor. No configura el servidor ni detecta su capacidad. El modelo elegido debe admitir ese contexto, el proceso de Ollama debe recibir la configuración y `/api/ps` debe permitir corroborar el contexto cargado cuando haya un modelo en ejecución. La rama también desactiva hooks/exportadores del runtime y rechaza credenciales hosted o proxies de entorno heredados en el proceso de AW; un rechazo `LAB_ENVIRONMENT` requiere revisar ese proceso, sin borrar credenciales de otros trabajos.

## 4. Conectar un Android identificado

Sólo después de identificar el host, conectar por USB un Android autorizado, habilitar depuración USB y aceptar en el dispositivo la autorización de ese ordenador. [Android documenta](https://developer.android.com/tools/adb) la selección explícita con `-s`; también advierte que adb puede iniciar su servidor local y que el estado `device` no garantiza que Android haya completado el arranque.

```bash
adb devices -l
```

Registrar el dispositivo elegido. Definir `AW_LAB_SERIAL` con su serial real y mantener `AW_LAB_PORT` con el puerto ya verificado. No escoger automáticamente el primer dispositivo. El sondeo siguiente sólo consulta metadatos y puede iniciar el servidor local de adb; no instala, abre AW ni crea reenvíos:

```bash
python3 -B scripts/lab/preflight.py --adb-serial "$AW_LAB_SERIAL" --output ../aw-lab-android-inventory.json
```

Comprobar versión Android, ABI, arranque, RAM y tamaño de página. El informe sustituye el serial por su hash. Si hay estado no autorizado, dispositivo offline, error del sistema o arranque incompleto, resolverlo antes de instalar. Con ese requisito aprobado, configurar únicamente el reenvío del ensayo:

```bash
adb -s "$AW_LAB_SERIAL" reverse "tcp:$AW_LAB_PORT" "tcp:$AW_LAB_PORT"
adb -s "$AW_LAB_SERIAL" reverse --list
```

Conservar el mapeo observado. La app usará `http://127.0.0.1:PUERTO_VERIFICADO/v1`, sustituyendo el puerto por el valor real. No usar una IP privada inventada ni habilitar adb TCP en la LAN como recuperación automática.

## 5. Compilar y aceptar el modo de texto

La build usa **`--dart-define=AW_LAB_TEXT_ONLY=true`** y una biblioteca nativa nueva. No basta con el APK anterior: el bridge debe exponer `arc_openhuman_init_lab(endpoint,key,model,cache_root)` y `arc_openhuman_turn_lab(prompt,session,request_id)`. ABI 1 conserva sus funciones existentes y añade estas entradas. El proceso fija su modo incluso después de reset.

El contrato exige `supported_modes` con `proposal-only` y `lab-text-only`. En laboratorio, init/status deben indicar `mode: lab-text-only`, `inference: lab-endpoint` y `tools: []`. Un turno devuelve el mismo `request_id`, `duration_ms` entero, `model_requested` y `live_reads: []`. La UI debe rechazar una biblioteca antigua o un resultado que no acredite esos campos. El contrato de las implementaciones se identifica en [bridge Dart](../lib/openhuman_bridge.dart), [configuración](../lib/domain/inference_config.dart) y [fuente nativa](../rust/arc_openhuman_bridge/src/). Su aceptación en Android sigue pendiente.

### Comprobación nativa disponible

La suite [smoke_native_lab.py](../scripts/lab/smoke_native_lab.py) terminó con salida 0 sobre la biblioteca real Linux x86_64 de OpenHuman y su C ABI, usando un servidor HTTP sintético. Los 17 casos verificaron init/status sin herramientas, JSON y SSE acumulado en una respuesta final, ruta `/v1/chat/completions`, modelo e ID correlacionados, cambio de modelo tras reset, rechazo de rutas/modelos/IDs inválidos y herramientas no autorizadas, cancelación/reset, modo fijo tras reset, HTTP 401/404/307, servicio detenido, timeout, guardas de entorno, limpieza y ausencia de canarios en stdout/stderr capturados. Los ocho subcasos de entorno se ejecutaron en procesos nuevos y verifican la guarda de inicialización; no acreditan mutaciones de entorno durante un turno.

El fixture recibió **19 solicitudes y cero GET** desde su inicio hasta la observación del último reset/status, incluidos los resets intermedios. El timeout devolvió `TIMEOUT` tras **120,004 s observados** (`duration_ms: 120003`), exigió reset y permitió recuperar un turno. Las respuestas y los nombres de modelos eran sintéticos: no se cargaron pesos ni se midió inferencia real. El control de cero GET corresponde al fixture configurado; no es una captura global de egress ni una garantía sobre tráfico posterior. Del mismo modo, la denegación de herramientas y `live_reads: []` no sustituyen una captura de todos los paquetes del proceso. La identidad de la biblioteca y del harness se conserva en el [JSON exacto](evidence/local-llm-lab/lab-native-smoke.json), y la relación con las fuentes, en la [proveniencia de build](evidence/local-llm-lab/native-build-provenance.json).

### Compilación e instalación en Android

En un host con las herramientas fijadas y la ABI **arm64-v8a** confirmada, la secuencia de compilación es:

```bash
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter test --dart-define=AW_LAB_TEXT_ONLY=true
python3 -B -m unittest discover -s scripts/tests -p 'test_*.py' -v
python3 -B -m unittest discover -s scripts/lab -p 'test_*.py' -v
bash scripts/build_android_rust.sh arm64-v8a
flutter build apk --release --flavor qa --target-platform android-arm64 --dart-define=AW_LAB_TEXT_ONLY=true
```

La variante x86_64 requiere cambiar de forma coherente la ABI nativa a `x86_64` y el destino Flutter a `android-x64`; no se selecciona sin identificar el Android. Cada orden depende del éxito de la anterior. Aplicar los controles existentes del APK con `scripts/inspect_apk.py`, aapt2/readelf del SDK/NDK fijados, firma y alineación, y conservar SHA-256, comando y salidas. El wrapper QA del baseline no reenvía argumentos adicionales de Flutter; el define debe llegar a la orden de build real. Véanse [instrucciones de build](../README.md) y [inspector](../scripts/inspect_apk.py).

El workflow de esta rama construye por separado `aw-qa-arm64.apk` y `aw-lab-arm64.apk`, con manifiesto de modos y verificaciones propias. Ambos corresponden al paquete QA existente `io.fluuix.aw.qa`; instalar uno sustituye esa variante de la aplicación. No son una nueva aplicación ni una firma de producción. Elegir el APK **lab** por su hash/registro de build y comprobar el modo visible antes de configurar el ensayo. Un artifact de CI aprobado no acredita instalación ni inferencia en Android.

Las dos variantes usan la misma `applicationId`. **Si la firma QA del APK difiere de la instalación existente y Android rechaza la actualización, detenerse. No desinstalar automáticamente ni borrar datos para resolverlo**, porque se perdería el estado local. Registrar el rechazo y comprobar la identidad de las firmas antes de decidir cómo conservar o migrar ese estado.

Instalar sólo el APK cuyo modo, ABI e identidad se hayan registrado. Abrir **AW · Laboratorio de texto**, comprobar los controles visibles del modo y configurar endpoint, modelo local exacto y marcador sintético. El ensayo no debe restaurar una wallet, consultar cotizaciones ni realizar RPC Arc. El éxito de inicialización no es una respuesta del modelo.

Enviar una consulta breve con datos sintéticos y conservar:

| Punto | Evidencia necesaria |
|---|---|
| Identidad | Commit/diff, hash APK, firma, ABI, versión Android, modelo/digest y versión del servidor. |
| Solicitud en AW | ID `awlab-` seguido de 32 caracteres hexadecimales minúsculos, modelo solicitado, inicio/resultado y duración. |
| Servidor local | Recepción y procesamiento correlacionables con ese ID, modelo/digest, proceso local y tiempos. No basta con que `/api/ps` liste un modelo. |
| Resultado visible | Respuesta mostrada en AW, mismo ID y `live_reads: []`; registrar captura del ensayo sintético. |
| Recursos | RAM/VRAM, CPU/GPU y tiempos medidos en el equipo real, identificando instrumento e intervalo. |

El bridge añade `[AW-LAB-REQUEST-ID: <id>]` al prompt. Es un marcador, no un header HTTP ni una garantía de que el modelo lo repetirá. Los logs normales del servidor pueden no contenerlo; hace falta una observación verificada que extraiga sólo ID/modelo/tiempos o un mecanismo equivalente. No se ha implementado aquí una captura de prompts ni un gateway de auditoría. Un eco generado por el modelo no sustituye la evidencia del servidor. `duration_ms` mide el turno del bridge, no exclusivamente tiempo de generación del modelo.

## 6. Errores y puertas de avance

Probar por separado servidor detenido, puerto/endpoint erróneo, timeout y cancelación desde la UI. Conservar ID, tiempos y resultado visible; no registrar keys ni prompts. Una cancelación local no demuestra que el servidor haya terminado su trabajo. No recuperar mediante cloud. El error debe dejar al usuario en un estado conocido y, cuando el runtime lo exija, requerir reset antes de otra consulta.

El rechazo de autenticación real queda **BLOCKED** con Ollama nativo sin autenticación. La key sintética ignorada no permite una prueba negativa de credenciales. Los HTTP 401 sintéticos del preflight y del smoke nativo sólo prueban su tratamiento de errores; comprobar que el fixture recibió una key sintética tampoco acredita autenticación de Ollama. Los fallos de conexión, ruta, redirección, timeout y cancelación ya tienen PASS en el fixture host, pero deben repetirse desde la UI y el servidor reales. Si después se necesita acceso fuera del loopback o una frontera autenticada, evaluar un componente pequeño con una necesidad concreta y verificar TLS/autenticación del transporte real; no se agrega por anticipación.

La **etapa 2** permanece cerrada hasta aprobar la inferencia real de texto. Debe habilitar sólo las herramientas de lectura verificadas y probar nombre/argumentos/permisos, datos malformados, RPC caído y contenido externo malicioso. El LLM no puede elegir endpoints ni elevar permisos. La **etapa 3** incorpora proveedores explícitos después del laboratorio, con pruebas propias de autenticación, mensajes, streaming, herramientas, esquemas y errores; no hay sustitución silenciosa por una API comercial.

La billetera dinámica y la tesorería empresarial son objetivos posteriores. La primera conserva separación entre saldo excluido y autorizado y trabaja en simulación; activo concreto, contrato, red y ruta deben verificarse antes de diseñar operaciones. La segunda separa interpretación documental, propuesta, autorización y ejecución. Este ensayo no implementa estrategias, pagos, swaps, firmas ni nuevos permisos financieros. Monad no es una dependencia de esta conexión: no se encontró una referencia implementada en las rutas de aplicación/runtime revisadas; el título de una conversación no constituye evidencia de integración.

## 7. Detención y rollback

Detener el turno desde AW y conservar su resultado. Cerrar el proceso dedicado de Ollama con Ctrl-C si se inició en primer plano; si se gestiona como servicio, usar el procedimiento de esa instalación. No detener servicios de otros trabajos ni confundir reset del agente con parada del servidor.

Retirar únicamente el mapeo creado para este ensayo:

```bash
adb -s "$AW_LAB_SERIAL" reverse --remove "tcp:$AW_LAB_PORT"
```

Los archivos de evidencia se conservan fuera del repo. Los ajustes de laboratorio deben mantenerse separados de los del modo Arc. El rollback de código consiste en volver al commit baseline en una rama o worktree de revisión, o revertir los commits específicos del laboratorio después de conservar el trabajo local. No usar un reset destructivo sobre cambios ajenos ni modificar `main` directamente. Volver a una build normal requiere compilarla sin `AW_LAB_TEXT_ONLY=true` y verificar su identidad; no reutilizar sin revisión un APK cuyo modo no se conoce.

## Fuentes y límites de las comprobaciones

Los enlaces primarios de Ollama y Android anteriores fueron consultados el 12 de octubre de 2026. El código del baseline y la evidencia de esta iteración se distinguen de esas referencias. La biblioteca y los avisos de licencia existentes permanecen en el producto; la licencia del modelo elegido también debe registrarse. Esta guía no certifica cumplimiento OWASP o de distribución íntegro: aplica límites concretos al preflight y mantiene pendientes los ensayos reales de transporte, UI y servidor.
