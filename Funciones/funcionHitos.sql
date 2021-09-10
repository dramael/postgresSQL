CREATE OR REPLACE FUNCTION test.hitos () RETURNS TABLE (tabla text, cantidad int) AS $func$
BEGIN
EXECUTE ('
	update capas_gral.hitos set nombre = upper (nombre) where fechamod::date = ''today'';
	update capas_gral.hitos set back = upper (nombre) where back is null and fechamod::date = ''today'';
	update capas_gral.hitos set tipo = upper (tipo)where tipo is null and fechamod::date = ''today'';
	update capas_gral.hitos set observacio = upper (observacio)where observacio is null and fechamod::date = ''today'';
	update capas_gral.hitos set direccion = upper (direccion)where direccion is null and fechamod::date = ''today'';
	update capas_gral.hitos set x = st_x(geom) where fechamod::date = ''today'';
	update capas_gral.hitos set y = st_y (geom) where fechamod::date = ''today'';
	update capas_gral.hitos set etiqueta = upper (etiqueta) where etiqueta is null and fechamod::date = ''today'';
	UPDATE capas_gral.hitos set borrado = 0 where borrado is null and fechamod::date = ''today'';
	update capas_gral.hitos a set provincia = b. provincia
	from capas_gral.provincia b
	where st_within (a.geom, st_transform(b.geom,4326)) and a.provincia is null and a.fechamod::date = ''today'';
	update capas_gral.hitos a set partido = b. partido
	from capas_gral.localidades b
	where st_within (a.geom, st_transform(b.geom,4326)) and a.partido is null and a.fechamod::date = ''today'';
	update capas_gral.hitos a set partido = b. partido
	from capas_gral.departamento b
	where st_within (a.geom, st_transform(b.geom,4326)) and a.partido is null and a.fechamod::date = ''today'';
	update capas_gral.hitos set localidad = null where fechamod::date = ''today'' and  localidad like ''%ZONA RURAL%'';
	update capas_gral.hitos set nombre = ''S/D'' WHERE nombre IS NULL	and  fechamod::date = ''today'';
	update capas_gral.hitos set direccion = ''S/D'' WHERE direccion IS NULL	and  fechamod::date = ''today'';
	update capas_gral.hitos set observacio = ''S/D'' WHERE observacio IS NULL	and  fechamod::date = ''today'';
	update capas_gral.hitos set telefono = ''S/D'' WHERE telefono IS NULL	and  fechamod::date = ''today'';
	update capas_gral.hitos a set localidad = b.localidad
	from capas_gral.localidades b
	where st_within (a.geom, st_transform(b.geom,4326)) and a.fechamod::date = ''today'' and a.localidad is null;
	update capas_gral.hitos a set barrio = b.nombre
	from capas_gral.barrios b
	where st_within (a.geom, b.geom) and a.barrio is null and a.fechamod::date = ''today'';
	update capas_gral.hitos  set tipo = upper (tipo) where fechamod::date = ''today'';
	update capas_gral.hitos  set localidad = upper (localidad) where fechamod::date = ''today'';
	update capas_gral.hitos set nombre = trim(nombre) where fechamod::date = ''today'';
	update capas_gral.hitos set direccion = trim(initcap(direccion)) where fechamod::date = ''today'';									  
	update capas_gral.hitos set localidad = concat (partido,'' (ZONA RURAL)'') where fechamod::date = ''today'' and localidad is null;
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''Á'',''A'')				where nombre like ''%Á%''  and fechamod::date = ''today''; 			
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''É'',''E'')				where nombre like ''%É%'' and fechamod::date = ''today''; 		
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''Í'',''I'')				where nombre like ''%Í%''and fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''Ó'',''O'')				where  nombre like ''%Ó%''and fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''Ü'',''U'')				where nombre like ''%Ü%''and fechamod::date = ''today'';  
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''Ú'',''U'')				where nombre like ''%Ú%''and fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''"'','' '')				where nombre like ''%"%''and fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''  '','' '')				where nombre like ''%  %''and fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''CAPITAN'',''CAP'')		where  nombre like ''%CAPITAN%''and fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''GENERAL'',''GRAL'')		where nombre like ''%GENERAL%'' and fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''PRESIDENTE'',''PRES'')	where nombre like ''%PRESIDENTE%''and  fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''TENIENTE'',''TTE'')		where nombre like ''%TENIENTE%'' and fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''º'','''')				where nombre like ''%º%''and  fechamod::date = ''today''; 
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''*'','''')				where nombre like ''%*%'' and fechamod::date = ''today'';
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''+'','''')				where nombre like ''%+%''and fechamod::date = ''today'';
	update capas_gral.hitos set NOMBRE = replace(NOMBRE , ''°'','''')				where nombre like ''%°%''and  fechamod::date = ''today''; 
	update capas_gral.hitos_pol a set borrado = 0 where borrado is null and fechamod::date = ''today'';
	update capas_gral.hitos_pol a set nombre = upper(nombre) where fechamod::date = ''today'';
	update capas_gral.hitos_pol a set direccion = upper(direccion) where fechamod::date = ''today'';
	update capas_gral.hitos_pol a set x = st_x(st_centroid(geom)) where x is null and fechamod::date = ''today'';
	update capas_gral.hitos_pol a set y = st_y(st_centroid(geom)) where y is null and fechamod::date = ''today'';
	update capas_gral.hitos_pol set back = upper (nombre) where back is null and fechamod::date = ''today'';
	update capas_gral.hitos_pol a set provincia = b. provincia
	from capas_gral.provincia b
	where st_within (a.geom, st_transform(b.geom,4326)) and a.provincia is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_pol a set partido = b. partido
	from capas_gral.localidades b
	where st_within (st_centroid(a.geom), st_transform(b.geom,4326)) and a.partido is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_pol a set partido = b. partido
	from capas_gral.departamento b
	where st_within (st_centroid(a.geom), st_transform(b.geom,4326)) and a.partido is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_pol a set localidad = b.localidad
	from capas_gral.localidades b
	where st_within (st_centroid(a.geom), st_transform(b.geom,4326)) and a.localidad is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_pol a set barrio = b.nombre
	from capas_gral.barrios b
	where st_within (st_centroid(a.geom), b.geom) and a.barrio is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_pol set nombre = trim(nombre) where fechamod::date = ''today'';
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''Á'',''A'')				where nombre like ''%Á%''  and fechamod::date = ''today''; 			
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''É'',''E'')				where nombre like ''%É%'' and fechamod::date = ''today''; 		
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''Í'',''I'')				where nombre like ''%Í%''and fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''Ó'',''O'')				where  nombre like ''%Ó%''and fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''Ü'',''U'')				where nombre like ''%Ü%''and fechamod::date = ''today'';  
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''Ú'',''U'')				where nombre like ''%Ú%''and fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''"'','' '')				where nombre like ''%"%''and fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''  '','' '')				where nombre like ''%  %''and fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''CAPITAN'',''CAP'')		where  nombre like ''%CAPITAN%''and fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''GENERAL'',''GRAL'')		where nombre like ''%GENERAL%'' and fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''PRESIDENTE'',''PRES'')	where nombre like ''%PRESIDENTE%''and  fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''TENIENTE'',''TTE'')		where nombre like ''%TENIENTE%'' and fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''º'','''')				where nombre like ''%º%''and  fechamod::date = ''today''; 
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''*'','''')				where nombre like ''%*%'' and fechamod::date = ''today'';
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''+'','''')				where nombre like ''%+%''and fechamod::date = ''today'';
	update capas_gral.hitos_pol set NOMBRE = replace(NOMBRE , ''°'','''')				where nombre like ''%°%''and  fechamod::date = ''today''; 

	update capas_gral.hitos set nombre=translate(nombre,''ÖË'',''OE'')  where nombre like any (array[''%Ö%'',''%Ë%'']) and  fechamod::date = ''today'';
	update capas_gral.hitos_linea set nombre=translate(nombre,''ÖË'',''OE'')  where nombre like any (array[''%Ö%'',''%Ë%'']) and  fechamod::date = ''today'';
	update capas_gral.hitos_pol set nombre=translate(nombre,''ÖË'',''OE'')  where nombre like any (array[''%Ö%'',''%Ë%'']) and  fechamod::date = ''today'';


	update capas_gral.hitos_linea a set borrado = 0 where borrado is null and fechamod::date = ''today'';
	update capas_gral.hitos_linea a set nombre = upper(nombre) where fechamod::date = ''today'';
	update capas_gral.hitos_linea a set direccion = upper(direccion) where fechamod::date = ''today'';
	update capas_gral.hitos_linea a set x = st_x(st_centroid(geom)) where x is null and fechamod::date = ''today'';
	update capas_gral.hitos_linea a set y = st_y(st_centroid(geom)) where y is null and fechamod::date = ''today'';
	update capas_gral.hitos_linea set back = upper (nombre) where back is null and fechamod::date = ''today'';
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''Á'',''A'')				where nombre like ''%Á%''  and fechamod::date = ''today''; 			
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''É'',''E'')				where nombre like ''%É%'' and fechamod::date = ''today''; 		
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''Í'',''I'')				where nombre like ''%Í%''and fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''Ó'',''O'')				where  nombre like ''%Ó%''and fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''Ü'',''U'')				where nombre like ''%Ü%''and fechamod::date = ''today'';  
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''Ú'',''U'')				where nombre like ''%Ú%''and fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''"'','' '')				where nombre like ''%"%''and fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''  '','' '')				where nombre like ''%  %''and fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''CAPITAN'',''CAP'')		where  nombre like ''%CAPITAN%''and fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''GENERAL'',''GRAL'')		where nombre like ''%GENERAL%'' and fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''PRESIDENTE'',''PRES'')	where nombre like ''%PRESIDENTE%''and  fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''TENIENTE'',''TTE'')		where nombre like ''%TENIENTE%'' and fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''º'','''')				where nombre like ''%º%''and  fechamod::date = ''today''; 
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''*'','''')				where nombre like ''%*%'' and fechamod::date = ''today'';
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''+'','''')				where nombre like ''%+%''and fechamod::date = ''today'';
	update capas_gral.hitos_linea set NOMBRE = replace(NOMBRE , ''°'','''')				where nombre like ''%°%''and  fechamod::date = ''today''; 
	update capas_gral.hitos_linea a set provincia = b. provincia
	from capas_gral.provincia b
	where st_within (a.geom, st_transform(b.geom,4326)) and a.provincia is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_linea a set partido = b. partido
	from capas_gral.localidades b
	where st_within (st_centroid(a.geom), st_transform(b.geom,4326)) and a.partido is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_linea a set partido = b. partido
	from capas_gral.departamento b
	where st_within (st_centroid(a.geom), st_transform(b.geom,4326)) and a.partido is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_linea a set localidad = b.localidad
	from capas_gral.localidades b
	where st_within (st_centroid(a.geom), st_transform(b.geom,4326)) and a.localidad is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_linea a set barrio = b.nombre
	from capas_gral.barrios b
	where st_within (st_centroid(a.geom), b.geom) and a.barrio is null and a.fechamod::date = ''today'';
	update capas_gral.hitos_linea set nombre = trim(nombre) where fechamod::date = ''today'';
	insert into _backup.hitos (id_hito, tabla, wkt, nombre, direccion, telefono, tipo, observacio, provincia, partido, localidad, x, y,   borrado)
	SELECT id as id_hito,''hitos_pol''::text as tabla, st_astext(geom)::text as wkt, nombre, direccion, telefono, tipo, 
	observacio, provincia, partido, localidad, x, y,borrado
		FROM capas_gral.hitos_pol where fechamod::date = ''today''; 
	insert into _backup.hitos (id_hito, tabla, wkt, nombre, direccion, telefono, tipo, observacio, provincia, partido, localidad, x, y,   borrado)
	SELECT id as id_hito,''hitos_linea''::text as tabla, st_astext(geom)::text as wkt, nombre, direccion, telefono, tipo, 
	observacio, provincia, partido, localidad, x, y,borrado
		FROM capas_gral.hitos_linea where fechamod::date = ''today''; 
	insert into _backup.hitos (id_hito, tabla, wkt, nombre, direccion, telefono, tipo, observacio, provincia, partido, localidad, x, y,   borrado)
		SELECT id as id_hito,''hitos''::text as tabla, st_astext(geom)::text as wkt, nombre, direccion, telefono, tipo, 
	observacio, provincia, partido, localidad, x, y,borrado
		FROM capas_gral.hitos where fechamod::date = ''today'';
	DELETE FROM _backup.hitos A USING _backup.hitos B
	WHERE a.id_hito = b.id_hito and a.tabla = b.tabla and a.pk < b.pk and a.fechamod = b.fechamod;');
RETURN query execute (
	'select concat(a.fechamod::date, '' Hitos'')::text, count (a.fechamod::date)::int
	from
	capas_gral.hitos a
	group by a.fechamod::date
	having  count (fechamod::date) < 20000
	union 
	select concat(a.fechamod::date, '' Poligonos'')::text, count (a.fechamod::date)::int
	from
	capas_gral.hitos_pol a
	group by a.fechamod::date
	having  count (fechamod::date) < 20000
	UNION
	select concat(a.fechamod::date, '' Lineas'')::text, count (a.fechamod::date)::int
	from
	capas_gral.hitos_linea a
	group by a.fechamod::date
	having  count (fechamod::date) < 20000
	order by 1 desc');
END
$func$ LANGUAGE plpgsql;

