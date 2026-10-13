# Fluuix Chain Access — cierre de verificación pública

Corte de ejecución: 13 de octubre de 2026, 19:20:56 UTC. Este archivo resume los logs leídos mediante el conector GitHub; no sustituye el log original ni declara aceptación móvil.

## Resultado

**Backend de lectura desplegado y probado mediante HTTP público. Integración con AW Android pendiente.** Fluuix es el principal. ZonaFranca queda como respaldo previsto, sin configurar y sin conmutación automática. No existe MCP ni hace falta para este corte HTTP. No se habilitaron simulaciones, firma, custodia ni publicación de transacciones.

## Identidad y procedencia

- Repositorio: hnasar99/AW.
- Rama: `deploy/fluuix-chain-access-20261013`.
- Commit del código probado: `d992aed8e6e6bc3481188de0ef7b8378fdcaa880`.
- Árbol fuente: `3b16d5725e4c632bc4ef41662c90538da2565d84`.
- Base preservada: `7768c172c38f674c8903f2e35a192167b9b4ee78`, rama de tesorería. No se alteró main ni código móvil.
- Fuente modular, pruebas y generador: `services/chain-access/`. El bundle de Railway se genera mediante `scripts/bundle.mjs`; no requiere paquetes npm externos.
- Railway: proyecto `b027e95f-1339-41aa-acb9-def36dd45a4e`; entorno testnet `e77581de-dbd0-402c-bb1b-7b36275fc3f8`; servicio `ddf7215c-9565-4632-9b06-fc9d82cc8c01`.
- Deployment observado: `4ba790b7-b71a-4504-9419-de4bd3dcbfaf`, SUCCESS; runtime Bun 1.4.0. Readback del servicio: codeSource=deployed, sin cambios staged. Arranque registrado en 0.0.0.0:8080.
- Dominio público: https://fluuix-chain-access-testnet.up.railway.app

## CI y fuentes primarias

Run: https://github.com/hnasar99/AW/actions/runs/38454079571

Job: https://github.com/hnasar99/AW/actions/runs/38454079571/job/115492155730

El run del commit de código terminó completed/success. El job verificó checkout, Node 22.16.0, generación del bundle, pruebas sintéticas y smoke HTTP real. Las 43 pruebas automatizadas pasaron, sin fallos ni omitidas; duración de la suite en ese runner: 211.857632 ms. Es la misma suite previamente probada localmente: no se suman las repeticiones como casos adicionales.

Las pruebas automatizadas usan upstream sintético. El smoke siguiente utiliza el despliegue público y RPC reales, sin fixture. Sus resultados se distinguen expresamente.

## Diez comprobaciones HTTP reales

Ventana: 19:20:49.709–19:20:50.936 UTC. Son mediciones puntuales desde el runner de GitHub, no SLA, carga sostenida ni latencia móvil.

| Comprobación | HTTP | Resultado | Duración ms |
|---|---:|---|---:|
| /healthz: proceso vivo | 200 | PASS | 184 |
| /v1/capabilities: alcance y límites | 200 | PASS | 108 |
| /: HTML de consola técnica | 200 | PASS | 87 |
| /readyz: ambas redes verificadas | 200 | PASS | 228 |
| Arc Testnet: eth_chainId | 200 | PASS | 135 |
| Arc Testnet: saldo público de prueba | 200 | PASS | 293 |
| Monad Testnet: eth_chainId | 200 | PASS | 89 |
| Monad Testnet: saldo público de prueba | 200 | PASS | 117 |
| eth_sendRawTransaction denegado | 403 | PASS | 98 |
| URL arbitraria adicional denegada | 400 | PASS | 72 |

Resultado del smoke: total=10, pass=10, failed=0.

La lectura /readyz observó Arc chain ID 5042002, bloque 67037433, y Monad chain ID 10143, bloque 70762957. La consulta posterior de saldo Monad utilizó el bloque 70762959. Ambos saldos consultaron la dirección pública cero; no son saldos del usuario ni demuestran control de una wallet.

La prueba de rechazo de publicación envió el nombre del método con params vacíos, sin transacción firmada; verificó su prohibición explícita con código -32601. La prueba de URL arbitraria recibió -32600. No se movieron fondos. Los límites de cuerpo, timeout, concurrencia, cuota y otros métodos prohibidos se probaron con fixtures, no mediante pruebas de carga públicas.

Correlación de readiness: `aca3ea90-451d-463d-89fb-771a12c165dc`. Rechazo de publicación: `fe73d506-82ca-4997-9ad8-9bd704605765`. Rechazo de URL adicional: `7b488300-25d5-4b94-b6ee-3280c9c96b8b`.

## Alcance y límites

- La consola es diagnóstico de la API, NO una sustitución de AW ni un cliente móvil entregado. Se verificó la descarga del HTML y sintaxis del JavaScript, no interacción visual E2E en un navegador.
- Los clientes Dart/Rust existentes de AW no se han conectado a este servicio. La API declara mobile_integration=pending.
- No hay autenticación empresarial, tenants, datos de clientes ni límites financieros centrales. Sólo datos públicos de testnet, con presupuestos por proceso; no equivalen a cuotas distribuidas ni defensa completa ante DoS.
- El backup ZonaFranca no está activo. No hay failover automático ni endpoints privados inventados.
- El MCP, el modelo real desde Android, la distribución del APK y el flujo de firma/pago siguen fuera de esta aceptación.
- El defecto de restauración del ledger de tesorería NO quedó corregido por este cambio backend. Los objetos Git preliminares no se presentan como modificaciones integradas al APK.
- Las observaciones RPC confían en los proveedores seleccionados; no son verificación criptográfica independiente del consenso ni prueba de disponibilidad futura.
- El navegador de investigación no pudo abrir este dominio y el entorno local previo tuvo fallos DNS. La verificación externa se resolvió mediante el runner de GitHub, sin relajar controles TLS o de red.
- El log contiene una advertencia no bloqueante sobre el runtime interno de actions/setup-node v4. No provocó fallo; la suite corrió con Node 22.16.0. Actualizar ese action de forma revisada es mantenimiento separado, no una condición que invalide el smoke.

## Siguiente cambio mínimo sobre AW

1. Añadir un adaptador HTTP de lectura al dominio existente, con registro fijo de destinos, esquema estricto y cantidades enteras. Mostrar origen, red, bloque y fallo real; nunca transformar error en saldo cero. No sustituir ciegamente el RPC de pagos, que necesita simulaciones deshabilitadas en este piloto.
2. Conectar las herramientas de lectura del runtime mediante una capacidad explícita, conservando `AW_LAB_TEXT_ONLY` sin red blockchain y sin herramientas financieras. Un fallo de Fluuix debe mostrarse, no activar un backup o RPC directo silencioso.
3. Corregir el ledger corrupto con fallo cerrado y pruebas; conservar el control de operaciones inciertas. No confundir ese arreglo local con política empresarial distribuida.
4. Compilar y aceptar el recorrido AW UI → runtime → Fluuix → RPC → UI en el dispositivo, con versión y evidencia. Mantener separados laboratorio de inferencia, lectura de chains y permisos de escritura.

No hace falta crear otro repositorio, rehacer Flutter, obtener el backend privado completo o implementar MCP antes de ese cambio. La documentación contractual utilizable está en `services/chain-access/README.md` y el esquema de capacidades está servido por `/v1/capabilities`.

Este documento posterior registra resultados del commit de código identificado; no altera ni vuelve a atribuir las pruebas a código diferente.
