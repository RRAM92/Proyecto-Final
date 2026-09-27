create database faux3;

create table sector(
	id_sector INT generated always as identity primary key,
	nombre VARCHAR(50) not null unique,
	descripcion TEXT
);

create table escenario(
	id_escenario INT generated always as identity primary key,
	nombre VARCHAR(100) not null,
	descripcion TEXT,
	hipotesis TEXT
);

create table variable(
	id_variable INT generated always as identity primary key,
	id_sector INT not null references sector(id_sector),
	nombre VARCHAR(100) not null,
	unidad_medida VARCHAR(30) not null
);

create table parametro_ve(
	id_parametro INT generated always as identity primary key,
	id_escenario INT not null references escenario(id_escenario),
	id_variable INT not null references variable(id_variable),
	valor_inicial NUMERIC(15,4) not null,
	constraint uq_escenario_variable unique (id_escenario, id_variable)
);

create table simulacion(
	id_simulacion INT generated always as identity primary key,
	id_escenario INT not null references escenario(id_escenario),
	fecha_exec TIMESTAMP default current_timestamp,
	year_inicio INT not null check (year_inicio >= 1900),
	year_fin INT not null check (year_fin <= 2100),
	constraint chk_rango_years check (year_fin > year_inicio)
);

create table dato_proyectado(
	id_dato INT generated always as identity primary key,
	id_simulacion INT not null references simulacion(id_simulacion),
	id_variable INT not null references variable(id_variable),
	anio INT not null check (anio between 1900 and 2100),
	constraint uq_simulacion_variable_year unique (id_simulacion, id_variable, anio)
);

select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name desc;

alter table dato_proyectado add column valor numeric(18,4) not null;