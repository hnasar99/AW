# Operación y aceptación · AW 0.2.0

Este procedimiento se aplica a Android y Arc Testnet. Su ejecución genera evidencia; la existencia de este documento no significa que todos los pasos se hayan completado. Consulte `DELIVERY_STATUS.md` y el informe de la entrega.

## Preparación

Registre versión del APK, SHA-256, certificado, modelo del teléfono, versión de Android, ABI, tamaño de página (`adb shell getconf PAGE_SIZE`) y versión de la wallet externa. Use únicamente USDC de Testnet y una cuenta de prueba. Obtenga un Project ID válido de Reown y confirme que sus restricciones permiten el cliente que va a utilizar.

Para inferencia, elija un proveedor y modelo habilitados en su cuenta. Configure una API key limitada para esa prueba. Las consultas y los resultados de herramientas que necesita el modelo salen del teléfono hacia el endpoint revisado. El runtime agéntico y su bridge permanecen en el proceso de la aplicación.

## Secuencia de aceptación

| Paso | Acción | Evidencia que permite aprobarlo |
|---|---|---|
| 1. Instalación | Instalar el APK y abrir la app | Versión/paquete correctos, sin crash, UI legible |
| 2. Biblioteca nativa | Pulsar «Verificar ejecución nativa de Rust» | ABI 1, sistema Android, arquitectura esperada y commit upstream real |
| 3. Inicialización | Configurar proveedor, iniciar agente | `initialized=true`; errores visibles si falla; no confundirlo con inferencia |
| 4. Inferencia | Pedir una respuesta breve | Respuesta real del proveedor; registrar ID solicitado sin atribuir pesos no atestados |
| 5. Herramientas | Solicitar estado de Arc y saldo de la cuenta | Herramientas ejecutadas registradas, chain 5042002, bloque y resultado RPC observados |
| 6. Sesión wallet | Aprobar una conexión | Cuenta, chain y permisos recibidos de la wallet; no solo URI abierta |
| 7. Simulación | Preparar un envío pequeño | Saldo, estimación y simulación RPC; revisión con importe y comisión máxima |
| 8. Rechazo | Rechazar la petición en la wallet | Sin confirmación inventada; estado explica el rechazo o incertidumbre |
| 9. Envío real | Revisar y firmar una transferencia de prueba | Hash, transacción coincidente, recibo con status=1, bloque y explorador |
| 10. Fallo/espera | Cortar red mientras espera el recibo | Pendiente o incierto, hash conservado y sin reenvío automático |
| 11. Recuperación | Cerrar/reabrir la app tras solicitar firma | Intención persistida; un hash ajeno no libera el bloqueo ni confirma el envío |
| 12. Cambios de sesión | Cambiar cuenta/red o revocar sesión | La revisión previa queda inválida; exige nueva preparación |
| 12a. Regreso por callback | Abrir `awallet://callback` con la app activa y cerrada | La app se abre o reanuda sin crear otra pantalla inicial ni perder la intención pendiente; el URI por sí solo no confirma la firma |
| 13. Cancelación | Interrumpir un turno de inferencia | El trabajo se cancela, se exige reinicio antes del siguiente turno |
| 14. Credenciales | Cambiar endpoint y olvidar key | La key no reaparece en un host distinto; la UI informa cualquier fallo de borrado |
| 15. Misiones | Cambiar entre vista normal y misiones | Mismo estado y controles; completar una misión exige el evento real correspondiente |

Si el resultado de un envío no se conoce, compruebe primero la actividad de la wallet. Pegue el hash correspondiente cuando exista. La opción para declarar cancelada una solicitud requiere haber comprobado que no fue enviada; no es un detector autónomo de la cadena. No vuelva a firmar a ciegas.

## Recolección de evidencia

Guarde comandos, versiones, marcas UTC, resultados y fallos. Para transacciones, guarde chain, cuenta emisora, destinatario, importe en unidades enteras, hash, bloque y recibo. No guarde claves, frases semilla, URI de emparejamiento activa ni cuerpos de conversación privada en un informe público.

Una prueba con servidor HTTP local de respuestas sintéticas debe llamarse **fixture de inferencia**. Puede demostrar que OpenHuman se inicializa, llama al transporte, registra herramientas y devuelve el resultado por FFI. No demuestra conectividad con un proveedor comercial, calidad del modelo, ejecución Android ni una transferencia real.

La inspección ELF/ZIP, los tests unitarios y el análisis estático son capas distintas. Ni un ABI `status` satisfactorio ni la presencia del nombre OpenHuman en una cadena del binario prueban que un turno real haya terminado.

## Límites operativos implementados

- Turno: timeout total de 120 s; RPC de herramientas: 20 s.
- Concurrencia: un trabajo nativo a la vez. Un error o cancelación del turno exige reset.
- Sesión: máximo de 32 turnos antes de reiniciar su historial en memoria.
- Salida final del bridge: 32 KiB; progreso acumulado: 128 KiB.
- Transporte OpenAI compatible: máximo acumulado de 2 MiB por respuesta HTTP antes del ensamblado JSON/SSE; no sigue redirecciones.
- Upstream permite hasta cinco intentos por llamada de modelo, con pausas de 3/6/12/24 s y jitter. El timeout total del turno sigue siendo 120 s; rechazar una respuesta o redirección puede tardar varias decenas de segundos por esos reintentos.
- Propuestas: red y token permitidos, aprobación explícita, campos tipados y monto positivo; no habilitan firma desde el agente.
- Revisión de transferencia: expira después de 2 minutos y se invalida al cambiar la sesión.

Estos límites no representan un presupuesto total de memoria, batería, latencia o coste del servicio. Mida esos consumos en el teléfono y proveedor objetivos.

## Distribución y soporte

El APK de QA tiene `applicationId=io.fluuix.aw.qa`. Una nueva compilación con otra clave de prueba puede requerir desinstalar la anterior; eso borra su estado local. Una distribución estable necesita custodia de la misma identidad de firma o un mecanismo de rotación compatible. No se debe convertir una clave temporal de esta sesión en la clave permanente del producto.

La variante `production` exige firma del operador. También sigue apuntando a Arc Testnet. Para habilitar un producto fuera de este alcance se requiere una decisión específica, endpoints reales, criterios operativos y evidencia nueva.

Mantenga junto al APK sus fuentes correspondientes, parches, locks, instrucciones y avisos. El fallo de publicación en GitHub debe registrarse como tal: un commit local o un archivo bundle no implica que `main` remoto ya esté actualizado.

## Criterio de salida

La entrega puede pasar a una prueba controlada cuando su APK, firma, contenido nativo y comportamiento local estén verificados y se conozcan sus dependencias. La aprobación de uso final requiere completar la secuencia E2E en el dispositivo, proveedor y wallet elegidos y cerrar Fluuix/ZonaFranca si es parte de la aceptación. Un resultado pendiente no se convierte en aprobado por urgencia del calendario.
