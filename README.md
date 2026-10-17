# Taller: Hasura — API GraphQL generada desde PostgreSQL

> Generar una API y consultar datos **sin programar un backend completo**.
> Duración: ~40 minutos. No se escribe ni una línea de servidor: solo SQL para
> modelar los datos y clics en la consola de Hasura.

El caso de ejemplo es la **cafetería de la universidad**: clientes que hacen
pedidos, un menú de productos y un tablero de cocina que se actualiza en vivo.

> 🧭 **¿Vas a dirigir la sesión paso a paso?** Usa
> **[TALLER-GUIADO.md](TALLER-GUIADO.md)**: los mismos pasos sin explicaciones ni
> contexto, solo qué hacer y qué debe salir en cada uno. Este README queda como
> referencia y respaldo (troubleshooting, plan B sin Docker, glosario).

---

## Qué pide el taller y dónde se cumple

| Lo que pide el enunciado | Cómo se demuestra | Paso |
|---|---|---|
| **Generar una API** | Un clic en *Track All* y la API GraphQL existe: queries, mutations y agregados para cada tabla. | 3 |
| **Consultar datos** | Queries con filtros y relaciones anidadas, mutations de escritura y subscriptions en tiempo real. | 4, 6, 7 |
| **Sin programar un backend completo** | En este repo no hay ni un archivo de servidor: **0 líneas** de JavaScript, Python o Java de backend. Lo único escrito son **62 líneas de SQL** que describen tablas (no comportamiento) y **38 líneas** de configuración de Docker. | — |

De esas 62 líneas de SQL salen 5 tablas y vistas expuestas como **42**
operaciones GraphQL (14 queries y 28 mutations). El único JavaScript del proyecto está en
`demo-tiempo-real/index.html` (~60 líneas) y es **cliente**, no servidor: es la
app que consume la API, el equivalente a lo que harías en React o Angular.

**Si el tiempo se acorta**, la secuencia mínima que cumple el enunciado es:
Paso 1 (levantar) → Paso 3 (*Track All*) → Paso 4 (query anidada) →
Paso 6 (insert anidado) → Paso 7 (tiempo real). Los pasos 5, 8 y 9 son
excedente para mostrar dominio del tema.

---

## La idea en un diagrama

```
                         ┌───────────────────────────────┐
   tu app / GraphiQL ◄──►│           HASURA              │
   (query, mutation,     │  lee el catálogo de la BD     │
    subscription)        │  y genera la API al instante  │
                         │  + permisos por rol           │
                         └───────────────┬───────────────┘
                                         │  SQL generado
                                         ▼
                         ┌───────────────────────────────┐
                         │         POSTGRESQL            │
                         │  clientes, productos,         │
                         │  pedidos, pedido_items        │
                         └───────────────────────────────┘
```

| Pieza | Papel en el taller |
|---|---|
| **PostgreSQL** | Dónde viven los datos (tablas, llaves foráneas, tipos). |
| **Hasura** | El motor que traduce esas tablas a una API GraphQL, y cada query a SQL. |
| **GraphQL** | El lenguaje con el que pedimos exactamente los campos que queremos. |
| **Resultado** | Un backend funcional en minutos, con filtros, relaciones, tiempo real y permisos. |

---

## Requisitos

- **Docker Desktop** instalado **y corriendo** (el ícono de la ballena activo).
  Verifica con `docker ps`: si responde con una tabla, está listo.
- Un navegador.
- Los puertos **8081** y **5433** libres (el contenedor usa 8080 y 5432 por dentro).
- Nada más: ni Node, ni Python, ni instalar PostgreSQL.

---

## Qué hay en esta carpeta

```
TALLER-GUIADO.md                  hoja de ruta de la sesion: solo los pasos
PRACTICA-REST.md                  practica guiada de endpoints REST (tras el Paso 5)
docker-compose.yml                PostgreSQL + Hasura, un solo comando
.env.example                      credenciales (opcional: ya hay valores por defecto)
sql/01-schema.sql                 las 4 tablas, un trigger, una función y una vista
sql/02-seed.sql                   datos de ejemplo
graphql/01-queries.graphql        consultas listas para pegar
graphql/02-mutations.graphql      insert / update / delete / upsert
graphql/03-subscriptions.graphql  tiempo real
graphql/04-permisos.md            permisos por rol, paso a paso
demo-tiempo-real/index.html       tablero de cocina en vivo (abrir en el navegador)
rest/01-endpoints.json            atajo: crea los 4 endpoints REST de la practica
rest/02-permisos-cliente.json     atajo: permisos del rol cliente
```

