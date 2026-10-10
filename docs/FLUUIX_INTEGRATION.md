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

La wallet, la experiencia con misiones y el agente deben consumir el mismo contrato de dominio para una propuesta. La integración privada no debe saltarse la revisión determinista ni la firma de la wallet externa.

## Evidencia de aceptación

1. Descubrimiento autenticado del catálogo en el entorno acordado.
2. Llamada exitosa de una herramienta permitida con una cuenta de prueba.
3. Rechazo de herramienta, tenant o scope no permitido.
4. Expiración/revocación de credenciales y comportamiento de reautenticación.
5. Timeout, respuesta excesiva, redirección y error de servicio visibles sin secretos.
6. Comprobación de que solo se comparte con el modelo el contexto autorizado.
7. Prueba de extremo a extremo desde el APK, con versión, endpoint, resultados y fecha.

Hasta disponer de esos datos, agregar una URL supuesta, fingir un catálogo o devolver respuestas simuladas como si fueran del servicio reduciría la fiabilidad de la entrega.
