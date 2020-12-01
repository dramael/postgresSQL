CREATE OR REPLACE FUNCTION _mysql.importador_geometrias(tabla varchar(30)) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (

'

create table if not exists _mysql.pais (pais_id int, pais_descripcion text, pais_fecha_actualizacion text, pais_habilitado int, wkt text);

INSERT INTO _MYSQL.pais (wkt, PAIS_ID,PAIS_DESCRIPCION,PAIS_FECHA_ACTUALIZACION, PAIS_HABILITADO)
select 	st_astext(GEOM), ''1'',NOMBRE,FECHAMOD,''1'' from capas_gral.hitos_pol where tipo = ''PAIS'';



create table if not exists _mysql.provincia 
(prov_id int, prov_pais_id int, prov_descripcion text, prov_fecha_actualizacion text,pais_habilitado int, wkt text);


INSERT INTO _MYSQL.PROVINCIA (PROV_ID,prov_pais_id, PROV_DESCRIPCION,prov_fecha_actualizacion,wkt,pais_habilitado)
SELECT IDSOFLEX_PROV::INT,1,PROVINCIA,FECHAMOD,st_Astext(SIMPLE),1 FROM CAPAS_GRAL.PROVINCIA ORDER BY IDSOFLEX_PROV;



create table if not exists _mysql.departamento
(depar_id int, depar_prov_id int, depar_descripcion text,depar_fecha_actualizacion text, depar_habilitado int, depar_archivo_dbf text, depar_fecha_archivo_dbf text, wkt text);

insert into _mysql.departamento 
(depar_id,depar_descripcion, depar_fecha_actualizacion,depar_habilitado,depar_archivo_dbf,depar_fecha_archivo_dbf,wkt)
select idsoflex_prov::int*1000+idsoflex_dpto::int, partido,fechamod,''1'',shp,now()::timestamp::text, st_astext(simple) from capas_Gral.departamento where provincia = '''||tabla||''';


create table if not exists _mysql.localidad
(loca_id int, loca_depar_id int, loca_descripcion text, loca_fecha_actualizacion text, loca_habilitado int, loca_archivo_dbf text, loca_fecha_archivo_dbf text, wkt text);

insert into _mysql.localidad (loca_id,loca_descripcion,loca_fecha_actualizacion,loca_habilitado,loca_fecha_archivo_dbf, wkt)
SELECT idsoflex_local::int,localidad,fechamod,''1'',now()::timestamp::text,st_astext(simple) FROM CAPAS_gRAL.LOCALIDADES WHERE PROVINCIA = '''||tabla||''' and localidad not like ''%ZONA RURAL%'' and idsoflex_local is not null
ORDER BY idsoflex_local ASC;



create table if not exists _mysql.archivosdbf 
(id int,arch_id int, arch_nombre text, arch_fecha_modificacion text,arch_fecha_actualizacion text, wkt text );

insert into _mysql.archivosdbf
(id, arch_id, arch_nombre, arch_fecha_modificacion,arch_fecha_actualizacion,wkt)
select id,arch_id,partido as arch_nombre,now()::timestamp::text as arch_fecha_modificacion ,now()::timestamp::text as arch_fecha_actualizacion, st_Astext(simple)  from capas_gral.departamento;



update _mysql.archivosdbf set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.departamento set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.localidad set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.pais set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.provincia set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;


-- actualiza el valor de pais en provncia
update _mysql.provincia set prov_pais_id = 1 WHERE prov_pais_id is null;

-- actualiza el valor de depar_prov_id en departamento
update _mysql.departamento a set depar_prov_id = prov_id
from  
(select depar_id,prov_id from _mysql.departamento a
inner join _mysql.provincia b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)), st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.depar_id = b.depar_id and depar_prov_id is null;

-- Realiza el update de departamento id y dbf en localidades
update _mysql.localidad a set loca_depar_id = b.depar_id, loca_archivo_dbf = b.depar_archivo_dbf
from (select loca_id, depar_id,depar_archivo_dbf from _mysql.localidad a
inner join _mysql.departamento b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)), st_setsrid(st_geomfromtext(b.wkt),4326)))b
where a.loca_id = b.loca_id and loca_depar_id is null;

-- Realiza el update de localidad id y lo normaliza
update _mysql.localidad a set  loca_id = b.loca_id+ depar_prov_id*1000
from
(select loca_id,depar_prov_id from _mysql.localidad a
inner join _mysql.departamento b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)), st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.loca_id = b.loca_id;



drop table if exists _mysql.cuadricula;

CREATE TABLE  IF NOT EXISTS _mysql.cuadricula
(
    cuad_id integer,
    cuad_cede_id integer,
    cuad_cuadricula TEXT,
    cuad_comisaria TEXT,
    cuad_departamental TEXT,
    cuad_cria TEXT,
    cuad_partido text,
    cuad_localidad TEXT,
    cuad_provincia TEXT,
    cuad_fecha_actualizacion TEXT,
    cuad_habilitado TEXT
)
;


INSERT INTO  _mysql.cuadricula(cuad_id, cuad_cede_id,cuad_cuadricula,cuad_comisaria, cuad_departamental, cuad_cria,cuad_partido, cuad_localidad,cuad_provincia, cuad_fecha_actualizacion,cuad_habilitado)
	select 
		ID as cuad_id,
		0 as cuad_cede_id,
		SECTOR as cuad_cuadricula, 
		COMIN as cuad_departamental,
		PARTIDO, 
		COMIN as cuad_cria,
		partido as cuad_partido,
		LOCALIDAD as cuad_localidad,
		PROVINCIA as cuad_provincia, 
		FECHAMOD as cuad_fecha_actualizacion, 
		CASE WHEN BORRADO = 0 THEN 1 WHEN BORRADO = 1 THEN 0 END CUAD_HABILITADO

from capas_gral.comisaria_cuadricula_Argentina

where provincia ='''||tabla||''';

'


);
RETURN query execute ('select count(*)::int as cantidad from _mysql.calles')
;

END
$func$ LANGUAGE plpgsql;