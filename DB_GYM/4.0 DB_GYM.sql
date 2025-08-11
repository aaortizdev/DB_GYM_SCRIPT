drop database if exists Gimnasio;

create database if not exists Gimnasio;
use Gimnasio;

create table if not exists Persona(
	persona_id int primary key auto_increment,
    cedula varchar(10) not null UNIQUE,
    nombre varchar(100) not null,
    apellido varchar(100) not null,
    tipo ENUM('socio','empleado') not null default 'socio',
    telefono varchar(15) UNIQUE,
    correo varchar(150) UNIQUE,
    fecha_nacimiento date,
    
    constraint chk_cedula_length check (CHAR_LENGTH(cedula) = 10),
    constraint chk_cedula_numerica check (cedula regexp('^[0-9]+$')),
    constraint chk_correo_formato check (correo Like '%@%.%')
);

create table if not exists Socio(
	socio_id int primary key auto_increment,
    persona_id int not null UNIQUE,
    ciudad varchar(255),
	calle_principal varchar(255),
    numero_residencia varchar(50),

    constraint fk_persona_id_socio foreign key (persona_id) references Persona(persona_id)
);

create table if not exists ObjetivoEntrenamiento(
	objetivo_entrenamiento_id int primary key auto_increment, 
	socio_id int not null,
    descripcion varchar(500) not null,
    constraint fk_socio_id foreign key (socio_id) references Socio(socio_id)
);

create table if not exists Empleado(
	empleado_id int primary key auto_increment,
    persona_id int not null UNIQUE,
    estado enum('activo','inactivo'),
    tipo enum('técnico','instructor','recepcionista') not null,
    fecha_contratacion date,
    salario decimal(10,2),
    supervisor_id int,

    constraint fk_persona_id_empleado foreign key (persona_id) references Persona(persona_id),
    constraint fk_supervisor_id foreign key (supervisor_id) references Empleado(empleado_id)
);

create table if not exists HorarioLaboral(
	horario_id int primary key auto_increment, 
	empleado_id int not null,
    hora_inicio datetime,
    hora_fin datetime,
    constraint fk_horario_id foreign key (empleado_id) references Empleado(empleado_id)
);

/*
	TRIGGER tgr_insert_socio que válida que una persona sea de tipo socio
*/
delimiter %%
create trigger tgr_insert_socio before insert on Socio
for each row
begin 
    select tipo into @tipo_persona from Persona where persona_id = new.persona_id;
    if @tipo_persona <> 'socio' then
		signal sqlstate '45000' set message_text = 'La persona no está registrada como socio';
	end if;
end;
%%
delimiter ;

/*
	TRIGGER tgr_insert_empleado que válida que una persona sea de tipo empleado
*/
delimiter %%
create trigger tgr_insert_empleado before insert on Empleado
for each row
begin 
	select tipo into @tipo_persona from Persona where persona_id = new.persona_id;
    if @tipo_persona <> 'empleado' then
		signal sqlstate '45000' set message_text = 'La persona no está registrada como empleado';
	end if;
end;
%%
delimiter ;

create table if not exists Producto(
	producto_id int primary key auto_increment,
    nombre varchar(255) not null unique,
    precio float not null,
    stock int,
    constraint chk_precio check (precio > 0)
);

create table if not exists Venta(
	venta_id int primary key auto_increment,
    socio_id int not null,
    fecha date,
    total decimal(10,2),
    constraint fk_socio_id_venta foreign key (socio_id) references Socio(socio_id),
    constraint chk_total check (total > 0)
);

create table if not exists DetalleVenta(
	detalle_id int primary key auto_increment,
	venta_id int not null,
    producto_id int not null,
    cantidad int not null,
    constraint fk_venta_id_detalle foreign key (venta_id) references Venta(venta_id),
    constraint fk_producto_id_detalle foreign key (producto_id) references Producto(producto_id),
    constraint chk_cantidad check (cantidad > 0)
);

create table if not exists Membresia(
	membresia_id int primary key auto_increment,
    socio_id int not null,
    fecha_inicio date not null,
    fecha_fin date,
    tipo enum('básico','estándar','premium'),
    constraint fk_socio_id_membresia foreign key (socio_id) references Socio(socio_id)
);

