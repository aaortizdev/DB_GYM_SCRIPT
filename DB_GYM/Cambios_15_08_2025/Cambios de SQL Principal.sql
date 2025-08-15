-- 1)Corrección de la tabla Producto para que sea decimales y no float
ALTER TABLE Producto 
  MODIFY COLUMN precio DECIMAL(10,2) NOT NULL,
  MODIFY COLUMN stock INT NOT NULL DEFAULT 0;
  -- ADD CONSTRAINT chk_stock_no_neg CHECK (stock >= 0);
  
-- 2)Correción de precio_unitario en DetalleVenta para no perder el precio histórico si el producto cambia
ALTER TABLE DetalleVenta 
  ADD COLUMN precio_unitario DECIMAL(10,2) DEFAULT NULL AFTER producto_id,
  ADD COLUMN subtotal DECIMAL(10,2) AS (cantidad * precio_unitario) STORED;
  
-- 3)Asegurar que total exista y sea NOT NULL
ALTER TABLE Venta 
  MODIFY COLUMN total DECIMAL(10,2) NOT NULL;

-- 4)Reglas de horario
ALTER TABLE HorarioLaboral
  MODIFY COLUMN hora_inicio DATETIME NOT NULL,
  MODIFY COLUMN hora_fin   DATETIME NOT NULL,
  ADD CONSTRAINT chk_rango_horario CHECK (hora_fin > hora_inicio);
  
  -- 5)Asistencia no nula
ALTER TABLE Asistencia 
  MODIFY COLUMN fecha_asistencia DATETIME NOT NULL;
  
  
## Triggers rehechos con variables locales(NO USADO)
DROP TRIGGER IF EXISTS tgr_insert_socio;
DELIMITER %%
CREATE TRIGGER tgr_insert_socio BEFORE INSERT ON Socio
FOR EACH ROW
BEGIN
  DECLARE v_tipo SET('socio','empleado');
  SELECT tipo INTO v_tipo FROM Persona WHERE persona_id = NEW.persona_id;
  IF v_tipo IS NULL OR FIND_IN_SET('socio', v_tipo) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La persona no está registrada como socio';
  END IF;
END;
%%
DELIMITER ;
## Triggers rehechos con variables locales(NO USADO)
DROP TRIGGER IF EXISTS tgr_insert_empleado;
DELIMITER %%
CREATE TRIGGER tgr_insert_empleado BEFORE INSERT ON Empleado
FOR EACH ROW
BEGIN
  DECLARE v_tipo SET('socio','empleado');
  SELECT tipo INTO v_tipo FROM Persona WHERE persona_id = NEW.persona_id;
  IF v_tipo IS NULL OR FIND_IN_SET('empleado', v_tipo) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La persona no está registrada como empleado';
  END IF;
END;
%%
DELIMITER ;




  
  
## 6) Triggers para recalcular el total en cada cambio del detalle
DROP TRIGGER IF EXISTS tgr_detalle_ins_calcula_total;
DROP TRIGGER IF EXISTS tgr_detalle_upd_calcula_total;
DROP TRIGGER IF EXISTS tgr_detalle_del_calcula_total;

DELIMITER %%
CREATE TRIGGER tgr_detalle_ins_calcula_total
AFTER INSERT ON DetalleVenta
FOR EACH ROW
BEGIN
  UPDATE DetalleVenta
    SET precio_unitario = (SELECT precio FROM Producto WHERE producto_id = NEW.producto_id)
  WHERE detalle_id = NEW.detalle_id;

  UPDATE Venta v
     JOIN (SELECT venta_id, SUM(subtotal) s FROM DetalleVenta WHERE venta_id = NEW.venta_id GROUP BY venta_id) x
       ON v.venta_id = x.venta_id
    SET v.total = x.s;
