# Distribución y verificación de fuentes

Este procedimiento entrega la fuente de AW y de sus submódulos OpenHuman en la
revisión usada para la entrega, con los parches locales ya aplicados. Conserva
los archivos fuente nuevos introducidos por los parches aunque todavía no
estén rastreados en el subrepositorio. No necesita que esos commits locales se
hayan publicado en GitHub.

El paquete y su inventario ayudan a comprobar procedencia, integridad y
reconstrucción. No constituyen una certificación de cumplimiento legal completo.
Las secciones 1, 5 y 6 de la [GPLv3 oficial](https://www.gnu.org/licenses/gpl-3.0.en.html)
definen el alcance de las fuentes correspondientes, los cambios y las formas de
entrega. Consulte también [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Qué contiene

- Fuente AW versionada, configuración Android, scripts, pruebas, avisos,
  `Cargo.lock`, `pubspec.lock` y la selección de toolchain.
- Fuente de cada gitlink recursivo de OpenHuman, materializada en su ruta real.
- Parches y su manifiesto. Antes de empaquetar se reconstruyen los archivos
  afectados a partir de los blobs del commit original en un directorio temporal;
  los bytes de trabajo deben coincidir con ese resultado. Los demás archivos
  upstream deben coincidir con sus blobs originales. Se admite únicamente la
  conversión de fin de línea CRLF declarada explícitamente por upstream.
- `SOURCE_MANIFEST.json`: revisión por repositorio, URL sin credenciales,
  parches/SHA-256, lista de archivos, tamaño, tipo, permisos y SHA-256 por archivo.
  Para un enlace simbólico se registra y verifica su destino relativo interno.
- `SOURCE_MANIFEST.sha256`, además del SHA-256 del TAR.GZ entregado por separado.

No se empaquetan `.git`, productos de compilación, cachés de herramientas,
keystores del operador, `.env` de operación ni propiedades locales de SDK/firma.
Los certificados de prueba incluidos en crates publicados y verificados se
conservan como fixtures de esas fuentes. Las exclusiones se registran; los
ejemplos de configuración y los avisos versionados permanecen.
Un filtro por nombre no reemplaza la revisión de secretos del commit que se vaya
a distribuir.

El inventario no es una firma. Compare el SHA-256 del archivo con el valor
publicado junto a la entrega por un canal de confianza. Un atacante que pueda
reemplazar tanto el archivo como todos sus checksums puede reemplazar ambos.

## Crear el paquete desde el checkout

Requisitos del empaquetador: Python 3.11 o posterior y Git. Usa la biblioteca
estándar de Python; no descarga dependencias, no modifica subrepositorios y no
crea commits. Los cambios AW deben estar incluidos en un commit y la raíz debe
estar limpia. Las modificaciones
upstream sólo se aceptan si proceden de `patches/manifest.json`, que puede contener
cualquier número de parches en su orden de aplicación.

Antes del commit final se puede comprobar únicamente upstream:

```bash
python3 scripts/package_corresponding_source.py --check-upstream
```

Después del commit final:

```bash
python3 scripts/package_corresponding_source.py --check
python3 scripts/package_corresponding_source.py \
  --output /ruta/de/entrega/AW-source.tar.gz
```

La salida incluye `AW-source.tar.gz` y `AW-source.tar.gz.sha256`. El TAR usa un
prefijo `AW-source/`, orden estable, uid/gid neutros y fecha del commit AW. Se
rechazan rutas que salgan del paquete, modificaciones inesperadas y archivos
que cambien durante el inventario o la escritura. No se sobrescribe un paquete
existente. Los mismos archivos y metadatos producen una salida estable en el
mismo entorno Python/zlib; eso no afirma que un APK tenga identidad binaria en
cualquier máquina o con otra clave de firma.

## Fuentes externas opcionales

Para añadir las fuentes de paquetes disponibles localmente:

```bash
python3 scripts/package_corresponding_source.py --check \
  --include-dependency-sources
python3 scripts/package_corresponding_source.py \
  --include-dependency-sources \
  --output /ruta/de/entrega/AW-source-with-dependencies.tar.gz
```

El helper `scripts/dependency_sources.py` hace el siguiente inventario:

| Familia | Selección y comprobación | Ruta materializada |
|---|---|---|
| Cargo registry | Nombre, versión y checksum de `Cargo.lock`; checksum del `.crate` cacheado y comparación de cada archivo de caché contra el contenido de ese `.crate` | `dependency-sources/cargo/<nombre>-<versión>/` |
| Dart hosted | Paquetes del lock presentes en `.dart_tool/package_config.json`, nombre/versión/servidor y checksum registrado por Pub; SHA-256 del contenido efectivamente resuelto | `dependency-sources/dart/hosted/<servidor>/` |
| Dart SDK packages | Directorios de paquetes SDK efectivamente resueltos y sus archivos/avisos | `dependency-sources/dart-sdk/` |

El helper genera `.cargo-checksum.json` para las fuentes Cargo incluidas. No
copia `.cargo-ok`, que es estado de caché. Para Pub también copia los archivos
`hosted-hashes` pertinentes; el checksum de descarga registrado no equivale a
volver a verificar los bytes del archivo comprimido original, que normalmente
ya no está en esa caché. El manifiesto distingue expresamente esos niveles de
verificación.

Por defecto se detiene si faltan fuentes de algún paquete del lock. Para una
instantánea parcial deliberada, añada `--allow-missing-dependency-sources`; el
manifiesto enumerará cada paquete faltante y no afirmará cobertura completa.
El lock puede incluir componentes para otros sistemas o funciones no utilizadas
en ARM64. Conserve la evidencia de resolución del destino para distinguir esos
casos de una dependencia usada que falte.

Tras terminar las compilaciones que estén usando Cargo, las descargas se pueden
completar sin actualizar versiones:

```bash
cargo fetch --locked
flutter pub get --enforce-lockfile
```

`cargo fetch --locked --target aarch64-linux-android` limita la descarga al
destino indicado; la comprobación de cobertura del helper sigue comparando con
el lock completo. Véanse la documentación oficial de
[Cargo fetch](https://doc.rust-lang.org/cargo/commands/cargo-fetch.html) y
[Pub get](https://dart.dev/tools/pub/cmd/pub-get).

La opción no materializa las fuentes completas de Gradle/Maven/plugins Android,
Flutter Engine, Dart runtime, JDK, SDK/NDK ni las distribuciones de herramientas.
Los avisos de las fuentes incluidas se conservan. Identificar versiones mediante
locks o descargar artefactos para compilar no demuestra, por sí solo, que estén
entregadas todas las fuentes o los avisos que deban acompañar a un binario. El
inventario de licencias de la distribución final debe cerrar ese alcance.

## Compilar desde la fuente extraída sin `.git`

Instale las versiones de Flutter, Rust, cargo-ndk, JDK y Android SDK/NDK indicadas
en [README.md](../README.md). El proyecto fuente extraído no necesita repositorios
Git en sus directorios, aunque las herramientas instaladas pueden usar Git para
su propio funcionamiento. No confunda esa condición con una compilación sin red.

En el directorio que contiene el TAR.GZ y su checksum:

```bash
sha256sum -c AW-source.tar.gz.sha256
tar -xzf AW-source.tar.gz
cd AW-source
python3 scripts/package_corresponding_source.py --verify .
bash scripts/prepare_upstream.sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
bash scripts/build_android_rust.sh arm64-v8a
flutter build apk --release --flavor qa --target-platform android-arm64
```

`prepare_upstream.sh` reconoce una fuente extraída sólo cuando la raíz carece de
`.git` y tiene el manifiesto. Verifica todos sus archivos y el conjunto exacto
de archivos upstream. Los parches ya están aplicados: no invoca `git submodule`
ni intenta aplicarlos de nuevo. Si existe `.git`, conserva la ruta de checkout,
la revisión fijada y los checksums de parches; un fallo de Git nunca se convierte
en una autorización para omitir ese control.

El manifiesto detecta modificaciones a la instantánea entregada. Una edición
posterior intencional es una nueva versión; no se debe presentar como una
reproducción intacta de la entrega original.

Si se incluyeron las fuentes Cargo, una configuración explícita de directorio
puede reutilizarlas. Cree `.cargo/config.toml` en la raíz extraída con:

```toml
[source.crates-io]
replace-with = "aw-packaged-source"

[source.aw-packaged-source]
directory = "dependency-sources/cargo"
```

Los paquetes hospedados por Pub se pueden reutilizar con:

```bash
PUB_CACHE="$PWD/dependency-sources/dart" flutter pub get --offline --enforce-lockfile
```

La instalación Flutter debe seguir aportando sus paquetes SDK compatibles. Las
fuentes `dart-sdk/` son una copia para inspección/distribución, no una instalación
completa del SDK. Gradle y las herramientas Android aún pueden necesitar red.
El helper de PowerShell conserva su flujo de checkout; para este procedimiento
del paquete extraído utilice Bash en Linux/macOS o un entorno WSL configurado.

La variante `qa` usa su identidad de aplicación y firma de pruebas. Una clave de
firma privada no forma parte del paquete. Reconstruir el mismo código con una
firma distinta no reproduce el hash del APK ni garantiza su actualización sobre
una instalación firmada por otra clave. La firma del operador, la validación en
dispositivo y los resultados E2E se documentan en el expediente de entrega.
