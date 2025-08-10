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
    nombre varchar(255) not null,
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

INSERT INTO Persona(cedula, nombre, apellido, tipo, telefono, correo, fecha_nacimiento)
VALUES 
('0955221963','Miguel','Alvarado','socio','0986883594','joseaalvarado@gmail.com','2000-12-07'),
('0956221834','Ana','Torres','socio','0987551234','anatorres@gmail.com','1998-05-14'),
('0904587921','Carlos','Pérez','socio','0998123456','carlosperez89@gmail.com','1989-11-23'),
('0923456789','María','López','socio','0986234789','maralopez2001@gmail.com','2001-07-09'),
('0945123789','Jorge','Castillo','socio','0995342871','jorgecastillo95@gmail.com','1995-02-28'),
('0967821345','Sofía','Herrera','socio','0989543217','sofiaherrera@gmail.com','1993-09-17'),
('0956234789','Luis','Ramírez','socio','0996432875','luisramirez87@gmail.com','1987-03-05'),
('0934875123','Paola','Sánchez','empleado','0987654321','paolasanchez@gmail.com','1999-12-15'),
('0956782345','Andrés','Molina','empleado','0998456237','andresmolina@gmail.com','1990-08-21'),
('1300560078','Gabriela','Vargas','empleado','0985123764','gabrielavgs@gmail.com','2002-04-12');
