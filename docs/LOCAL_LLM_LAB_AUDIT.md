# AW · auditoría del circuito de inferencia local

## Estado y alcance

Esta iteración continúa AW sobre el commit `f5567e7819cf6c486a2cba9ae6d448ddada054fe`, sin cambiar la aplicación de referencia, las licencias, la separación móvil/backend ni la integración Circle/Arc. El primer criterio de aceptación es una consulta originada en la interfaz Android, procesada por un modelo del laboratorio y mostrada de vuelta con evidencia correlacionada. **Ese recorrido sigue BLOCKED por falta de acceso al Android y al servidor del operador.**

La auditoría usa el requerimiento aportado en esta conversación, el código recuperado del repositorio y los registros anteriores disponibles. La recuperación de contexto de otras conversaciones devolvió que estaba deshabilitada; no se atribuyen decisiones a historiales no accesibles. No se publica aquí una transcripción de conversaciones ni credenciales.

## 1. Identidad recuperada y contraste con la entrega anterior

El [PR anterior #1](https://github.com/hnasar99/AW/pull/1) fue fusionado por el mantenedor el 10 de octubre de 2026 a las 20:20:22 UTC. El main consultado el 12 de octubre apunta al [merge f5567e7](https://github.com/hnasar99/AW/commit/f5567e7819cf6c486a2cba9ae6d448ddada054fe). Su [ejecución de CI 38083359015](https://github.com/hnasar99/AW/actions/runs/38083359015) terminó en success. Los registros anteriores que describen el PR abierto corresponden a un corte anterior a esa fusión.

La rama de esta iteración es `work/local-llm-lab-20261012`. Se comprobó un árbol de aplicación limpio antes de editar. Los submódulos se recuperaron en sus pins y se aplicaron los cinco parches registrados en [el manifiesto existente](../patches/manifest.json). Las modificaciones preparadas dentro de submódulos corresponden a esos parches; no son una actualización de sus gitlinks.

El expediente anterior recuperado conservó su SHA-256 `eb3e11eaced6c912811124b35f13cc37d8735f33ce01ef54f7fa71aad5ed21c1` y pasó la comprobación CRC de sus 419 miembros. Ese control verifica integridad del archivo recuperado, no vuelve a ejecutar sus ensayos. El [estado anterior de entrega](DELIVERY_STATUS.md) conserva su fecha de corte y no debe leerse como estado de esta rama.

## 2. Recorrido existente y comprobación de los antecedentes

Todas las referencias de esta tabla se inspeccionaron en el baseline `f5567e7819cf6c486a2cba9ae6d448ddada054fe`.

| Antecedente | Archivo y símbolo | Conclusión |
|---|---|---|
| Inicialización configurable | [lib/main.dart](https://github.com/hnasar99/AW/blob/f5567e7819cf6c486a2cba9ae6d448ddada054fe/lib/main.dart), `_startAgent`; [lib/openhuman_bridge.dart](https://github.com/hnasar99/AW/blob/f5567e7819cf6c486a2cba9ae6d448ddada054fe/lib/openhuman_bridge.dart), `OpenHumanBridge.initialize` | EXISTENTE Y VERIFICADO: endpoint, API key, modelo y cache se envían a la ABI fuera del isolate de UI. |
| Turno desde Dart | [bridge Dart](https://github.com/hnasar99/AW/blob/f5567e7819cf6c486a2cba9ae6d448ddada054fe/lib/openhuman_bridge.dart), `sendTurn` y `_turnSync`; [lib.rs](https://github.com/hnasar99/AW/blob/f5567e7819cf6c486a2cba9ae6d448ddada054fe/rust/arc_openhuman_bridge/src/lib.rs), `arc_openhuman_turn` | EXISTENTE Y VERIFICADO en fuente. No acredita interacción Android. |
| Runtime y proveedor | [agent.rs](https://github.com/hnasar99/AW/blob/f5567e7819cf6c486a2cba9ae6d448ddada054fe/rust/arc_openhuman_bridge/src/agent.rs), `initialize`, `turn`, `run_turn` | OpenHuman embed real, workspace Stateless, sesión en memoria y `Provider::openai_compatible(...).model(...)`. El deadline del turno es 120 s. |
| Herramientas Arc | [rpc.rs](https://github.com/hnasar99/AW/blob/f5567e7819cf6c486a2cba9ae6d448ddada054fe/rust/arc_openhuman_bridge/src/rpc.rs), `tools`; `ToolFactory::build` en agent.rs | El baseline registra `arc_network_status` y `arc_balance` siempre. Es necesario un registro vacío para la etapa 1. |
| Transporte autorizado | [validation.rs](https://github.com/hnasar99/AW/blob/f5567e7819cf6c486a2cba9ae6d448ddada054fe/rust/arc_openhuman_bridge/src/validation.rs), `endpoint_url` | HTTPS para destinos remotos; HTTP sólo en loopback validado. Rechaza credenciales embebidas, query, fragmento y una ruta terminada en `/chat/completions`. |
| Evidencia histórica | [DELIVERY_STATUS.md](DELIVERY_STATUS.md) y expediente recuperado | REPORTADO SIN REVERIFICAR: fixtures de inferencia en host y C ABI en Android shell. El intento de instalación UI terminó con fallo del sistema Android; no hay prueba previa UI → modelo real. |
| Monad | Búsqueda de la referencia en la aplicación y documentación baseline revisadas | No se encontró integración ni dependencia implementada para este circuito. Un título de chat no permite inferir red, contrato, activo o decisión arquitectónica. |

### Ruta efectiva del proveedor fijado

OpenHuman permanece en `036b13e79e4e555ae249f6245966f384d15f35ba`; TinyInference, en `abf90568a24b826d49900150b20856ef166df3f8`. En OpenHuman, `crates/openhuman-core/src/inference/host_runtime/ops/agent_chat.rs` aplica el modelo explícito antes de `EphemeralRoute::apply`. La ruta efímera fija el slug `ephemeral-route` y los roles al endpoint, credencial y modelo suministrados. `crates/openhuman-core/src/inference/provider/factory/cloud_slug.rs` usa el ID literal y construye Chat Completions. TinyInference añade `/chat/completions` a la raíz, por lo que el ensayo usa `/v1`, no `/api` ni la ruta completa de completions.

Se comprobó una consulta potencial de metadatos en `crates/openhuman-core/src/inference/context_window.rs`: puede hacer descubrimiento de `/models` antes del POST. El override explícito de `model_registry` devuelve el presupuesto del host antes de esa consulta. La rama lab fija **4096 tokens** para el ID exacto. Esto evita el descubrimiento; no detecta la capacidad ni el contexto efectivo del servidor. La aceptación debe verificar esos valores en el proceso elegido.

El manifiesto bloqueado resuelve reqwest 0.12.28. La ruta Android de inferencia utiliza rustls y raíces WebPKI; configurar una CA o una política de cleartext de Android no configura automáticamente este cliente Rust. La topología inicial propuesta une loopbacks por USB y no altera la verificación TLS. Las pruebas de conexiones reales y certificados siguen pendientes. Véanse [reqwest 0.12.28](https://docs.rs/crate/reqwest/0.12.28/source/Cargo.toml), [Android Network Security Configuration](https://developer.android.com/privacy-and-security/security-config) y el grafo de features registrado en la verificación de esta rama.

## 3. Cambio implementado y límites de su garantía

La misma AW se compila con `AW_LAB_TEXT_ONLY=true`. El modo normal sigue siendo el valor predeterminado. El modo lab tiene sus propios ajustes, endpoint y modelo explícitos, y no inicializa la wallet ni transforma salidas del modelo en formularios de pago. La política es una constante de build, no un comando que el modelo pueda modificar.

La ABI 1 añade `arc_openhuman_init_lab` y `arc_openhuman_turn_lab`; conserva las seis funciones anteriores. Dart valida el endpoint de entrada y comprueba capacidad, modo, clase de inferencia declarada y listas vacías de herramientas/lecturas. El estado nativo no devuelve el endpoint efectivo como evidencia; éste debe comprobarse en el tráfico del ensayo. No degrada silenciosamente a las entradas anteriores si falta una función lab. El inspector de los nuevos APK exige los ocho exports.

En Rust, el lab no construye `ArcRpc`, instala `HostOnly` con un conjunto vacío y limita los dominios al núcleo necesario, agente e inferencia. Desactiva servicios, hooks y exportadores de observabilidad. El runtime se crea desde configuración del host, sin cargar una configuración de operador heredada. Rechaza credenciales backend, transporte hosted instalado y proxies de entorno no vacíos; no imprime ni borra sus valores. El modo queda fijado durante la vida del proceso, incluso después de reset, porque upstream conserva infraestructura global.

La validación lab admite una IP loopback literal y la raíz exacta `/v1`; rechaza nombres DNS, destinos remotos y sintaxis de selección de modelo con `hint:`, `@` o `cloud`. Estas restricciones impiden seleccionar una ruta cloud desde AW. **Un servicio loopback todavía podría actuar como proxy o ejecutar un modelo remoto:** se exige verificar el servidor y deshabilitar su capacidad cloud. Ninguna etiqueta de la UI sustituye esa comprobación.

Cada turno lab lleva `awlab-` y 32 dígitos hexadecimales aleatorios generados por Dart. La ABI valida ese formato, añade un marcador al prompt y devuelve ID y duración nativa. No añade un header HTTP personalizado. La observación del servidor debe asociar el procesamiento con ese ID; el eco del modelo y una coincidencia temporal no son evidencia suficiente por sí solos.

## 4. Controles y aceptación pendiente

Los cambios se relacionan con controles concretos de [OWASP LLM01: Prompt Injection](https://genai.owasp.org/llmrisk/llm01-prompt-injection/), [LLM02: Sensitive Information Disclosure](https://genai.owasp.org/llmrisk/llm022025-sensitive-information-disclosure/) y [LLM06: Excessive Agency](https://genai.owasp.org/llmrisk/llm062025-excessive-agency/): el contenido del modelo no modifica endpoints/política ni alcanza herramientas financieras; se mantienen límites y redacción de credenciales. Eso no certifica cumplimiento integral ni reemplaza pruebas adversariales de un futuro sistema con herramientas.

La guía [LOCAL_LLM_LAB.md](LOCAL_LLM_LAB.md) contiene el inventario, arranque, conexión, aceptación, detención y rollback. La [matriz](LOCAL_LLM_LAB_TEST_MATRIX.md) es la referencia de resultados; distingue pruebas sintéticas, código leído, APK compilado y ejecución real. Las etapas 2 y 3, las estrategias de inversión y los pagos permanecen fuera del ensayo de texto.
