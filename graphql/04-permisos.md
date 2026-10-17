# Permisos por rol (el punto donde Hasura deja de ser "un juguete")

Hasta ahora todo se ejecuto como **admin** (con `x-hasura-admin-secret`), que ve
todo. En una app real el cliente nunca usa el admin secret: se usa un **rol**.

La regla de permisos es una condicion que Hasura **inyecta en el WHERE de cada
consulta**. Si la fila no cumple, para ese rol simplemente no existe.

## Configurarlo en la consola (3 minutos)

1. `Data` → tabla **pedidos** → pestaña **Permissions**.
2. En "Enter new role" escribe `cliente` y haz clic en la celda de **select**.
3. **Row select permissions** → *With custom check*:
   ```json
   { "cliente_id": { "_eq": "X-Hasura-User-Id" } }
   ```
4. **Column select permissions**: marca `id`, `estado`, `notas`, `created_at`
   (deja `cliente_id` sin marcar si no quieres exponerlo).
5. Guarda con **Save Permissions**.
6. Repite para la tabla **clientes** con el check:
   ```json
   { "id": { "_eq": "X-Hasura-User-Id" } }
   ```
7. Para **productos**, rol `cliente`, permiso **select** con *Without any checks*
   (el menu es publico), y en columnas marca todas.

## Probarlo

En GraphiQL, abre **Request Headers** y:

- Quita (o desmarca) `x-hasura-admin-secret`.
- Agrega:

  | Header            | Valor     |
  |-------------------|-----------|
  | `x-hasura-role`   | `cliente` |
  | `x-hasura-user-id`| `1`       |

Ejecuta:

```graphql
query QueVeElCliente1 {
  pedidos { id estado notas }
}
```

Devuelve **solo los pedidos de Ana (cliente 1)**. Cambia el header a
`x-hasura-user-id: 2` y la respuesta cambia sin tocar ni una linea de la query.
Pide `cliente_id` y Hasura responde con un error de campo no disponible.

> En produccion esos headers no los escribe el usuario: vienen firmados dentro de
> un **JWT** (`HASURA_GRAPHQL_JWT_SECRET`) emitido por Auth0, Firebase, Clerk,
> Supabase Auth o tu propio login. Hasura valida la firma y lee los claims
> `x-hasura-*`. Es decir: el cliente **no puede mentir** sobre quien es.

## Mas cosas que se configuran igual (sin codigo)

- **Limites**: `Limit` en el permiso de select = tope de filas por peticion.
- **Preset de columnas**: al insertar, forzar `cliente_id = X-Hasura-User-Id`
  para que nadie cree pedidos a nombre de otro.
- **Allow-list** y limites de profundidad/rate, para que nadie mande una query
  gigante maliciosa.
