# Guion por diapositiva · qué decir

Esto es el **texto hablado**, pensado para alguien que no sabía nada del tema.
No lo leas palabra por palabra: la idea es que sepas a dónde vas en cada parte.

- Logística, orden de la demo y preguntas probables → [GUION-EXPOSICION.md](GUION-EXPOSICION.md)
- Los pasos del taller en vivo → [TALLER-GUIADO.md](TALLER-GUIADO.md)

---

# 1 · ¿Qué es Hasura?

## 1.1 · Arranca por el problema, no por la herramienta · 45 seg

> "Imagínense que les piden una app para la cafetería de la universidad. Que se
> vea el menú, que uno pida, y que en la cocina aparezca el pedido.
>
> Lo normal sería: diseñar la base de datos, y después escribir un backend.
> Un archivo para conectarse a la base, otro para los modelos, otro para las
> rutas, uno por cada operación: listar productos, buscar uno, crear pedido,
> actualizar estado… Y después de dos días de trabajo, ¿qué tienen? Código que
> básicamente **traduce** peticiones a consultas SQL. Nada más.
>
> Hasura parte de una idea: si ese código es siempre el mismo trabajo mecánico,
> ¿por qué lo escribimos a mano?"

**Pausa.** Aquí es donde la gente entiende por qué existe la herramienta.

## 1.2 · La definición · 30 seg

> "Hasura es un **motor de código abierto que se conecta a tu base de datos y
> genera automáticamente una API GraphQL lista para usar.**"

Si solo pudieras decir una frase en toda la exposición, es esa.

## 1.3 · La analogía · 45 seg

Usa una sola, la que más te acomode:

> **El traductor.** "Un backend hecho a mano es un traductor que ustedes
> contratan y entrenan: le enseñan, tabla por tabla, cómo hablar con la base de
> datos. Hasura ya sabe leer el idioma de las bases de datos. No hay que
> enseñarle nada: le muestras la base y empieza a traducir."

> **El plano de la casa.** "Toda base de datos guarda un plano de sí misma: qué
> tablas tiene, de qué tipo es cada columna, cuáles se relacionan con cuáles.
> Nosotros los programadores leemos ese plano y escribimos el backend a mano.
> Hasura lee el mismo plano y lo escribe solo."

## 1.4 · Qué hace exactamente · 1 min

Tres pasos, y conviene decirlos con los dedos:

1. **Lee el catálogo** de la base: tablas, columnas, tipos y llaves foráneas.
2. **Genera un esquema GraphQL** a partir de eso: por cada tabla crea
   operaciones de leer, insertar, actualizar y borrar.
3. **Traduce cada consulta a SQL**, la ejecuta y devuelve el resultado.

> "Y eso es todo el truco. Hasura no guarda datos: **la base de datos sigue
> siendo la dueña de la verdad.** Hasura es la capa que la expone."

Dato para soltar aquí, porque impresiona:

> "En nuestro ejemplo son 4 tablas. Al conectarlas, Hasura generó **42
> operaciones** distintas: 14 de consulta y 28 de escritura. Cero líneas de
> backend."

## 1.5 · Qué NO es (para que nadie se quede con la idea equivocada) · 30 seg

- **No es una base de datos.** Necesita un PostgreSQL detrás.
- **No es un framework** donde programas tu lógica. Es una capa que ya viene hecha.
- **No elimina a los programadores.** Elimina el CRUD repetitivo. La lógica de
  negocio de verdad —cobrar, enviar correos, validar reglas raras— se sigue
  escribiendo, y se conecta con *Actions* o *Event Triggers*.

> "Hasura no hace que el trabajo desaparezca: lo mueve a donde importa, que es
> diseñar bien los datos."

---

# 2 · El tiempo real y los WebSockets

Esta es la parte que más impresiona. Va en tres tiempos: **el problema**,
**qué es un WebSocket**, y **cómo lo hace Hasura**.

## 2.1 · El problema, con algo que todos han vivido · 45 seg

> "Piensen en una app de domicilios. Uno pide y la pantalla dice 'preparando'.
> ¿Cómo se entera la app de que ya cambió a 'en camino'?
>
> La forma vieja es que la app pregunte cada cierto tiempo: *¿ya cambió?
> ¿ya cambió? ¿ya cambió?* Eso se llama **polling**, y es malísimo: si pregunta
> cada 10 segundos, gasta batería y datos preguntando al vacío la mayoría de las
> veces; y aun así el usuario puede esperar 10 segundos de más."

## 2.2 · Qué es un WebSocket · 45 seg

