# Contrato de incorporación · Fluuix / ZonaFranca

## Estado real

No se proporcionaron un endpoint, catálogo de herramientas, esquema de autenticación ni credenciales verificables de Fluuix/ZonaFranca. Por eso esta entrega **no anuncia una conexión privada activa**. Las únicas herramientas del agente son `arc_network_status` y `arc_balance`, implementadas por el host Rust.

OpenHuman usa `ToolScopeSpec::HostOnly`. Ese alcance no hereda servidores MCP definidos en configuración. Activar una feature llamada MCP tampoco registra herramientas por sí mismo. Una futura integración debe crear un adaptador explícito y acotado por herramienta.

## Información necesaria del operador del servicio

| Dato | Finalidad |
|---|---|
| URL base y entorno | Establecer destino exacto y separar pruebas de producción |
| Transporte | API HTTP o MCP HTTP soportado, rutas y versión de protocolo |
| Autenticación | OAuth/PKCE, token delegado u otro mecanismo documentado; audience/scopes y expiración |
| Catálogo real | Nombre, descripción, JSON Schema de entrada/salida y clasificación lectura/escritura |
| Identidad/tenant | Relacionar la cuenta de la app con el recurso permitido |
| Semántica de errores | Autenticación, permisos, límite de tasa, timeout, reintentos y duplicados |
| Política de datos | Qué campos puede recibir el modelo y qué registros conserva el servicio |
| Cuenta y datos de prueba | Permitir una aceptación sin afectar recursos de producción |

No pegue secretos en un prompt ni los codifique dentro del APK. Una aplicación móvil no puede conservar de manera confidencial un client secret compartido por todos sus usuarios. La autenticación concreta debe seguir el contrato del proveedor y su modelo de amenazas.

## Adaptador previsto

Cada herramienta aceptada tendrá un nombre estable en el host Rust, validación de entrada, destino allowlisted, tiempo y tamaño de respuesta limitados, credenciales obtenidas por el canal de sesión y salida reducida a los campos necesarios. Los secretos no forman parte de los argumentos que ve el modelo. La respuesta se trata como datos de un servicio, no como instrucciones de sistema.

El primer conjunto debe limitarse a lecturas cuyo contrato se pueda verificar. Una operación con efectos requiere autorización explícita independiente, idempotencia y conciliación ante un resultado incierto. No se expone un método genérico que permita al modelo elegir cualquier URL, scope o llamada MCP.

La wallet, la caja, las órdenes del día y el agente deben consumir el mismo contrato de dominio para una propuesta. La integración privada no debe saltarse la revisión determinista ni la firma de la wallet externa.

## Superficie de la app

El modo normal se presenta como FluuiX, con cuatro destinos:

| Destino | Qué muestra | Qué no hace |
|---|---|---|
| Caja | Saldo USDC de Arc Testnet, riel local y reserva separados, tope local, pago con la revisión ya existente | No suma rieles. No ejecuta CCTP, Gateway ni cirBTC |
| Agente | Chips `arc_network_status` y `arc_balance`. Distingue texto del modelo y lectura ejecutada | No firma ni autoriza |
| Red | ZonaBank, lending, ZonaFranca, TTN y los vehículos de capital, todos en estado sin contrato | No muestra saldos, tasas ni préstamos de demostración |
| Ajustes | Project ID de Reown y proveedor de inferencia | No pide frase semilla ni clave privada |

