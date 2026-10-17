# Historial de validación de redes configurables

## Primer intento: análisis

2026-10-13: run 38458987279, commit ee4248177ad097a03c6bbe92830cf47aa6389060, FAILED antes de las pruebas y del APK. Flutter analyze detectó un return Future sin await dentro de try en network_controller.dart y tres avisos en el smoke CLI (dos imports relativos de lib y print). No hubo artefactos ni aceptación móvil en ese intento.

La corrección mantiene el analyzer y sus reglas: await explícito, imports package y stdout.writeln para el ejecutable CLI. El workflow usa bash explícito para propagar también fallos de pipes como el smoke con tee. Las aserciones y requisitos de compilación no se eliminaron.

## Segundo intento: APK aprobado, empaquetado de fuentes fallido

Run 38460085827, job 115512685654, commit 112a671854834da4d6e538fda541856e4ae0e3fa. El análisis, las suites Flutter normal/laboratorio, los tests Python, las lecturas reales desde el cliente Dart, la procedencia del bridge reutilizado, el build APK y su inspección/firma/alineación terminaron con éxito. Esto NO acredita instalación o UI Android.

La etapa Package corresponding source with pinned dependencies falló con ModuleNotFoundError: No module named 'tomllib', importado por scripts/dependency_sources.py. La preparación de upstream y cargo fetch --locked habían concluido. El intérprete Python 3.10 del runner no satisface ese requisito: tomllib pertenece a la biblioteca estándar desde Python 3.11. Referencia: https://docs.python.org/3.11/library/tomllib.html.

La subida final estaba después del empaquetado y fue omitida por el fallo. Por eso el APK construido no se presentó como entregado ni se inventó un enlace de descarga. El run conserva estado failure; los éxitos anteriores no lo convierten en un pipeline aprobado.

## Corrección de entorno y conservación de artefactos

Se añade actions/setup-python v6, fijado al commit ece7cb06caefa5fff74198d8649806c4678c61a1, con Python 3.12 y un preflight que importa tomllib ANTES del build. El código móvil y el bridge no cambian en esta corrección. El log de la nueva ejecución debe identificar la versión de parche resuelta.

Se añade un checkpoint del APK y de sus reportes inmediatamente después de su inspección; la entrega final mantiene el requisito de fuentes correspondientes y sus checksums. El checkpoint no es una exención de la distribución de fuentes ni una afirmación de producción. No se desactivan validaciones ni se permite omitir dependencias.

Los resultados de esta nueva revisión deben verificarse por separado. El presente documento no atribuye a una ejecución futura los resultados de los dos intentos anteriores.