create table if not exists Pago(
	pago_id int primary key auto_increment,
    monto decimal(10,2) not null,
    fecha_pago date,
    metodo_pago enum('efectivo','débito','crédito','transferencia'),
	membresia_id int not null,
    constraint fk_membresia_id_pago foreign key (membresia_id) references Membresia(membresia_id)
);

create table if not exists Asistencia(
	asistencia_id int primary key auto_increment,
    fecha_asistencia datetime,
    membresia_id int not null,
    constraint fk_membresia_id_asistencia foreign key(membresia_id) references Membresia(membresia_id)
);

create table if not exists Clase(
	clase_id int primary key auto_increment,
    nombre varchar(100) not null,
    descripcion varchar(255),
    empleado_id int,
    constraint fk_empleado_id_clase foreign key(empleado_id) references Empleado(empleado_id)
);

create table if not exists ParticipacionClase (
	participacion_id int primary key auto_increment,
    membresia_id int not null,
    clase_id int not null,
    fecha date,
    foreign key (membresia_id) references Membresia(membresia_id),
    foreign key (clase_id) references Clase(clase_id),
    UNIQUE (membresia_id, clase_id, fecha)
);

create table if not exists Maquina(
	maquina_id int primary key auto_increment,
    nombre varchar(150) not null,
    estado enum('operativa','en mantenimiento','fuera de servicio') not null default 'operativa'
); 

create table if not exists Mantenimiento(
	mantenimiento_id int primary key auto_increment,
	empleado_id int not null,
    maquina_id int not null,
    fecha_mantenimiento date not null,
    observacion varchar(255),
    constraint fk_empleado_mante foreign key (empleado_id) references Empleado(empleado_id),
    constraint fk_maquina_mante foreign key (maquina_id) references Maquina(maquina_id)
);

INSERT INTO Persona(cedula, nombre, apellido, tipo, telefono, correo, fecha_nacimiento)
VALUES 
('0955221963','Miguel','Alvarado','socio','0986883594','joseaalvarado@gmail.com','2000-12-07'),
('0956221834','Ana','Torres','socio','0987551234','anatorres@gmail.com','1998-05-14'),
('0904587921','Carlos','Pérez','socio','0998123456','carlosperez89@gmail.com','1989-11-23'),
('0923456789','María','López','socio','0986234789','maralopez2001@gmail.com','2001-07-09'),
('0945123789','Jorge','Castillo','socio','0995342871','jorgecastillo95@gmail.com','1995-02-28'),
('0967821345','Sofía','Herrera','socio','0989543217','sofiaherrera@gmail.com','1993-09-17'),
('0956234789','Luis','Ramírez','socio','0996432875','luisramirez87@gmail.com','1987-03-05'),
('0934875123','Paola','Sánchez','empleado','0987684331','paolasanchez@gmail.com','1999-12-15'),
('0956782345','Andrés','Molina','empleado','0998456237','andresmolina@gmail.com','1990-08-21'),
('1300560078','Gabriela','Vargas','empleado','0985123764','gabrielavgs@gmail.com','2002-04-12'),
('0987654321', 'Laura', 'Mendoza', 'empleado', '0995765432', 'lauramendoza@gmail.com', '1992-06-20'),
('0976543210', 'Jorge', 'Valencia', 'empleado', '0986654321', 'jorgevalencia@gmail.com', '1985-11-11');

INSERT INTO Socio (persona_id, ciudad, calle_principal, numero_residencia) VALUES
(1, 'Guayaquil', 'Av. 9 de Octubre', '102'),
(2, 'Guayaquil', 'Av. Francisco de Orellana', '230'),
(3, 'Durán', 'Calle Loja', '54'),
(4, 'Guayaquil', 'Av. del Bombero', '85'),
(5, 'Samborondón', 'Via La Puntilla', 'C4'),
(6, 'Guayaquil', 'Av. Pedro Menéndez', '12'),
(7, 'Guayaquil', 'Av. Quito', '94');

INSERT INTO Empleado (persona_id, estado, tipo, fecha_contratacion, salario, supervisor_id) VALUES
(8, 'activo', 'instructor', '2021-01-15', 600.00, NULL),
(9, 'activo', 'técnico', '2020-09-20', 550.00, NULL),
(10, 'activo', 'recepcionista', '2022-05-01', 650.00, NULL),
(11, 'activo', 'instructor', '2022-05-01', 500.00, NULL),
(12, 'activo', 'recepcionista', '2022-04-01', 450.00, NULL);

