--PRIMER EXPERIMENTO: Crisis Maltusiana sobre la Madera

insert into escenario (nombre, descripcion, hipotesis) values
('Crisis de la Madera 2026 - 2100',
'Evaluación de la masa forestal bajo demanda industrial constante, ligada a piblación y consumo per cápita',
'Si la deforestación anual supera la capacidad de regeneración natural, la cobertura forestal colapsa antes de 2080');

insert into variable (id_sector, nombre, unidad_medida) values 
(1, 'Poblacion Total', 'Habitantes'),
(2, 'Cobertura Forestal Disponible', 'Fracción (0.0 a 1.0)'),
(3, 'Consumo de Madera por Persona', 'Ton/Hab/Año'),
(2, 'Tasa de Reforestacion Natural', 'Fraccion Anual');

insert into parametro_ve (id_escenario, id_variable, valor_inicial) values
(1, 1, 8200000000.0000),
(1, 2, 0.3000),
(1, 3, 0.5000),
(1, 4, 0.0200);

select exec_simulacion(1, 2026, 2100);

select d.anio, v.nombre as variable, d.valor, v.unidad_medida from dato_proyectado d
join variable v on d.id_variable = v.id_variable where d.id_simulacion = 1
order by d.anio, v.id_variable;