---

## Paso 1 · Levantar el stack

En esta carpeta:

```bash
docker compose up -d
```

La primera vez descarga las imágenes de PostgreSQL y Hasura (varios cientos de
MB, un par de minutos). No se instala nada en tu Windows: todo queda dentro de
Docker. Comprueba:

```bash
docker compose ps
```

Ambos servicios deben decir `running`; `taller-postgres` además `(healthy)`.

**Qué acaba de pasar:** se creó la base `cafeteria`, PostgreSQL ejecutó solo los
archivos de `sql/` (así nacieron las tablas y los datos), y Hasura arrancó
apuntando a esa base.

---

## Paso 2 · Abrir la consola

👉 **http://localhost:8081/console** — admin secret: `taller123`

Pestañas que usaremos:

- **API** → GraphiQL, el explorador donde ejecutamos todo.
- **Data** → las tablas y los permisos.
- **Actions / Remote Schemas** → extender la API (fuera del alcance de hoy).

---

## Paso 3 · Rastrear las tablas = aquí nace la API

Hasura **no expone nada sin permiso explícito**. Hay que "rastrear" (*track*) lo
que queremos publicar.

1. Ve a **Data** → fuente `default` → esquema `public`.
2. Verás la lista **Untracked tables or views** con `clientes`, `productos`,
   `pedidos`, `pedido_items` y `productos_mas_vendidos`.
3. Clic en **Track All**.

> 🎤 *Momento clave de la exposición:* abre la pestaña **API** y mira el panel
> **Explorer** de la izquierda. Sin escribir código ya existen `productos`,
> `productos_aggregate`, `productos_by_pk`, `insert_productos`,
> `update_productos`, `delete_productos`… para **cada** tabla.

### Paso 3b · Rastrear las relaciones

Debajo aparece **Untracked foreign-key relationships** → **Track All**.

Hasura leyó las llaves foráneas del `CREATE TABLE` y deduce las relaciones en
ambos sentidos: `pedido.cliente` (objeto) y `cliente.pedidos` (arreglo). Eso es
lo que permite consultar varias tablas anidadas en una sola petición.

---

## Paso 4 · Primeras consultas (Queries)

Pestaña **API**. Abre `graphql/01-queries.graphql` y ve pegando de a una.

Lo mínimo:

```graphql
query {
  productos {
    nombre
    precio
  }
}
```

Compáralo con REST: un `GET /productos` te devuelve **todas** las columnas.
Aquí pides dos campos y recibes dos campos. Agrega `categoria` y vuelve a
ejecutar: la respuesta cambia sin tocar el servidor.

### Filtros, orden y paginación (ya generados)

```graphql
query {
  productos(
    where: { categoria: { _eq: "bebida" }, precio: { _lt: 6000 } }
    order_by: { precio: asc }
    limit: 5
  ) {
    nombre
    precio
  }
}
```

Operadores disponibles sin configurar nada: `_eq` `_neq` `_gt` `_gte` `_lt`
`_lte` `_in` `_nin` `_like` `_ilike` `_is_null` `_and` `_or` `_not`.

### Lo que más impresiona: tres tablas en una petición

```graphql
query {
  pedidos(order_by: { created_at: desc }) {
    id
    estado
    cliente { nombre email }
    pedido_items {
      cantidad
      producto { nombre categoria }
    }
  }
}
```

> 🎤 Esto en un backend hecho a mano son tres consultas o un endpoint
> específico con sus JOINs. Hasura lo resuelve en **una sola consulta SQL**.

### Agregados

```graphql
query {
  productos_aggregate {
    aggregate { count avg { precio } max { precio } }
  }
}
```

---

## Paso 5 · Campo calculado y vista (el SQL sigue siendo tuyo)

Hasura no te quita PostgreSQL: lo aprovecha.

### Campo calculado `total`

En `sql/01-schema.sql` hay una función `pedido_total(pedido_row pedidos)`.
Expónla como campo:

1. **Data** → tabla `pedidos` → pestaña **Modify**.
2. Baja hasta **Computed fields** → **Add a computed field**.
3. Name: `total` · Function: `pedido_total` → **Save**.

Ahora:

```graphql
query {
  pedidos { id estado total }
}
```

### La vista `productos_mas_vendidos`

Ya quedó rastreada en el Paso 3 y se consulta como cualquier tabla:

```graphql
query {
  productos_mas_vendidos(order_by: { unidades_vendidas: desc }, limit: 5) {
    nombre
    unidades_vendidas
    ingresos
  }
}
```

