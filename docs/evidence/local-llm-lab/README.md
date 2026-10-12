# Evidencia seleccionada · laboratorio AW

Estos registros vinculan las comprobaciones realizadas con el baseline, los hashes de fuentes y la biblioteca host. Las rutas absolutas en los JSON identifican el entorno donde se ejecutó cada comprobación; no son dependencias del producto ni ubicaciones que existan en el laboratorio del usuario.

- `github-baseline.json`: lectura remota de PR1, merge y CI del baseline. La fecha de guardado no se presenta como hora exacta de la consulta.
- `baseline.json` y `baseline-python.log`: estado y pruebas anteriores a la edición de esta rama.
- `preflight-tests.json` y `executor-inventory.json`: fixtures del inventario y recursos del executor; no son recursos del laboratorio del usuario.
- `native-build-provenance.json` y `rust-unit-tests.log`: hashes del código/biblioteca host y 15 pruebas Rust. La copia del log elimina únicamente líneas vacías al final para su almacenamiento en git; el resultado no se altera.
- `legacy-native-smoke.json`: regresión seleccionada del modo Arc sobre la biblioteca nueva, con HTTP sintético. Sus estados originales `passed/failed/skipped` se corresponden con PASS/FAIL/NOT RUN en la matriz.
- `flutter-local-validation.json`: fuente y formato Dart verificados; bloqueo del bootstrap local de Flutter y pruebas todavía no ejecutadas en ese entorno. Los resultados de CI posteriores tienen evidencia propia.
- `android-reqwest-features.txt`: grafo efectivo para Android, sin realizar una conexión TLS ni ejecutar un APK.

La [matriz](../../LOCAL_LLM_LAB_TEST_MATRIX.md) distingue cada entorno. Un PASS de build, fuente o fixture no aprueba el hito Android → modelo del laboratorio → UI. Las evidencias posteriores del servidor deben incluir identidad del modelo/proceso y correlación con la solicitud, sin registrar secretos ni contenidos de producción.
