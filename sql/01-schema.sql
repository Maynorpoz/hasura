-- ============================================================
-- Taller Hasura - Esquema de la base de datos "cafeteria"
-- Este archivo lo ejecuta PostgreSQL automaticamente al crearse
-- el contenedor por primera vez.
--
-- IDEA CLAVE: aqui solo modelamos DATOS. No escribimos ni una
-- linea de backend. Hasura leera estas tablas, sus llaves
-- foraneas y sus tipos para generar la API GraphQL.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Clientes de la cafeteria
-- ------------------------------------------------------------
CREATE TABLE clientes (
    id          serial PRIMARY KEY,
    nombre      text        NOT NULL,
    email       text        NOT NULL UNIQUE,
    created_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE clientes IS 'Personas que hacen pedidos en la cafeteria';

-- ------------------------------------------------------------
-- 2. Catalogo de productos
-- ------------------------------------------------------------
CREATE TABLE productos (
    id          serial PRIMARY KEY,
    nombre      text          NOT NULL,
    categoria   text          NOT NULL,
    precio      numeric(10,2) NOT NULL CHECK (precio >= 0),
    disponible  boolean       NOT NULL DEFAULT true
);

COMMENT ON TABLE productos IS 'Menu de la cafeteria';

-- ------------------------------------------------------------
-- 3. Pedidos
--    La llave foranea cliente_id es lo que permite a Hasura
--    inferir la relacion pedido -> cliente y cliente -> pedidos.
-- ------------------------------------------------------------
CREATE TABLE pedidos (
    id          serial PRIMARY KEY,
    cliente_id  integer     NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    estado      text        NOT NULL DEFAULT 'pendiente'
                            CHECK (estado IN ('pendiente','preparando','listo','entregado','cancelado')),
    notas       text,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_estado  ON pedidos(estado);

COMMENT ON TABLE pedidos IS 'Cabecera del pedido; el estado es lo que seguiremos en tiempo real';

-- ------------------------------------------------------------
-- 4. Lineas de cada pedido (tabla intermedia pedido <-> producto)
-- ------------------------------------------------------------
CREATE TABLE pedido_items (
    id               serial PRIMARY KEY,
    pedido_id        integer       NOT NULL REFERENCES pedidos(id)   ON DELETE CASCADE,
    producto_id      integer       NOT NULL REFERENCES productos(id),
    cantidad         integer       NOT NULL CHECK (cantidad > 0),
    precio_unitario  numeric(10,2) NOT NULL CHECK (precio_unitario >= 0)
);

CREATE INDEX idx_items_pedido   ON pedido_items(pedido_id);
CREATE INDEX idx_items_producto ON pedido_items(producto_id);

COMMENT ON TABLE pedido_items IS 'Detalle del pedido: que producto y cuantos';

-- ------------------------------------------------------------
-- 5. Trigger: mantener updated_at al dia
--    Demuestra que la logica que ya vive en Postgres sigue
--    funcionando: Hasura no la reemplaza, la aprovecha.
-- ------------------------------------------------------------
CREATE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pedidos_updated_at
    BEFORE UPDATE ON pedidos
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------
-- 6. Funcion para un CAMPO CALCULADO de Hasura
--    Recibe una fila de "pedidos" y devuelve el total.
--    En la consola la expondremos como el campo: pedidos.total
-- ------------------------------------------------------------
CREATE FUNCTION pedido_total(pedido_row pedidos)
RETURNS numeric AS $$
    SELECT COALESCE(SUM(cantidad * precio_unitario), 0)
    FROM pedido_items
    WHERE pedido_id = pedido_row.id;
$$ LANGUAGE sql STABLE;

-- ------------------------------------------------------------
-- 7. Vista: productos mas vendidos
--    Hasura tambien expone VISTAS como si fueran tablas.
-- ------------------------------------------------------------
CREATE VIEW productos_mas_vendidos AS
SELECT p.id            AS producto_id,
       p.nombre,
       p.categoria,
       SUM(pi.cantidad)                      AS unidades_vendidas,
       SUM(pi.cantidad * pi.precio_unitario) AS ingresos
FROM productos p
JOIN pedido_items pi ON pi.producto_id = p.id
GROUP BY p.id, p.nombre, p.categoria
ORDER BY unidades_vendidas DESC;
