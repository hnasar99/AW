# Historial de validación de redes configurables

2026-10-13: run 38458987279, commit ee4248177ad097a03c6bbe92830cf47aa6389060, FAILED antes de las pruebas y del APK. Flutter analyze detectó un return Future sin await dentro de try en network_controller.dart y tres avisos en el smoke CLI (dos imports relativos de lib y print). No hubo artefactos ni aceptación móvil en ese intento.

La corrección mantiene el analyzer y sus reglas: await explícito, imports package y stdout.writeln para el ejecutable CLI. El workflow usa bash explícito para propagar también fallos de pipes como el smoke con tee. Las aserciones y requisitos de compilación no se eliminaron. Los resultados de la nueva revisión deben verificarse por separado, sin reetiquetar el primer intento como exitoso.
