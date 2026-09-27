--CREAR SECTORES
insert into sector (nombre, descripcion) values
('Población', 'Dinámica demográfica mundial'),
('Recursos Naturales', 'Disponibilidad y agotamiento de recursos no renovables y biomasa'),
('Sistema Industrial', 'Inversión, producción y consumo de materiales'),
('Sistema Agrícola', 'Producción de alimentos y uso del suelo'),
('Contaminación', 'Generación de residuos y su impacto ambiental');

--FUNCIÓN DE SIMULACIÓN
create or replace function exec_simulacion(p_id_escenario INT, p_year_inicio INT, p_year_fin INT)
returns int as $$
declare
	v_id_simulacion INT;
	v_anio INT;
	r_param RECORD;
	v_valor_actual numeric(18,4);
	v_tasa_cambio numeric(18,4);
begin
	--CREAR REGISTRO EN TABLA SIMULACION
	insert into simulacion (id_escenario, year_inicio, year_fin)
	values (p_id_escenario, p_year_inicio, p_year_fin)
	returning id_simulacion into v_id_simulacion;

	--CREAR TABLA TEMPORAL PARA LLEVAR EL ESTADO DINÁMICO DE CADA VARIABLE
	create temp table if not exists estado_actual(
		id_variable int primary key,
		valor numeric(18,4)
	) on commit drop;
	delete from estado_actual; --LIMPIAR POR SI ACASO

	--CARGAR VALORES INICIALES DEL ESCENARIO SELECCIONADO DESDE PARAMETRO_VE
	insert into estado_actual(id_variable, valor)
	select id_variable, valor_inicial from parametro_ve
	where id_escenario = p_id_escenario;

	--BUCLE PARA VISUALIZACIÓN DE RESULTADOS ANUALES
	for v_anio in p_year_inicio..p_year_fin loop
		--GUARDAR ESTADO DEL AÑO ACTUAL EN DATO_PROYECTADO
		insert into dato_proyectado(id_simulacion, id_variable, anio, valor)
		select v_id_simulacion, id_variable, v_anio, valor from estado_actual;
		--MECANISMO MATEMÁTICO
		for r_param in select id_variable, valor from estado_actual loop
			v_valor_actual := r_param.valor;
			--ACTUALIZAR ESTADO EN LA TABLA TEMPORAL (FUTURO = PRESENTE + CAMBIO)
			update estado_actual set valor = case
				when v_valor_actual <= 1.0 and v_valor_actual > 0 then greatest(0, v_valor_actual * 0.98) --SE APLICA REDUCCIÓN O AJUSTE SI EL VALOR ES PEQUEÑO
				else v_valor_actual * 1.01 --SE APLICA CRECIMIENTO O VARIACIÓN SI EL VALOR ES GRANDE
			end
			where id_variable = r_param.id_variable;
		end loop;
	end loop;
	return v_id_simulacion;
end;