> "HTTP, el protocolo de toda la web, funciona como una carta: el cliente
> pregunta, el servidor responde, y la conexión se cierra. El servidor **no
> puede** hablarle al cliente por su cuenta.
>
> Un **WebSocket** es distinto: es una línea telefónica que queda abierta en los
> dos sentidos. Se abre una vez, y a partir de ahí el servidor puede mandarte
> información cuando él quiera, sin que tú preguntes."

Analogía de cierre:

> "Polling es llamar a la pizzería cada dos minutos a preguntar si ya salió.
> WebSocket es que ellos te llamen cuando salió."

## 2.3 · Cómo está integrado en Hasura · 1 min

Lo importante: **no hay que configurar nada.**

> "En Hasura uno no 'activa' los WebSockets ni instala una librería. Toman la
> consulta que ya escribieron y le cambian **una palabra**: donde dice `query`,
> escriben `subscription`.
>
> Eso es todo. La misma consulta, los mismos campos, los mismos permisos. La
> diferencia es que en vez de responder una vez y cerrar, Hasura abre el
> WebSocket y te sigue mandando el resultado cada vez que cambia."

Muestra la query al lado de la subscription; se ven idénticas salvo la primera
palabra. Ese contraste visual vale más que cualquier explicación.

> "Y como es la misma capa de siempre, **los permisos por rol siguen
> aplicando**: cada usuario recibe en vivo únicamente las filas que tiene
> derecho a ver."

## 2.4 · Cómo funciona por dentro · 1 min

Esto es lo que te separa de quien solo repite lo que dice la página oficial.
Son datos medidos en nuestro propio servidor:

> "¿Y cómo sabe Hasura que algo cambió? Mucha gente asume que la base de datos
> le avisa. No es así.
>
> Hasura **guarda tu consulta y la vuelve a ejecutar cada segundo**. Pero hace
> dos cosas inteligentes:
>
> 1. **Agrupa las suscripciones.** Si cien personas están viendo el mismo
>    tablero, no son cien consultas: Hasura las junta en lotes de hasta 100 y
>    hace **una sola consulta SQL** para todas. Eso se llama multiplexing.
> 2. **Compara el resultado con el anterior** y solo manda algo por el WebSocket
>    **si cambió**. Si nada cambió, no gasta red."

Los números exactos de nuestro montaje (salen en el log de arranque de Hasura:
`live_query_options: {batch_size: 100, refetch_delay: 1}`):

| Qué | Valor |
|---|---|
| Cada cuánto re-ejecuta la consulta | 1 segundo |
| Cuántas suscripciones agrupa por consulta SQL | hasta 100 |
| Retraso medido de un cambio hasta la pantalla | ~1 segundo |

Y un detalle que descubrimos probando, buenísimo para contar:

> "Hicimos una prueba cambiando el estado de un pedido… al mismo estado que ya
> tenía. Y no llegó nada por el WebSocket. Tiene todo el sentido: la base sí se
> escribió, pero el **resultado** de la consulta se veía igual, así que Hasura
> no tenía nada nuevo que mandar."

Si alguien pregunta por qué un segundo y no instantáneo:

> "Es el precio de que escale. Un segundo de retraso a cambio de que mil
> usuarios conectados no se conviertan en mil consultas por segundo contra la
> base. Y el intervalo se puede bajar con una variable de entorno si tu caso lo
> necesita."

## 2.5 · Qué decir mientras muestras el tablero · 30 seg

Con el tablero y la consola lado a lado:

> "Esta pantalla de la izquierda son 60 líneas de JavaScript, sin ninguna
> librería. No tiene servidor propio: le habla directo a Hasura.
>
> Voy a cambiar este pedido aquí en la consola… y miren la otra pantalla."

*(cambias el estado y esperas en silencio el segundo que tarda)*

> "No recargué nada. Así es como funciona el tablero de una cocina, el chat de
> una app o el marcador de un partido en vivo."

## 2.6 · Lo que NO resuelve · 20 seg

> "Un detalle honesto: las subscriptions te dicen **cómo está algo ahora**, no
> te avisan de **cada evento** que ocurrió. Si necesitas reaccionar a cada
> cambio —mandar un correo cada vez que entra un pedido— eso se hace con
> *Event Triggers*, que son webhooks que Hasura dispara cuando la tabla cambia."

---

## Resumen de las dos secciones, por si te quedas en blanco

1. Hasura lee el plano de tu base de datos y escribe la API por ti.
2. La base de datos sigue siendo la dueña de los datos.
3. Para tiempo real, cambias `query` por `subscription`: ahí aparecen los
   WebSockets, sin configurar nada.
4. Por debajo, Hasura re-ejecuta la consulta cada segundo, agrupada con las de
   los demás usuarios, y solo te manda algo si el resultado cambió.