---

## Paso 6 · Escribir datos (Mutations)

Archivo: `graphql/02-mutations.graphql`.

Insert simple:

```graphql
mutation {
  insert_clientes_one(object: { nombre: "Pedro Ramirez", email: "pedro@uni.edu" }) {
    id
    nombre
  }
}
```

**Insert anidado** — el pedido y sus líneas en una sola transacción:

```graphql
mutation {
  insert_pedidos_one(object: {
    cliente_id: 2
    notas: "Extra caliente"
    pedido_items: { data: [
      { producto_id: 1, cantidad: 2, precio_unitario: 3500 }
      { producto_id: 7, cantidad: 1, precio_unitario: 4800 }
    ]}
  }) {
    id
    total
    pedido_items { cantidad producto { nombre } }
  }
}
```

> 🎤 Esto es lo que normalmente cuesta un controlador entero con manejo manual
> de transacciones. Si una línea falla, **nada** se inserta.

También hay `update`, `delete`, `upsert` (`on_conflict`) y varias mutations en
una sola petición en ese mismo archivo.

---

## Paso 7 · Tiempo real (Subscriptions)

Cambia la palabra `query` por `subscription` y ya está. Hasura abre un WebSocket
y te empuja los datos cada vez que cambian en PostgreSQL.

### Demo A — dentro de la consola

1. Pestaña **API**, pega la subscription del tablero:

```graphql
subscription {
  pedidos(where: { estado: { _in: ["pendiente","preparando","listo"] } }) {
    id
    estado
    cliente { nombre }
  }
}
```

2. Ejecútala y **déjala corriendo** (el botón queda en "stop").
3. Abre **otra pestaña del navegador** en la consola y cambia el estado de un
   pedido (por GraphiQL con `update_pedidos_by_pk`, o en **Data → pedidos →
   Browse rows** editando la fila).
4. Vuelve a la primera pestaña: se actualizó sola.

### Demo B — el tablero de cocina (más visual)

Abre **`demo-tiempo-real/index.html`** con doble clic (no necesita servidor).
Verás tres columnas: *pendiente · preparando · listo*.

- El punto verde indica que el WebSocket está conectado.
- Botón **Crear pedido de prueba** → aparece una tarjeta al instante.
- Botón **pasar a …** de cada tarjeta → la tarjeta salta de columna.
- Y lo mejor: pon esta ventana al lado de la consola de Hasura, cambia el estado
  de un pedido **en la consola** y mira cómo la tarjeta se mueve sola.

Son ~60 líneas de JavaScript sin dependencias. Toda la lógica de servidor
—incluido el tiempo real— ya la daba Hasura.

---

## Paso 8 · Permisos por rol (sin esto no es un backend real)

Hasta ahora todo corrió como **admin**, que lo ve todo. En producción cada
usuario solo debe ver lo suyo.

📄 **Sigue `graphql/04-permisos.md`** (3 minutos). Resumen: en
**Data → pedidos → Permissions** creas el rol `cliente` y en el permiso de
*select* pones el check

```json
{ "cliente_id": { "_eq": "X-Hasura-User-Id" } }
```

Luego, en GraphiQL, quitas el admin secret y mandas los headers
`x-hasura-role: cliente` y `x-hasura-user-id: 1`. La **misma query** devuelve
solo los pedidos de ese cliente, porque Hasura inyecta esa condición en el
`WHERE` de cada consulta. En producción esos headers vienen firmados dentro de
un **JWT** y el cliente no puede falsearlos.

---

## Paso 9 · Bonus: un endpoint REST sin escribir código

Para quien no quiera usar GraphQL. Ejemplo rápido:

1. Escribe una query en GraphiQL (por ejemplo `PedidosDeCliente` con su variable).
2. Clic en el botón **REST** del panel derecho.
3. Nómbrala `pedidos-cliente` y guarda.

Hasura publica `GET /api/rest/pedidos-cliente/:clienteId`:

```bash
curl -H "x-hasura-admin-secret: taller123" \
     http://localhost:8081/api/rest/pedidos-cliente/1
```

👉 **Hay una práctica guiada completa de esto** en
[PRACTICA-REST.md](PRACTICA-REST.md): 7 ejercicios con parámetros en la ruta y
en el query string, POST para escribir, los errores que devuelve cada caso,
permisos por rol sobre el mismo endpoint y la documentación OpenAPI que Hasura
genera sola. Todos los resultados están verificados contra este stack.

---

