use Gimnasio;
##CONSULTAS
-- 1 Total de Ventas por Socio
SELECT s.socio_id, p.nombre, p.apellido, SUM(v.total) AS total_ventas
FROM Venta v
JOIN Socio s ON v.socio_id = s.socio_id
JOIN Persona p ON s.persona_id = p.persona_id
GROUP BY s.socio_id;

-- 2 Socios con su Objetivo de Entrenamiento
SELECT p.nombre, p.apellido, o.descripcion AS objetivo
FROM ObjetivoEntrenamiento o
JOIN Socio s ON o.socio_id = s.socio_id
JOIN Persona p ON s.persona_id = p.persona_id;

##PROCEDIMIENTOS
-- 1 Registro de un Pago
DELIMITER %%
CREATE PROCEDURE registrar_pago(
    IN p_socio_id INT,
    IN p_monto DECIMAL(10,2),
    IN p_metodo_pago ENUM('efectivo', 'débito', 'crédito', 'transferencia'),
    IN p_membresia_id INT
)
BEGIN
    DECLARE v_pago_id INT;
    
    START TRANSACTION;

    INSERT INTO Pago (monto, fecha_pago, metodo_pago, membresia_id)
    VALUES (p_monto, NOW(), p_metodo_pago, p_membresia_id);

    SET v_pago_id = LAST_INSERT_ID();     -- Obtener el ID del pago
    
    UPDATE Membresia     -- Actualizar la fecha de fin de la membresía si es necesario, Por ejemplo, si el monto es suficiente para extender la membresía
    SET fecha_fin = DATE_ADD(fecha_fin, INTERVAL 1 MONTH)
    WHERE membresia_id = p_membresia_id;
    COMMIT;
END;
%%
DELIMITER ;

-- 2 Registrar una Nueva Venta
DELIMITER %%
CREATE PROCEDURE registrar_venta(
    IN p_socio_id INT,
    IN p_producto_id INT,
    IN p_cantidad INT,
    OUT p_venta_id INT
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);
    START TRANSACTION;

    SELECT precio INTO v_precio FROM Producto WHERE producto_id = p_producto_id;

    SET v_total = v_precio * p_cantidad;

    INSERT INTO Venta (socio_id, fecha, total)
    VALUES (p_socio_id, NOW(), v_total);
    SET p_venta_id = LAST_INSERT_ID();

    -- Insertar los detalles de la venta en la tabla DetalleVenta
    INSERT INTO DetalleVenta (venta_id, producto_id, cantidad, precio_unitario)
    VALUES (p_venta_id, p_producto_id, p_cantidad, v_precio);

    COMMIT;
END;
%%
DELIMITER ;

##VISTA
-- Vista de Ventas por Socio
CREATE VIEW ventas_por_socio AS
SELECT s.socio_id, p.nombre, p.apellido, SUM(v.total) AS total_ventas
FROM Venta v
JOIN Socio s ON v.socio_id = s.socio_id
JOIN Persona p ON s.persona_id = p.persona_id
GROUP BY s.socio_id;