INSERT INTO ObjetivoEntrenamiento (socio_id, descripcion) VALUES
(1, 'Perder 5kg en 3 meses'),
(2, 'Aumentar masa muscular'),
(3, 'Mejorar resistencia cardiovascular'),
(4, 'Recuperación de rodilla'),
(5, 'Preparación para maratón'),
(6, 'Aumentar masa muscular'),
(7, 'Mejorar flexibilida');

INSERT INTO HorarioLaboral (empleado_id, hora_inicio, hora_fin) VALUES
(1, '2025-08-10 08:00:00', '2025-08-10 14:00:00'),
(2, '2025-08-10 14:00:00', '2025-08-10 18:00:00'),
(3, '2025-08-10 08:00:00', '2025-08-10 14:00:00'),
(4, '2025-08-10 14:00:00', '2025-08-10 20:00:00'),
(5, '2025-08-10 14:00:00', '2025-08-10 20:00:00');

INSERT INTO Producto (nombre, precio, stock) VALUES
('Proteína Whey', 35.50, 20),
('Guantes de Gimnasio', 15.00, 50),
('Botella de Agua 1L', 3.00, 100),
('Toalla Deportiva', 8.00, 40),
('Creatina Monohidratada', 25.00, 30);

INSERT INTO Venta (socio_id, fecha, total) VALUES
(1, '2025-08-01', 50.50),
(2, '2025-08-02', 35.00),
(3, '2025-08-03', 40.00),
(4, '2025-08-04', 75.00),
(5, '2025-08-05', 28.00);

INSERT INTO DetalleVenta (venta_id, producto_id, cantidad) VALUES
(1, 1, 1),
(1, 3, 5),
(2, 2, 1),
(3, 4, 2),
(4, 5, 3);

INSERT INTO Membresia (socio_id, fecha_inicio, fecha_fin, tipo) VALUES
(1, '2025-01-01', '2025-12-31', 'premium'),
(2, '2025-03-01', '2025-08-31', 'estándar'),
(3, '2025-05-15', '2025-11-15', 'básico'),
(4, '2025-07-01', '2025-12-31', 'premium'),
(5, '2025-02-01', '2025-08-01', 'básico');

INSERT INTO Pago (monto, fecha_pago, metodo_pago, membresia_id) VALUES
(60.00, '2025-01-01', 'efectivo', 1),
(45.00, '2025-03-01', 'débito', 2),
(30.00, '2025-05-15', 'transferencia', 3),
(60.00, '2025-07-01', 'crédito', 4),
(30.00, '2025-02-01', 'efectivo', 5);

INSERT INTO Asistencia (fecha_asistencia, membresia_id) VALUES
('2025-08-01 07:00:00', 1),
('2025-08-02 08:00:00', 2),
('2025-08-04 07:30:00', 3),
('2025-08-04 09:00:00', 4),
('2025-08-05 08:15:00', 5);

INSERT INTO Clase (nombre, descripcion, empleado_id) VALUES
('Yoga', 'Clase de relajación y estiramiento', 1),
('CrossFit', 'Entrenamiento de alta intensidad', 4),
('Zumba', 'Baile y ejercicio', 1),
('Spinning', 'Ciclismo indoor', 4),
('Entrenamiento Funcional', 'Rutina de fuerza y resistencia', 1);

INSERT INTO ParticipacionClase (membresia_id, clase_id, fecha) VALUES
(1, 1, '2025-08-01'),
(2, 2, '2025-08-02'),
(3, 3, '2025-08-03'),
(4, 4, '2025-08-04'),
(5, 5, '2025-08-05');

INSERT INTO Maquina (nombre, estado) VALUES
('Cinta de correr', 'operativa'),
('Bicicleta estática', 'operativa'),
('Máquina de remo', 'en mantenimiento'),
('Press de banca', 'operativa'),
('Elíptica', 'fuera de servicio');

INSERT INTO Mantenimiento (empleado_id, maquina_id, fecha_mantenimiento, observacion) VALUES
(2, 3, '2025-08-01', 'Revisión de poleas'),
(2, 5, '2025-08-02', 'Cambio de batería'),
(2, 1, '2025-08-03', 'Lubricación de banda'),
(2, 4, '2025-08-04', 'Ajuste de tornillos'),
(2, 2, '2025-08-05', 'Revisión de pedales');
