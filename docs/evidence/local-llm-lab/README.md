# Evidencia seleccionada · laboratorio AW

Estos registros vinculan las comprobaciones realizadas con el baseline, los hashes de fuentes y la biblioteca host. Las rutas absolutas en los JSON identifican el entorno donde se ejecutó cada comprobación; no son dependencias del producto ni ubicaciones que existan en el laboratorio del usuario.

- `github-baseline.json`: lectura remota de PR1, merge y CI del baseline. La fecha de guardado no se presenta como hora exacta de la consulta.
- `baseline.json` y `baseline-python.log`: estado y pruebas anteriores a la edición de esta rama.
- `preflight-tests.json` y `executor-inventory.json`: fixtures del inventario y recursos del executor; no son recursos del laboratorio del usuario.
- `native-build-provenance.json` y `rust-unit-tests.log`: hashes del código/biblioteca host y 15 pruebas Rust. La copia del log elimina únicamente líneas vacías al final para su almacenamiento en git; el resultado no se altera.
- `legacy-native-smoke.json`: regresión seleccionada del modo Arc sobre la biblioteca nueva, con HTTP sintético. Sus estados originales `passed/failed/skipped` se corresponden con PASS/FAIL/NOT RUN en la matriz.
- `lab-native-smoke.json`: copia exacta del informe completo `aw-lab-evidence/lab-native-full/report.json`, sin reserializar ni modificar sus bytes. La biblioteca host real Linux x86_64 y el HTTP sintético aprobaron los 17 casos, incluidos el timeout nativo de 120 s, reset/recuperación y las guardas de inicialización en procesos nuevos. Este es un resultado local previo al cierre de CI de la rama.
- `flutter-local-validation.json`: fuente y formato Dart verificados; bloqueo del bootstrap local de Flutter y pruebas todavía no ejecutadas en ese entorno. Los resultados de CI posteriores tienen evidencia propia.
- `android-reqwest-features.txt`: grafo efectivo para Android, sin realizar una conexión TLS ni ejecutar un APK.

## Identidad y alcance del smoke de laboratorio

`lab-native-smoke.json` tiene **48.263 bytes** y SHA-256 **`f110988ea667f9d32f8ed67b942a556c87c4f3579110c706eea579a557363a3d`**. El informe registra salida 0 y 17 PASS / 0 FAIL / 0 BLOCKED / 0 NOT RUN para sus casos; conserva los hashes de la biblioteca, el harness, los helpers y los logs. Sus campos `started_utc` y `completed_utc` sitúan el proceso principal entre las 23:12:53 y las 23:16:25 UTC del 12 de octubre de 2026. La [proveniencia de build](native-build-provenance.json) documenta por separado su relación con las fuentes.

El fixture recibió 19 solicitudes y cero GET hasta la observación del reset/status final, incluidos los resets anteriores. No es una captura global de egress ni cubre tráfico posterior. La respuesta `TIMEOUT` se observó a los 120,004 s, con `duration_ms: 120003`, reset requerido y recuperación comprobada. El HTTP 401 fue sintético: no prueba autenticación de Ollama ni rechazo de una credencial real. El envío de una key sintética al fixture sólo verifica el contrato de transporte.

El informe mantiene UI/Android, Ollama real, laboratorio del usuario, Arc/wallet reales y captura global de paquetes como NOT RUN. Las ocho guardas de entorno se probaron antes de inicializar bibliotecas en procesos nuevos; no se mutó el entorno de un proceso Rust vivo. La comprobación de canarios cubre únicamente stdout/stderr de los hijos capturados. No se registran las claves ni los prompts completos y no se cargó ni ejecutó un modelo real.

La [matriz](../../LOCAL_LLM_LAB_TEST_MATRIX.md) distingue cada entorno. Un PASS de build, fuente o fixture no aprueba el hito Android → modelo del laboratorio → UI. Las evidencias posteriores del servidor deben incluir identidad del modelo/proceso y correlación con la solicitud, sin registrar secretos ni contenidos de producción.
