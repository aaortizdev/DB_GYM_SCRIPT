drop database if exists Gimnasio;

create database if not exists Gimnasio;
use Gimnasio;

create table if not exists Persona(
	id_persona int primary key auto_increment,
    cedula varchar(10) not null UNIQUE,
    nombre varchar(100) not null,
    apellido varchar(100) not null,
    telefono varchar(15) UNIQUE,
    correo varchar(150) UNIQUE,
    fecha_nacimiento date,
    
    constraint chk_cedula_length check (CHAR_LENGTH(cedula) = 10),
    constraint chk_cedula_numerica check (cedula regexp('^[0-9]+$')),
    constraint chk_correo_formato check (correo Like '%@%.%')
);

insert into Persona(cedula,nombre,apellido,telefono,correo,fecha_nacimiento)
values ('0955221963','Miguel','Alvarado','0986883594','joseaalvarado@gmail.com','2000-12-07'),
('0956221834','Ana','Torres','0987551234','anatorres@gmail.com','1998-05-14'),
('0904587921','Carlos','Pérez','0998123456','carlosperez89@gmail.com','1989-11-23'),
('0923456789','María','López','0986234789','maralopez2001@gmail.com','2001-07-09'),
('0945123789','Jorge','Castillo','0995342871','jorgecastillo95@gmail.com','1995-02-28'),
('0967821345','Sofía','Herrera','0989543217','sofiaherrera@gmail.com','1993-09-17'),
('0956234789','Luis','Ramírez','0996432875','luisramirez87@gmail.com','1987-03-05'),
('0934875123','Paola','Sánchez','0987654321','paolasanchez@gmail.com','1999-12-15'),
('0956782345','Andrés','Molina','0998456237','andresmolina@gmail.com','1990-08-21'),
('1300560078','Gabriela','Vargas','0985123764','gabrielavgs@gmail.com','2002-04-12');
