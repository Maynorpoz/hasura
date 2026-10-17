-- ============================================================
-- Datos de ejemplo para el taller
-- ============================================================

INSERT INTO clientes (nombre, email) VALUES
    ('Ana Torres',     'ana@uni.edu'),
    ('Luis Gomez',     'luis@uni.edu'),
    ('Maria Rincon',   'maria@uni.edu'),
    ('Carlos Mendoza', 'carlos@uni.edu'),
    ('Sofia Herrera',  'sofia@uni.edu');

INSERT INTO productos (nombre, categoria, precio, disponible) VALUES
    ('Cafe americano',   'bebida',   3500,  true),
    ('Capuchino',        'bebida',   5200,  true),
    ('Latte vainilla',   'bebida',   5800,  true),
    ('Jugo de naranja',  'bebida',   4500,  true),
    ('Croissant',        'panaderia',4200,  true),
    ('Pan de queso',     'panaderia',2800,  true),
    ('Brownie',          'postre',   4800,  true),
    ('Cheesecake',       'postre',   7500,  true),
    ('Sandwich de pollo','comida',   9800,  true),
    ('Ensalada cesar',   'comida',  11500, false);

-- Pedidos de ejemplo en distintos estados
INSERT INTO pedidos (cliente_id, estado, notas) VALUES
    (1, 'entregado',  'Sin azucar'),
    (2, 'preparando', NULL),
    (1, 'pendiente',  'Para llevar'),
    (3, 'listo',      'Mesa 4'),
    (4, 'pendiente',  NULL);

-- Detalle de cada pedido (precio_unitario se congela al momento de la compra)
INSERT INTO pedido_items (pedido_id, producto_id, cantidad, precio_unitario) VALUES
    (1, 1, 2, 3500),
    (1, 5, 1, 4200),
    (2, 2, 1, 5200),
    (2, 7, 2, 4800),
    (3, 3, 1, 5800),
    (4, 9, 1, 9800),
    (4, 4, 2, 4500),
    (5, 8, 1, 7500),
    (5, 1, 1, 3500);
