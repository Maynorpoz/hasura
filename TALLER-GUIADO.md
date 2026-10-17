# Taller guiado · hoja de ruta

Solo los pasos, en orden, con lo que debería salir en cada uno. **40 minutos.**

- Si algo no funciona → [README.md](README.md), sección *Si algo falla*.
- Consola: **http://localhost:8081/console** · secret: **`taller123`**

---

## Paso 0 · Arrancar · 2 min

En la carpeta del taller:

```bash
docker compose up -d
docker compose ps
```

✅ Los dos servicios en `running`, y `taller-postgres` además `(healthy)`.

---

## Paso 1 · Abrir la consola · 1 min

Entra a **http://localhost:8081/console** con el secret `taller123`.

✅ Ves las pestañas **API** y **Data** arriba.

---

## Paso 2 · Mostrar lo único que escribimos · 1 min

Abre [sql/01-schema.sql](sql/01-schema.sql).

> "Son 4 tablas con sus llaves foráneas. No hay servidor, ni rutas, ni
> controladores. Esto es todo."

---

## Paso 3 · Generar la API · 3 min

**Data** → fuente `default` → esquema `public` → botón **Track All**.

Luego pasa a la pestaña **API** y abre el panel **Explorer** de la izquierda.

✅ Aparecen `clientes`, `productos`, `pedidos`, `pedido_items` y
`productos_mas_vendidos`, cada una con sus operaciones de lectura y escritura.
En total la API expone **42 operaciones** (14 queries y 28 mutations); solo
`productos` tiene 10.

---

## Paso 4 · Rastrear las relaciones · 1 min

Vuelve a **Data** → abajo verás **Untracked foreign-key relationships** →
**Track All**.

✅ En el Explorer, dentro de `pedidos` ahora existen `cliente` y `pedido_items`.

---

## Paso 5 · Primera consulta · 4 min

Pestaña **API**. Pega y ejecuta:

```graphql
query {
  productos {
    nombre
    precio
  }
}
```

✅ 10 productos con dos campos.

Agrega `categoria` dentro de las llaves y vuelve a ejecutar.

✅ La respuesta cambia. **El servidor no se tocó.**

Ahora con filtros:

```graphql
query {
  productos(
    where: { categoria: { _eq: "bebida" }, precio: { _lt: 6000 } }
    order_by: { precio: asc }
  ) {
    nombre
    precio
  }
}
```

✅ Exactamente 4 bebidas, en este orden: Cafe americano 3500, Jugo de naranja
4500, Capuchino 5200, Latte vainilla 5800.

---

## Paso 6 · Tres tablas en una sola petición · 5 min

```graphql
query {
  pedidos(order_by: { id: asc }) {
    id
    estado
    cliente { nombre }
    pedido_items {
      cantidad
      producto { nombre }
    }
  }
}
```

✅ El pedido 1 es de **Ana Torres** con *2 x Cafe americano* y *1 x Croissant*;
el pedido 2 es de **Luis Gomez** con *1 x Capuchino* y *2 x Brownie*.

> "Una sola petición, una sola consulta SQL. Nadie programó este JOIN: Hasura lo
> deduce de las llaves foráneas."

---

## Paso 7 · Agregados · 2 min

```graphql
query {
  productos_aggregate {
    aggregate {
      count
      avg { precio }
      max { precio }
    }
  }
}
```

✅ `count: 10`, `avg: 5960`, `max: 11500`.

---

## Paso 8 · Campo calculado · 3 min

**Data** → tabla `pedidos` → pestaña **Modify** → baja a **Computed fields** →
**Add a computed field**:

- **Name:** `total`
- **Function:** `pedido_total`
- **Save**

Luego, en **API**:

```graphql
query {
  pedidos(order_by: { id: asc }) {
    id
    estado
    total
  }
}
```

✅ Pedido 1 → `11200`, pedido 2 → `14800`, pedido 3 → `5800`.

> "El total lo calcula una función SQL. Hasura no reemplaza a Postgres: lo usa."

---

## Paso 9 · Escribir datos · 5 min

Un pedido con sus dos líneas, en una sola transacción:

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

