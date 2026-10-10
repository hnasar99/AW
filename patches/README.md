# Parches locales reproducibles

OpenHuman permanece fijado en `036b13e79e4e555ae249f6245966f384d15f35ba`.
TinyInference permanece fijado en `abf90568a24b826d49900150b20856ef166df3f8`.
El manifiesto registra cada parche por SHA-256 y el commit del repositorio propietario.

## Transporte de inferencia

`tinyinference-no-redirect.patch` impide que una respuesta HTTP 3xx cambie
el destino de los prompts o degrade HTTPS. El host que el usuario revisó
sigue siendo el único destino de esa solicitud de inferencia. Los errores
3xx se devuelven a la aplicación; no se siguen automáticamente.

El parche modifica el constructor compartido `OpenAiModel::new`; la ruta
OpenAI compatible de `Provider` usa ese constructor. No es una garantía
sobre otras capacidades de OpenHuman ni sobre servicios no configurados.
Es un parche local: no se afirma que upstream lo haya aceptado.

`tinyinference-response-bound.patch` añade un límite acumulativo de 2 MiB a
los cuerpos del transporte OpenAI compatible antes de la lectura JSON o
del ensamblado SSE. Cubre respuestas normales, errores, listado de modelos
y fallback no streaming, incluso streams sin saltos de línea. Sus pruebas
de frontera y overflow están en un archivo separado. El límite es por
solicitud HTTP; no describe el consumo total de memoria de OpenHuman.

Fuente original:
https://github.com/tinyhumansai/tinyinference/blob/abf90568a24b826d49900150b20856ef166df3f8/crates/tinyinference-llm/src/providers/openai/transport.rs

Ejecutar `python3 scripts/apply_upstream_patches.py` tras recuperar los
submódulos. El comando comprueba el commit y el hash, es idempotente y
rechaza un parche que no se aplique limpiamente. Distribuir estos archivos
junto con el código correspondiente al binario.

## Identidad de TinyBus en el lockfile

`tinyhosts-shared-tinybus.patch` unifica las dos dependencias opcionales de
TinyHosts con el checkout de TinyBus que OpenHuman ya utiliza. Cargo encontraba
dos paquetes de ruta con el mismo nombre y versión y rechazaba `--locked`,
aunque al resolver sin ese flag serializaba los mismos bytes de Cargo.lock.
El parche conserva el grafo efectivo y las versiones: cambia las dos rutas
del manifiesto de TinyHosts, no la implementación de TinyBus.

TinyHosts base: `94098349c8d75269438e8903f9042148b1ab4752`.
TinyBus usado por OpenHuman: `ea92d19a4130a0fb945d837f17034aea9a130c26`.
La copia opcional original de TinyHosts permanece disponible como submódulo;
no se borran su fuente ni sus avisos.

## Portabilidad y actualización en Android

`tinytools-android-executable-access.patch` corrige una incompatibilidad de
TinyTools `bd60b9b52f1998b4483b9cf107a72d3338e672f8`: su comprobación Unix
usaba `AT_EACCESS`, que el backend Android de rustix no expone. En Android
se comprueba primero la igualdad de UID/GID reales y efectivos; si difieren,
se deniega el probe. Cuando coinciden, se utiliza `access` con `EXEC_OK`.
Los demás Unix conservan `accessat` y `EACCESS`. No se habilita una herramienta
de ejecución de comandos en el agente de AW.

`openhuman-android-updater-policy.patch` añade los triples Android reales a
los metadatos del actualizador y rechaza en Android su comprobación y descarga
antes de acceder a HTTP o al sistema de archivos. Su scheduler tampoco se
inicia. La aplicación se actualiza mediante el APK y su identidad de firma;
no descarga ni sustituye un ejecutable de escritorio. Incluye pruebas
específicas de Android, cuya ejecución debe registrarse separadamente.

Ambos cambios se incorporaron durante la compilación Android, después del
smoke de la biblioteca Linux. Los hashes de esa biblioteca host y de cada
binario Android identifican evidencias diferentes. Todos los parches locales
de esta entrega están fechados el 2026-10-10 y conservan sus revisiones base.
