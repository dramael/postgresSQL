CREATE OR REPLACE FUNCTION _mysql.importador_calles() RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (

'


update _mysql.calles set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.callesalturas set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326))where geom is null;


CREATE INDEX IF NOT EXISTS GEOMCALLES   ON 	_mysql.calles 					USING GIST (GEOM);
CREATE INDEX IF NOT EXISTS GEOMALTURAS  ON 	_mysql.callesalturas 			USING GIST (GEOM);
CREATE INDEX IF NOT EXISTS GEOMINTER1   ON 	_mysql.callesintersecciones2 	USING GIST (GEOM1);
CREATE INDEX IF NOT EXISTS GEOMINTER2   ON 	_mysql.callesintersecciones2 	USING GIST (GEOM2);


-- actualiza los valor de departamento en calles
update _mysql.calles a  set call_Depar_id = b.loca_depar_id
from
(select call_id,b.loca_depar_id from _mysql.calles a
inner join _mysql.localidad b on st_within (st_centroid(a.geom), b.geom)) b
where a.call_id = b.call_id and call_Depar_id is null;

-- actualiza los valores de provincia en calle
update _mysql.calles a set call_prov_id = b.prov_id
from (
select call_id,b.prov_id from _mysql.calles a
inner join _mysql.provincia b on st_within (st_centroid(a.geom),b.geom)) b
where a.call_id = b.call_id and call_prov_id is null;


-- Actualiza los valores de departamento en callesaltura

update _mysql.callesalturas a set caal_depar_id = depar_id
from (
select caal_id, depar_id from _mysql.callesalturas a
inner join _mysql.departamento b on st_within (st_centroid(a.geom),b.geom)) b
where a.caal_id = b.caal_id and caal_depar_id is null;


update _mysql.calles a  set call_arch_id = b.arch_id
from
(select call_id,b.arch_id from _mysql.calles a
inner join _mysql.archivosdbf b on st_within (st_centroid(a.geom),b.geom)) b
where a.call_id = b.call_id and call_arch_id is null;


update _mysql.callesalturas a  set caal_arch_id = b.arch_id
from
(select caal_id,b.arch_id from _mysql.callesalturas a
inner join _mysql.archivosdbf b on st_within (st_centroid(a.geom),b.geom)) b
where a.caal_id = b.caal_id and caal_arch_id is null;


update _mysql.callesintersecciones2 a set cain_arch_id = b.arch_id
from (
select cain_id,b.arch_id from _mysql.callesintersecciones2 a
inner join _mysql.archivosdbf b on st_within (geom1,b.geom)) b
where a.cain_id = b.cain_id and cain_arch_id is null;


update _mysql.calles a set call_depar_id = id_dpto
from (select a.call_id, b.idsoflex_dpto::int+(idsoflex_prov::int*1000) id_dpto from _mysql.calles a
inner join capas_gral.departamento  b on st_intersects (a.geom, b.simple)
where call_depar_id is null) b
where a.call_id = b.call_id
and   call_depar_id is null;
 
update _mysql.callesintersecciones2 a set cain_arch_id = b.arch_id
from (
select cain_id,b.arch_id from _mysql.callesintersecciones2 a
inner join _mysql.archivosdbf b on st_within (geom2,b.geom)) b
where a.cain_id = b.cain_id and cain_arch_id = 1 or cain_arch_id is null;



update _mysql.callesintersecciones2 set cain_uid = ''0'' where cain_uid is null;
update _mysql.callesintersecciones2 set cain_fecha_actualizacion = now() where cain_fecha_actualizacion is null;
update _mysql.callesintersecciones2 set cain_tiponumeracion = ''0'';


update _mysql.callesintersecciones2 set cain_latitud1 = st_y(geom1), cain_longitud1 = st_x(geom1), cain_latitud2 = st_y(geom2), cain_longitud2 = st_x(geom2);

update _mysql.callesintersecciones2 set geom3 = st_setsrid(st_makeline(geom1, geom2),4326);

update _mysql.calles set  CALL_ES_ALIAS=0 where call_es_alias is null;
update _mysql.calles set  CALL_ALIAS_DE_CALL_ID=0 where CALL_ALIAS_DE_CALL_ID is null;
update _mysql.calles  set call_tipo = 0;
update _mysql.calles set CALL_FECHA_ACTUALIZACION = now();
update _mysql.calles set CALL_RUTA_NOMBRE = '''' where CALL_RUTA_NOMBRE is null;
update _mysql.calles set CALL_RUTA_TIPO = '''' where CALL_RUTA_TIPO is null ;
update _mysql.calles set CALL_RUTA_DESCRIPCION = '''' where CALL_RUTA_DESCRIPCION is null;
update _mysql.calles set CALL_RUTA_OBSERVACION = '''' where CALL_RUTA_OBSERVACION is null;
update _mysql.callesalturas set CAAL_FECHA_ACTUALIZACION = now();





update _mysql.calles set call_nombre = call_ruta_nombre where call_nombre is null;
update _mysql.calles set call_nombre_org = call_ruta_nombre where call_nombre_org is null;
'


);
RETURN query execute ('select count(*)::int as cantidad from _mysql.calles')
;

END
$func$ LANGUAGE plpgsql;