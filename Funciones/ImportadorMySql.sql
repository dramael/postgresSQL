CREATE OR REPLACE FUNCTION _mysql.importador_calles(tabla varchar(30)) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (

'


update _mysql.calles set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.callesalturas set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326))where geom is null;
update _mysql.callesintersecciones2 set geom1 = st_setsrid(st_makepoint(cain_latitud1::double precision,cain_longitud1::double precision),4326)
update _mysql.callesintersecciones2 set geom2 = st_setsrid(st_makepoint(cain_latitud2::double precision,cain_longitud2::double precision),4326)


-- actualiza los valor de departamento en calles
update _mysql.calles a  set call_Depar_id = b.loca_depar_id
from
(select call_id,b.loca_depar_id from _mysql.calles a
inner join _mysql.localidad b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)), st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.call_id = b.call_id and call_Depar_id is null;

-- actualiza los valores de provincia en calle
update _mysql.calles a set call_prov_id = b.prov_id
from (
select call_id,b.prov_id from _mysql.calles a
inner join _mysql.provincia b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.call_id = b.call_id and call_prov_id is null;


-- Actualiza los valores de departamento en callesaltura

update _mysql.callesalturas a set caal_depar_id = depar_id
from (
select caal_id, depar_id from _mysql.callesalturas a
inner join _mysql.departamento b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.caal_id = b.caal_id and caal_depar_id is null;


update _mysql.calles a  set call_arch_id = b.arch_id
from
(select call_id,b.arch_id from _mysql.calles a
inner join _mysql.archivosdbf b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),
											  st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.call_id = b.call_id and call_arch_id is null;


update _mysql.callesalturas a  set caal_arch_id = b.arch_id
from
(select caal_id,b.arch_id from _mysql.callesalturas a
inner join _mysql.archivosdbf b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),
											  st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.caal_id = b.caal_id and caal_arch_id is null;


update _mysql.callesintersecciones2 a set cain_arch_id = b.arch_id
from (
select cain_id,b.arch_id from _mysql.callesintersecciones2 a
inner join _mysql.archivosdbf b on st_within
	
	(st_setsrid(st_makepoint(cain_latitud1::double precision,cain_longitud1::double precision),4326),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.cain_id = b.cain_id and cain_arch_id is null;


update _mysql.calles a set call_depar_id = id_dpto
from (select a.call_id, b.idsoflex_dpto::int+(idsoflex_prov::int*1000) id_dpto from _mysql.calles a
inner join capas_gral.departamento  b on st_intersects ((st_setsrid(st_geomfromtext(a.wkt),4326)), b.simple)
where call_depar_id is null) b
where a.call_id = b.call_id
and   call_depar_id is null;
 
update _mysql.callesintersecciones2 a set cain_arch_id = b.arch_id
from (
select cain_id,b.arch_id from _mysql.callesintersecciones2 a
inner join _mysql.archivosdbf b on st_within
	
	(st_setsrid(st_makepoint(cain_latitud2::double precision,cain_longitud2::double precision),4326),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.cain_id = b.cain_id and cain_arch_id = 1 or cain_arch_id is null;


update _mysql.calles set  CALL_ES_ALIAS=0 where call_es_alias is null;
update _mysql.calles set  CALL_ALIAS_DE_CALL_ID=0 where CALL_ALIAS_DE_CALL_ID is null;
update _mysql.calles  set call_tipo = 0;
update _mysql.calles set CALL_FECHA_ACTUALIZACION = now();
update _mysql.calles set CALL_RUTA_NOMBRE = '''';
update _mysql.calles set CALL_RUTA_TIPO = '''';
update _mysql.calles set CALL_RUTA_DESCRIPCION = '''';
update _mysql.calles set CALL_RUTA_OBSERVACION = '''';
update _mysql.callesalturas set CAAL_FECHA_ACTUALIZACION = now();


'


);
RETURN query execute ('select count(*)::int as cantidad from _mysql.calles')
;

END
$func$ LANGUAGE plpgsql;