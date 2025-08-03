create database if not exists Gimnasio;
use Gimnasio;

create table if not exists Persona(
	id_persona int primary key auto_increment,
    cedula varchar(10) not null UNIQUE,
    nombre varchar(100) not null,
    apellido varchar(100) not null,
    telefono varchar(15),
    correo varchar(150),
    fecha_nacimiento date,
    
    CONSTRAINT chk_cedula_length CHECK (CHAR_LENGTH(cedula) = 10),
    CONSTRAINT chk_correo_formato CHECK (correo LIKE '%@%.%')
);