## Paso 10 · Apagar y limpiar

```bash
docker compose stop          # pausar, conserva los datos
docker compose down          # borrar contenedores, conserva los datos
docker compose down -v       # borrar TAMBIÉN la base (empezar de cero)
```

Tras un `down -v`, el siguiente `up -d` vuelve a ejecutar los `sql/` y regenera
la base limpia. **Ojo:** también se pierde la metadata de Hasura (tablas
rastreadas, permisos, campo calculado), así que habrá que repetir los pasos 3
y 5. Para una demo eso es ideal: siempre arrancas desde el mismo punto.

---

## Qué NO hace Hasura (para responder preguntas con honestidad)

- **No diseña tu base de datos.** El modelo de datos sigue siendo tu trabajo; si
  el esquema está mal, la API saldrá mal.
- **No reemplaza la lógica de negocio compleja.** Cobrar una tarjeta, enviar un
  correo o validar reglas raras se hace con **Actions** (tu propia función o
  microservicio) o **Event Triggers** (webhooks cuando cambian los datos).
- **No es autenticación.** Hasura *autoriza* (permisos por rol), pero el login lo
  pone otro: Auth0, Firebase, Clerk, Supabase Auth o tu propio emisor de JWT.
- **Introduce una dependencia.** Tu API queda atada a Hasura y a su forma de
  hacer las cosas.
- **Las consultas pesadas siguen siendo pesadas.** El SQL lo genera Hasura, pero
  los índices los pones tú (mira los `CREATE INDEX` del esquema).

---

## Si algo falla

| Síntoma | Causa y solución |
|---|---|
| `failed to connect to the docker API` / `daemon is not running` | Docker Desktop está cerrado. Ábrelo, espera a que la ballena deje de moverse y repite `docker compose up -d`. |
| `port is already allocated` | Otro proceso o contenedor ocupa el puerto. Mira con `docker ps` quién lo tiene y cambia el número **de la izquierda** en `docker-compose.yml` (ej. `"8082:8080"`); el de la derecha nunca se toca. |
| Las tablas no aparecen en **Data** | El volumen ya existía, así que los `sql/` no se ejecutaron (solo corren al crear la base). `docker compose down -v` y vuelve a subir. |
| `connection error` en la consola | PostgreSQL aún no termina de arrancar. Espera 10 s y recarga; revisa `docker compose logs postgres`. |
| La consola pide un secret y no lo recuerdas | Es `taller123` (o lo que pusiste en `.env`). |
| El tablero HTML no conecta (punto gris) | Verifica `docker compose ps`, que la URL sea `ws://localhost:8081/v1/graphql` y que el secret coincida. Abre la consola del navegador (F12) para ver el error. |
| Cambié el esquema por SQL y no lo veo en GraphQL | Vuelve a **Data** y rastrea la tabla o la columna nueva. |

Ver logs en vivo:

```bash
docker compose logs -f graphql-engine
```

---

## Plan B: sin Docker (si no te arranca)

Hasura Cloud tiene un tier gratuito que incluye un PostgreSQL de **Neon** en un
clic, todo desde el navegador:

1. Crea una cuenta en <https://cloud.hasura.io> y un proyecto nuevo (v2).
2. **Data → Connect Database → Create Neon Database** (gratis, un clic).
3. **Data → SQL**: pega el contenido de `sql/01-schema.sql` y ejecuta; repite con
   `sql/02-seed.sql`. Marca *"track this"* si te lo ofrece.
4. Sigue el taller desde el **Paso 3**: la consola es idéntica.
5. En el demo HTML cambia la URL por la de tu proyecto
   (`wss://<tu-proyecto>.hasura.app/v1/graphql`) y el secret por el de la nube.

Requiere internet y registro, y los límites del plan gratis cambian con el
tiempo, así que haz este montaje **antes** de la clase.

---

## Glosario de un renglón

- **GraphQL**: lenguaje de consulta para APIs; el cliente pide los campos exactos.
- **Query / Mutation / Subscription**: leer / escribir / escuchar cambios.
- **GraphiQL**: el explorador interactivo de la API (pestaña **API** de la consola).
- **Track (rastrear)**: autorizar a Hasura a exponer una tabla, vista o relación.
- **Metadata**: la configuración de Hasura (qué está rastreado, permisos,
  relaciones). Vive en la base de datos, no en tu código.
- **Campo calculado**: una función SQL expuesta como si fuera una columna.
- **Rol + claims `x-hasura-*`**: la identidad con la que Hasura filtra las filas.