END;
%%
CREATE TRIGGER tgr_detalle_upd_calcula_total
AFTER UPDATE ON DetalleVenta
FOR EACH ROW
BEGIN
  -- Si cambiaron producto o cantidad, refrescar precio_unitario cuando cambie producto
  IF NEW.producto_id <> OLD.producto_id THEN
    UPDATE DetalleVenta
       SET precio_unitario = (SELECT precio FROM Producto WHERE producto_id = NEW.producto_id)
     WHERE detalle_id = NEW.detalle_id;
  END IF;

  UPDATE Venta v
     JOIN (SELECT venta_id, SUM(subtotal) s FROM DetalleVenta WHERE venta_id = NEW.venta_id GROUP BY venta_id) x
       ON v.venta_id = x.venta_id
    SET v.total = x.s;
END;
%%
CREATE TRIGGER tgr_detalle_del_calcula_total
AFTER DELETE ON DetalleVenta
FOR EACH ROW
BEGIN
  UPDATE Venta v
     LEFT JOIN (SELECT venta_id, SUM(subtotal) s FROM DetalleVenta WHERE venta_id = OLD.venta_id GROUP BY venta_id) x
       ON v.venta_id = x.venta_id
    SET v.total = COALESCE(x.s, 0.00)
  WHERE v.venta_id = OLD.venta_id;
END;
%%
DELIMITER ;
  
-- 7) Mejoras en Los FK de estas tablas paa evitar errores
-- ON DELETE /ON UPDATE garantizan que los registros dependientes se comporten de manera coherente
ALTER TABLE Socio 
  DROP FOREIGN KEY fk_persona_id_socio,
  ADD CONSTRAINT fk_persona_id_socio 
    FOREIGN KEY (persona_id) REFERENCES Persona(persona_id) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE Empleado 
  DROP FOREIGN KEY fk_persona_id_empleado,
  ADD CONSTRAINT fk_persona_id_empleado 
    FOREIGN KEY (persona_id) REFERENCES Persona(persona_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  DROP FOREIGN KEY fk_supervisor_id,
  ADD CONSTRAINT fk_supervisor_id 
    FOREIGN KEY (supervisor_id) REFERENCES Empleado(empleado_id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE HorarioLaboral
  DROP FOREIGN KEY fk_horario_id,
  ADD CONSTRAINT fk_horario_empleado 
    FOREIGN KEY (empleado_id) REFERENCES Empleado(empleado_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE Venta 
  DROP FOREIGN KEY fk_socio_id_venta,
  ADD CONSTRAINT fk_socio_id_venta 
    FOREIGN KEY (socio_id) REFERENCES Socio(socio_id) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE DetalleVenta
  DROP FOREIGN KEY fk_venta_id_detalle,
  DROP FOREIGN KEY fk_producto_id_detalle,
  ADD CONSTRAINT fk_venta_id_detalle 
    FOREIGN KEY (venta_id) REFERENCES Venta(venta_id) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT fk_producto_id_detalle
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE Membresia 
  DROP FOREIGN KEY fk_socio_id_membresia,
  ADD CONSTRAINT fk_socio_id_membresia 
    FOREIGN KEY (socio_id) REFERENCES Socio(socio_id) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE Pago 
  DROP FOREIGN KEY fk_membresia_id_pago,
  ADD CONSTRAINT fk_membresia_id_pago 
    FOREIGN KEY (membresia_id) REFERENCES Membresia(membresia_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE Asistencia 
  DROP FOREIGN KEY fk_membresia_id_asistencia,
  ADD CONSTRAINT fk_membresia_id_asistencia 
    FOREIGN KEY (membresia_id) REFERENCES Membresia(membresia_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE Clase 
  DROP FOREIGN KEY fk_empleado_id_clase,
  ADD CONSTRAINT fk_empleado_id_clase 
    FOREIGN KEY (empleado_id) REFERENCES Empleado(empleado_id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE Mantenimiento 
  DROP FOREIGN KEY fk_empleado_mante,
  DROP FOREIGN KEY fk_maquina_mante,
  ADD CONSTRAINT fk_empleado_mante 
    FOREIGN KEY (empleado_id) REFERENCES Empleado(empleado_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT fk_maquina_mante 
    FOREIGN KEY (maquina_id) REFERENCES Maquina(maquina_id) ON DELETE RESTRICT ON UPDATE CASCADE;