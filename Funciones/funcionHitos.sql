-- FUNCTION: capas_gral.hitos()

-- DROP FUNCTION capas_gral.hitos();

CREATE OR REPLACE FUNCTION capas_gral.hitos(
	)
    RETURNS TABLE(tabla text, cantidad integer) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE 

tabla text; 

BEGIN

FOR tabla IN
	
	SELECT tablename FROM pg_catalog.pg_tables where schemaname='capas_gral' and tablename like 'hitos%' 
	
	LOOP
	
	EXECUTE ('
			 update capas_gral.'||tabla||' set nombre = trim(upper(nombre)) 						where fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set nombre = ''S/D'' 									where nombre is null and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set nombre = translate(nombre, ''ÁÉÍÓÚ'',''AEIOU'')      where nombre like any (array[''%Á%'',''%É%'',''%Í%'',''%Ó%'',''%Ú%'']) and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set nombre = translate(nombre,''ÖË'',''OE'')  			where nombre like any (array[''%Ö%'',''%Ë%'']) and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''"'','' '')				where nombre like ''%"%''and fechamod::date = ''today''; 
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''CAPITAN'',''CAP'')		where nombre like ''%CAPITAN%''and fechamod::date = ''today''; 
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''GENERAL'',''GRAL'')		where nombre like ''%GENERAL%'' and fechamod::date = ''today''; 
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''PRESIDENTE'',''PRES'')	where nombre like ''%PRESIDENTE%''and  fechamod::date = ''today''; 
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''TENIENTE'',''TTE'')		where nombre like ''%TENIENTE%'' and fechamod::date = ''today''; 
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''º'','''')				where nombre like ''%º%''and  fechamod::date = ''today''; 
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''*'','''')				where nombre like ''%*%'' and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''+'','''')				where nombre like ''%+%''and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''°'','''')				where nombre like ''%°%''and  fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set nombre = replace(nombre , ''  '','' '')				where nombre like ''%  %''and fechamod::date = ''today'';
			 
			 update capas_gral.'||tabla||' set back = nombre	  	 								    where fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set tipo = upper(tipo) 									    where tipo is not null and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set observacion = trim(upper(observacion)) 					where observacion is not null and fechamod::date = ''today'';
 			 update capas_gral.'||tabla||' set observacion = translate(observacion,''ÁÉÍÓÚ'',''AEIOU'') where observacion like any (array[''%Á%'',''%É%'',''%Í%'',''%Ó%'',''%Ú%'']) and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set observacion = replace(observacion , ''  '','' '')		where observacion like ''%  %''and fechamod::date = ''today'';		 
			 update capas_gral.'||tabla||' set observacion = ''S/D''  									where observacion is null and fechamod::date = ''today'';
		     update capas_gral.'||tabla||' set direccion = trim(initcap(direccion)) 					where fechamod::date = ''today'';
 			 update capas_gral.'||tabla||' set direccion = initcap(translate(upper(direccion),''ÁÉÍÓÚ'',''AEIOU'')) 
			 where direccion like any (array[''%Á%'',''%É%'',''%Í%'',''%Ó%'',''%Ú%'']) and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set direccion = replace(direccion , ''  '','' '')			where direccion like ''%  %''and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set direccion = ''S/D'' 										where direccion is null and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set etiqueta = upper(etiqueta) 								where etiqueta is not null and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set borrado = 0 												where borrado is null and fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set telefono = ''S/D'' 										where telefono is null and fechamod::date = ''today'';
			 
			 update capas_gral.'||tabla||' a set pais = b. pais
		     from capas_gral.pais b
	         where st_within (st_centroid(a.geom), b.geom) and a.pais is null and a.fechamod::date = ''today'';
			 
			 update capas_gral.'||tabla||' a set provincia = b. provincia
		     from capas_gral.provincias b
	         where st_within (st_centroid(a.geom), b.geom) and a.provincia is null and a.fechamod::date = ''today'';
			 
			 update capas_gral.'||tabla||' a set partido = b. partido
		     from capas_gral.localidades b
	         where st_within (st_centroid(a.geom), b.geom) and a.partido is null and a.fechamod::date = ''today'';
			 update capas_gral.'||tabla||' a set partido = b. partido
		     from capas_gral.partidos b
			 where st_within (st_centroid(a.geom), b.geom) and a.partido is null and a.fechamod::date = ''today'';
			 
			 update capas_gral.'||tabla||' set localidad = null where fechamod::date = ''today'' and  localidad like ''%ZONA RURAL%'';
			 update capas_gral.'||tabla||' a set localidad = b.localidad
		     from capas_gral.localidades b
		     where st_within (st_centroid(a.geom), b.geom) and a.fechamod::date = ''today'' and a.localidad is null;
			 update capas_gral.'||tabla||' set localidad = upper (localidad) where fechamod::date = ''today'';
			 update capas_gral.'||tabla||' set localidad = concat (partido,'' (ZONA RURAL)'') where fechamod::date = ''today'' and localidad is null;
			 
			 update capas_gral.'||tabla||' a set barrio = b.nombre
		 	 from capas_gral.barrios b
			 where st_within (st_centroid(a.geom), b.geom) and a.barrio is null and a.fechamod::date = ''today'';
			 
			 insert into _backup.hitos (id_hito, tabla, wkt, nombre, direccion, telefono, tipo, observacion, provincia, partido, localidad, borrado)
			 select id as id_hito,'''||tabla||'''::text as tabla, st_astext(geom)::text as wkt, nombre, direccion, telefono, tipo, 
	 		 observacion, provincia, partido, localidad,borrado
			 FROM capas_gral.'||tabla||' where fechamod::date = ''today''; 
			 
			 delete from _backup.hitos A using _backup.hitos B
		     where a.id_hito = b.id_hito and a.tabla = b.tabla and a.pk < b.pk and a.fechamod = b.fechamod;
			 ');
		
	END LOOP;
			 
RETURN QUERY EXECUTE (
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
	 union
	 select concat(a.fechamod::date, '' Lineas'')::text, count (a.fechamod::date)::int
	 from
	 capas_gral.hitos_linea a
	 group by a.fechamod::date
	 having  count (fechamod::date) < 20000
	 order by 1 desc');
	
END
$BODY$;

ALTER FUNCTION capas_gral.hitos()
    OWNER TO nahuel;
