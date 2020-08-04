CREATE OR REPLACE FUNCTION _mysql.importador(tabla varchar(30)) RETURNS TABLE (cantidad int ) AS $func$
BEGIN
EXECUTE (

'
TRUNCATE TABLE _MYSQL.pais restart identity;
TRUNCATE TABLE _mysql.provincia restart identity;
truncate table _mysql.departamento restart identity;
truncate table _mysql.localidad restart identity;

create table if not exists _mysql.pais
(pais_id int, pais_descripcion text, pais_fecha_actualizacion text, pais_habilitado int, wkt text);

INSERT INTO _MYSQL.pais (wkt, PAIS_ID,PAIS_DESCRIPCION,PAIS_FECHA_ACTUALIZACION, PAIS_HABILITADO)
select 	st_astext(GEOM), ''1'',NOMBRE,FECHAMOD,''1'' from capas_gral.hitos_pol where tipo = ''PAIS'';

create table if not exists _mysql.provincia 
(prov_id int, prov_pais_id int, prov_descripcion text, prov_fecha_actualizacion text, wkt text);

INSERT INTO _MYSQL.PROVINCIA (PROV_ID, PROV_DESCRIPCION,prov_fecha_actualizacion,wkt)
SELECT IDSOFLEX_PROV::INT,PROVINCIA,FECHAMOD,st_Astext(SIMPLE) FROM CAPAS_GRAL.PROVINCIA ORDER BY IDSOFLEX_PROV;

create table if not exists _mysql.departamento
(depar_id int, depar_prov_id int, depar_descripcion text,depar_fecha_actualizacion text, depar_habilitado int, depar_archivo_dbf text, depar_fecha_archivo_dbf text, wkt text);

insert into _mysql.departamento 
(depar_id,depar_descripcion, depar_fecha_actualizacion,depar_habilitado,depar_archivo_dbf,wkt)
select idsoflex_prov::int*10000+idsoflex_dpto::int, partido,fechamod,''1'',shp, st_astext(simple) from capas_Gral.departamento where provincia = '''||tabla||''';

create table if not exists _mysql.localidad
(loca_id int, loca_depar_id int, loca_descripcion text, loca_fecha_actualizacion text, loca_habilitado int, loca_archivo_dbf text, loca_fecha_archivo_dbf text, wkt text);

insert into _mysql.localidad (loca_id,loca_descripcion,loca_fecha_actualizacion,loca_habilitado, wkt)
SELECT idsoflex_local::int,localidad,fechamod,''1'',st_astext(simple) FROM CAPAS_gRAL.LOCALIDADES WHERE PROVINCIA = '''||tabla||''' and localidad not like ''%ZONA RURAL%'' and idsoflex_local is not null
ORDER BY idsoflex_local ASC;

create table if not exists _mysql.archivosdbf 
(arch_id int, arch_nombre text, arch_fecha_modificacion text,arch_fecha_actualizacion text, wkt text );

-- actualiza el valor de pais en provncia
update _mysql.provincia set prov_pais_id = 1;

-- actualiza el valor de depar_prov_id en departamento
update _mysql.departamento a set depar_prov_id = prov_id
from  
(select depar_id,prov_id from _mysql.departamento a
inner join _mysql.provincia b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)), st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.depar_id = b.depar_id;

-- Realiza el update de departamento id y dbf en localidades
update _mysql.localidad a set loca_depar_id = b.depar_id, loca_archivo_dbf = b.depar_archivo_dbf
from (select loca_id, depar_id,depar_archivo_dbf from _mysql.localidad a
inner join _mysql.departamento b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)), st_setsrid(st_geomfromtext(b.wkt),4326)))b
where a.loca_id = b.loca_id;

-- Realiza el update de localidad id y lo normaliza
update _mysql.localidad a set  loca_id = b.loca_id+ depar_prov_id*10000
from
(select loca_id,depar_prov_id from _mysql.localidad a
inner join _mysql.departamento b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)), st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.loca_id = b.loca_id;

-- actualiza los valor de departamento en calles
update _mysql.calles a  set call_Depar_id = b.loca_depar_id
from
(select call_id,b.loca_depar_id from _mysql.calles a
inner join _mysql.localidad b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)), st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.call_id = b.call_id;

-- actualiza los valores de provincia en calle
update _mysql.calles a set call_prov_id = b.prov_id
from (
select call_id,b.prov_id from _mysql.calles a
inner join _mysql.provincia b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.call_id = b.call_id;'

    
);
RETURN query execute ('select count(*)::int as cantidad from _mysql.calles')
;

END
$func$ LANGUAGE plpgsql;