El modo `AW_LAB_TEXT_ONLY` no construye Caja ni Red. Conserva Agente y Ajustes, sin wallet, sin Arc y sin herramientas. Esa rama es el [PR #2](https://github.com/hnasar99/AW/pull/2). La UI de FluuiX se apila encima y no cambia el ABI de laboratorio.

El tope por pago (1000 USDC) y por día (5000 USDC) es política de esta app, contada con recibos confirmados guardados en el teléfono. No es un Agent Wallet de Circle. Si el importe la supera, `prepare` no se llama.

## Frontera Circle y LATAM

Circle no ofrece en este conjunto una stablecoin de peso argentino, real o peso mexicano para el teléfono.

- La caja es USDC en Arc Testnet. EURC existe en esa red como activo distinto y no entra en el hero.
- BRL/USDC por PIX y MXN/USDC por SPEI son corredores de Circle Mint para cuentas institucionales. El acceso institucional a USDC en Argentina publicado con BIND/BEN tampoco es un SDK de esta app. Esos rieles quedan en el back-office del operador.
- El riel local de la marca es Twin/ARGt, detrás de ZonaBank, cuando exista el contrato que pide la sección de información del operador. Hasta entonces la caja lo muestra como sin contrato y no lo suma.
- xReserve sirve para que un equipo de cadena emita un token respaldado por USDC. No tokeniza la empresa. Eso sigue siendo TTN.
- CCTP mueve el mismo USDC entre cadenas. En CCTP V2, Arc está solo en testnet, dominio 26. Gateway ofrece un saldo USDC unificado y también incluye Arc solo en testnet. Ninguno está ejecutable en esta versión. La app no arma el pasaje.
- Smart Contract Platform cubre plantillas ERC-20, ERC-721, ERC-1155 y airdrop. No cubre el security token con compliance que publica ZonaFranca. Esta app no despliega tokens.
- Una wallet developer-controlled de Circle implicaría custodia de la app. La firma sigue en la wallet externa.

## Mapa de la Red

La pantalla Red lista los módulos en estado **sin contrato**. El enlace abre la descripción pública. No es un endpoint, no autentica y no trae saldos. Las cifras de las páginas de marketing (volúmenes, campañas, tasas de éxito) no se copian a la app.

| Módulo | Página pública | Qué falta para registrarlo |
|---|---|---|
| ZonaBank | `https://fluuix.com/zonabank` | URL de API, auth, esquema de cuentas, contactos, intents y riel |
| Lending | `https://fluuix.com/ecosystem` | No hay portal público de préstamos. El dashboard `/dashboard/lending-protocols` no es un contrato y no se enlaza. Faltan catálogo, colateral y política de datos |
| ZonaFranca | `https://fluuix.com/zf` | Catálogo de activos y trazabilidad, con tenant |
| TTN | `https://fluuix.com/ttn` | Instrumentos ya emitidos. Emitir un token no es una orden del teléfono |
| Fideicomisos | `https://fluuix.com/fideicomiso` | Posiciones, cuando el motor publique catálogo |
| Fondos | `https://fluuix.com/fondos` | Posiciones, cuando el motor publique catálogo |
| Crowd | `https://fluuix.com/financiamiento` | Campañas reales del tenant. La página pública no es la cartera de la empresa |
| Licitaciones | `https://fluuix.com/licitaciones` | Procesos del tenant |
| Donaciones | `https://fluuix.com/donaciones` | Campañas del tenant |
| Academia | `https://fluuix.com/academia` | No mueve fondos y no tiene herramienta de host |

## Mapa de herramientas del host

Mismo patrón que Arc: nombre estable, entrada validada, destino allowlisted, secreto fuera de los argumentos del modelo. Lectura primero. Escritura igual a propuesta revisada en la UI. No hay una herramienta genérica de URL o de MCP.

Ya registradas en el host Rust:

| Herramienta | Dato |
|---|---|
| `arc_network_status` | Estado de Arc Testnet |
| `arc_balance` | Saldo USDC de la caja |

Lecturas que el host puede sostener con RPC y contratos públicos, y que este corte no registra:

| Herramienta | Dato |
|---|---|
| lectura EURC en Arc | Saldo separado del hero |
| estado CCTP | Dominio 26 en testnet, burn y atestación, sin firma del agente |
| saldo Gateway | Lectura en las cadenas de testnet soportadas, sin mezclarlo con la caja |

Herramientas que esperan el contrato del operador. No se registran antes de esa evidencia:

| Módulo | Lectura prevista | Escritura |
|---|---|---|
| ZonaBank | Cuentas, contactos, intents, estado de riel | Un intent de pago local también pasa por revisión |
| Lending | Facilidades y colateral declarado | Originar un préstamo no entra en este corte |
| ZonaFranca | Activos y trazabilidad de la empresa | No hay alta de activo desde el agente |
| TTN | Instrumentos ya emitidos | Emitir un token no es una orden del teléfono |
| Fideicomisos, fondos, crowd, licitaciones, donaciones | Posiciones cuando el motor publique catálogo | No hay suscripción desde el agente |

Los skills de Circle documentan qué puede implementar el host. No se montan como MCP arbitrario dentro del APK. Si el operador ofrece un MCP de FluuiX, se adapta herramienta por herramienta. OpenHuman no lo hereda por configuración.

## Evidencia que el operador todavía no entregó

Sigue faltando, para cada módulo de la Red y para cualquier lectura nueva:

- URL base del servicio y entorno, distinta de la página pública de la tabla anterior.
- Transporte, versión y catálogo con JSON Schema de entrada y salida.
- Autenticación delegada, audience, scopes y expiración. Sin client secret dentro del APK.
- Tenant que ate la wallet de la empresa al recurso permitido.
- Semántica de error, límite de tasa, timeout e idempotencia.
- Política de datos: qué puede ver el modelo y qué conserva el servicio.
- Cuenta de prueba que no toque producción.

Hasta esa evidencia, la Red permanece en sin contrato. Una página de `fluuix.com` no sustituye el catálogo.

## Evidencia de aceptación

1. Descubrimiento autenticado del catálogo en el entorno acordado.
2. Llamada exitosa de una herramienta permitida con una cuenta de prueba.
3. Rechazo de herramienta, tenant o scope no permitido.
4. Expiración/revocación de credenciales y comportamiento de reautenticación.
5. Timeout, respuesta excesiva, redirección y error de servicio visibles sin secretos.
6. Comprobación de que solo se comparte con el modelo el contexto autorizado.
7. Prueba de extremo a extremo desde el APK, con versión, endpoint, resultados y fecha.

Hasta disponer de esos datos, agregar una URL supuesta, fingir un catálogo o devolver respuestas simuladas como si fueran del servicio reduciría la fiabilidad de la entrega.
