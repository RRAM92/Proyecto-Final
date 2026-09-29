--CREAR SECTORES
insert into sector (nombre, descripcion) values
('Población', 'Dinámica demográfica mundial'),
('Recursos Naturales', 'Disponibilidad y agotamiento de recursos no renovables y biomasa'),
('Sistema Industrial', 'Inversión, producción y consumo de materiales'),
('Sistema Agrícola', 'Producción de alimentos y uso del suelo'),
('Contaminación', 'Generación de residuos y su impacto ambiental');

--FUNCIÓN DE SIMULACIÓN
create or replace function exec_simulacion(p_id_escenario int, p_year_inicio int, p_year_fin int)
returns int as $$
declare v_id_simulacion int; v_anio int;
begin
	insert into simulacion (id_escenario, year_inicio, year_fin)
	values (p_id_escenario, p_year_inicio, p_year_fin)
	returning id_simulacion into v_id_simulacion;

	create temp table if not exists estado_actual(id_variable int primary key, valor numeric(30,10)) on commit drop;
	create temp table if not exists estado_nuevo(id_variable int primary key, valor numeric(30,10)) on commit drop;

	delete from estado_actual;
	insert into estado_actual(id_variable, valor)
	select id_variable, valor_inicial from parametro_ve where id_escenario = p_id_escenario;

	for v_anio in p_year_inicio..p_year_fin loop
		--I. Registrar Estado del Año Actual
		insert into dato_proyectado(id_simulacion, id_variable, anio, valor)
		select v_id_simulacion, id_variable, v_anio, valor from estado_actual;

		--II. Arrancar el siguiente estado igual al actual
		delete from estado_nuevo;
		insert into estado_nuevo select * from estado_actual;

		--III. Aplicar flujos causales
		update estado_nuevo en set valor = greatest(0, en.valor + flujo.neto)
		from (select rc.id_variable_afectada, sum(
			(case when rc.tipo = 'input' then 1 else -1 end)
			*rc.coeficiente * ea1.valor * coalesce(ea2.valor, 1) * (case when rc.tiene_nv_propio then ea0.valor else 1 end)
		) as neto
		from relacion_causal rc
		join estado_actual ea1 on ea1.id_variable = rc.id_variable_influyente
		left join estado_actual ea2 on ea2.id_variable = rc.id_variable_influyente_2
		join estado_actual ea0 on ea0.id_variable = rc.id_variable_afectada
		group by rc.id_variable_afectada) flujo
		where en.id_variable = flujo.id_variable_afectada;

		--IV. Aplicar techo opcional (variable.valor_max)
		update estado_nuevo en set valor = least(en.valor, v.valor_max)
		from variable v where en.id_variable = v.id_variable and v.valor_max is not null;

		--V. Aplicar modificadores por umbral
		update estado_nuevo en set valor = greatest(0, en.valor + ea.valor * tl.tasa) from tabla_lookup tl
		join estado_actual ea on ea.id_variable = tl.id_variable_nv
		join estado_actual cond on cond.id_variable = tl.id_variable_con
		where en.id_variable = tl.id_variable_nv
		and (tl.umbral_max is null or cond.valor < tl.umbral_max) and tl.orden = (
			select min(tl2.orden) from tabla_lookup tl2
			join estado_actual cond2 on cond2.id_variable = tl2.id_variable_con
			where tl2.id_variable_nv = tl.id_variable_nv
			and (tl2.umbral_max is null or cond2.valor < tl2.umbral_max)
		);

		--VI. Recalcular variables auxiliares a partir del estado YA actualizado
		update estado_nuevo en set valor = ra.coeficiente * base.valor
		from relacion_auxiliar ra join estado_nuevo base on base.id_variable = ra.id_variable_base
		where en.id_variable = ra.id_variable_auxiliar;

		--VII. Avanzar: estado_actual <- estado_nuevo
		delete from estado_actual;
		insert into estado_actual select * from estado_nuevo;

	end loop;
	return v_id_simulacion;
end;
$$ language plpgsql;