✅ Devuelve el pedido **id 6** con **total 11800** y sus dos productos.

> "Si una línea falla, no se inserta nada. Esto suele ser un controlador entero
> con transacciones a mano."

---

## Paso 10 · Tiempo real · 6 min

1. En **API**, ejecuta esto y **déjalo corriendo**:

```graphql
subscription {
  pedidos(where: { estado: { _in: ["pendiente", "preparando", "listo"] } }) {
    id
    estado
    cliente { nombre }
  }
}
```

2. Abre [demo-tiempo-real/index.html](demo-tiempo-real/index.html) con doble clic
   y ponlo al lado de la consola.

✅ Punto verde = conectado, y los pedidos repartidos en tres columnas.

3. En el tablero, clic en **pasar a preparando** de cualquier tarjeta.

✅ La tarjeta salta de columna **y** la subscription de la consola se actualiza
sola, sin recargar nada.

> "Cambié la palabra `query` por `subscription`. Eso fue todo el WebSocket."

---

## Paso 11 · Permisos por rol · 5 min

1. **Data** → tabla `pedidos` → pestaña **Permissions**.
2. En *Enter new role* escribe `cliente` y haz clic en la celda de **select**.
3. **Row select permissions** → *With custom check* → pega:

```json
{ "cliente_id": { "_eq": "X-Hasura-User-Id" } }
```

4. En **Column select permissions** marca `id`, `estado`, `notas`, `created_at`
   (deja `cliente_id` sin marcar).
5. **Save Permissions**.
6. Vuelve a **API**, abre **Request Headers** y agrega:

| Header | Valor |
|---|---|
| `x-hasura-role` | `cliente` |
| `x-hasura-user-id` | `1` |

7. Ejecuta:

```graphql
query {
  pedidos { id estado notas }
}
```

✅ Solo **2 pedidos** (el 1 y el 3), los de Ana.

8. Cambia el header a `x-hasura-user-id: 2` y ejecuta lo mismo.

✅ La respuesta cambia sin tocar la query.

9. Pide `cliente_id` dentro de la query.

✅ Error: `field 'cliente_id' not found in type: 'pedidos'`. Para ese rol la
columna no existe.

> "La query es idéntica; lo que cambia es quién pregunta. En producción estos
> headers vienen firmados en un JWT y no se pueden falsear."

---

## Cierre · 2 min

Al terminar, tus compañeros deberían poder explicar tres cosas:

1. De dónde salió la API: del **esquema** de la base de datos.
2. Por qué una query trae tres tablas: de las **llaves foráneas**.
3. Dónde vive la seguridad: en **permisos por rol**, no en código.

---

## Si sobra tiempo · retos para que ellos resuelvan

<details>
<summary><b>Reto 1.</b> Los postres disponibles, del más caro al más barato.</summary>

```graphql
query {
  productos(
    where: { categoria: { _eq: "postre" }, disponible: { _eq: true } }
    order_by: { precio: desc }
  ) {
    nombre
    precio
  }
}
```

✅ Cheesecake 7500 y Brownie 4800.
</details>

<details>
<summary><b>Reto 2.</b> Los 3 productos más caros del menú.</summary>

```graphql
query {
  productos(order_by: { precio: desc }, limit: 3) {
    nombre
    precio
  }
}
```

✅ Ensalada cesar 11500, Sandwich de pollo 9800, Cheesecake 7500.
</details>

<details>
<summary><b>Reto 3.</b> Los pedidos que incluyen un Brownie. (Difícil: hay que filtrar por una relación anidada.)</summary>

```graphql
query {
  pedidos(where: { pedido_items: { producto: { nombre: { _eq: "Brownie" } } } }) {
    id
    estado
    cliente { nombre }
  }
}
```

✅ Un solo pedido: el **2**, de Luis Gomez. El filtro atraviesa dos relaciones
(`pedido_items` → `producto`) sin que nadie escribiera ese JOIN.
</details>

---

Para seguir por su cuenta: [PRACTICA-REST.md](PRACTICA-REST.md) convierte estas
queries en endpoints REST.
