CREATE OR REPLACE FUNCTION _mysql.importador(tabla varchar(30)) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (

'

create table if not exists _mysql.pais
(pais_id int, pais_descripcion text, pais_fecha_actualizacion text, pais_habilitado int, wkt text);

INSERT INTO _MYSQL.pais (wkt, PAIS_ID,PAIS_DESCRIPCION,PAIS_FECHA_ACTUALIZACION, PAIS_HABILITADO)
select 	st_astext(GEOM), ''1'',NOMBRE,FECHAMOD,''1'' from capas_gral.hitos_pol where tipo = ''PAIS'';

create table if not exists _mysql.provincia 
(prov_id int, prov_pais_id int, prov_descripcion text, prov_fecha_actualizacion text,pais_habilitado int, wkt text);

INSERT INTO _MYSQL.PROVINCIA (PROV_ID, PROV_DESCRIPCION,prov_fecha_actualizacion,wkt,pais_habilitado)
SELECT IDSOFLEX_PROV::INT,PROVINCIA,FECHAMOD,st_Astext(SIMPLE),1 FROM CAPAS_GRAL.PROVINCIA ORDER BY IDSOFLEX_PROV;

create table if not exists _mysql.departamento
(depar_id int, depar_prov_id int, depar_descripcion text,depar_fecha_actualizacion text, depar_habilitado int, depar_archivo_dbf text, depar_fecha_archivo_dbf text, wkt text);

insert into _mysql.departamento 
(depar_id,depar_descripcion, depar_fecha_actualizacion,depar_habilitado,depar_archivo_dbf,wkt)
select idsoflex_prov::int*1000+idsoflex_dpto::int, partido,fechamod,''1'',shp, st_astext(simple) from capas_Gral.departamento where provincia = '''||tabla||''';

create table if not exists _mysql.localidad
(loca_id int, loca_depar_id int, loca_descripcion text, loca_fecha_actualizacion text, loca_habilitado int, loca_archivo_dbf text, loca_fecha_archivo_dbf text, wkt text);

insert into _mysql.localidad (loca_id,loca_descripcion,loca_fecha_actualizacion,loca_habilitado, wkt)
SELECT idsoflex_local::int,localidad,fechamod,''1'',st_astext(simple) FROM CAPAS_gRAL.LOCALIDADES WHERE PROVINCIA = '''||tabla||''' and localidad not like ''%ZONA RURAL%'' and idsoflex_local is not null
ORDER BY idsoflex_local ASC;

create table if not exists _mysql.archivosdbf 
(arch_id int, arch_nombre text, arch_fecha_modificacion text,arch_fecha_actualizacion text, wkt text );


INSERT INTO _mysql.archivosdbf 
select id,"CALLES",(now()::timestamp)::text, (now()::timestamp)::text, st_astext("GEOM") from _avl."Localizacion calles_Argentina"
WHERE "PROVINCIA" = '''||tabla||''' ;


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
update _mysql.localidad a set  loca_id = b.loca_id+ depar_prov_id*1000
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
where a.call_id = b.call_id;

-- actualiza el valor archivo id en callesalturas
update _mysql.callesalturas a set caal_arch_id = b.arch_id
from (
select caal_id,b.arch_id from _mysql.callesalturas a
inner join _mysql.archivosdbf b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.caal_id = b.caal_id;


-- Actualiza los valores de departamento en callesaltura

update _mysql.callesalturas a set caal_depar_id = depar_id
from (
select caal_id, depar_id from _mysql.callesalturas a
inner join _mysql.departamento b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.caal_id = b.caal_id
;

-- actualiza el valor archivo id en calles interseccion2

update _mysql.callesintersecciones2 a set cain_arch_id = b.arch_id
from (
select cain_id,b.arch_id from _mysql.callesintersecciones2 a
inner join _mysql.archivosdbf b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.cain_id = b.cain_id;

-- Actualiza el valor de archivo di en localidad
update _mysql.localidad a set loca_archivo_dbf = b.arch_id
from (
select loca_id,b.arch_id from _mysql.localidad a
inner join _mysql.archivosdbf b on st_within (st_centroid(st_setsrid(st_geomfromtext(a.wkt),4326)),st_setsrid(st_geomfromtext(b.wkt),4326))) b
where a.loca_id = b.loca_id;

-- Actualiza la tabla de tipos id

insert into _MYSQL.HITO_TIPO (hiti_id, hiti_codigo,hiti_descripcion, hiti_fecha_actualizacion, hiti_habilitado )
select hiti_id::int, hiti_codigo,hiti_descripcion, (now()::timestamp)::text hiti_fecha_actualizacion, hiti_habilitado::int from _idhito ;


CREATE TABLE if not exists _mysql.hito (  HITO_ID int,  HITO_HITI_ID int ,  HITO_DESCRIPCION text ,  HITO_CALLE text ,  HITO_ENTRE_CALLE1 text ,  HITO_ENTRE_CALLE2 text ,  HITO_ALTURA int ,  HITO_NUMERO int ,  HITO_PROV_ID int ,  HITO_DEPA_ID int ,  HITO_LOCA_ID int , HITO_TELEFONO text ,  HITO_LATITUD text ,  HITO_LONGITUD text ,  HITO_OBSERVACIONES text,
HITO_FECHA_ACTUALIZACION text ,  HITO_HABILITADO int ,  HITO_ID_MAPA int ) ;

insert into _mysql.hito (hito_id, hito_hiti_id, hito_descripcion, hito_calle, hito_latitud, hito_longitud,hito_fecha_actualizacion,hito_habilitado)
select 
case when id_hito is null then a.id+100000 else id_hito end hito_id, b.hiti_id as hito_hiti_id, nombre as hito_descripcion,direccion as hito_calle, y as hito_latitud, x as hito_longitud, fechamod as hito_fecha_actualizacion, borrado as hito_habilitado
from capas_Gral.hitos a inner join _idhito b on a.tipo = b.hiti_descripcion where provincia = '''||tabla||'''  order by 1;

update _mysql.hito a set hito_prov_id = b.prov_id
from(
select hito_id,prov_id  from _mysql.hito a
inner join _mysql.provincia b on
st_within (st_setsrid(st_makepoint(hito_longitud::double precision, hito_latitud::double precision),4326), st_setsrid(st_geomfromtext(b.wkt),4326)) 
) b
where a.hito_id = b.hito_id;

update _mysql.hito a set hito_depa_id = b.depar_id
from(
select hito_id,depar_id  from _mysql.hito a
inner join _mysql.departamento b on
st_within (st_setsrid(st_makepoint(hito_longitud::double precision, hito_latitud::double precision),4326), st_setsrid(st_geomfromtext(b.wkt),4326)) 
) b
where a.hito_id = b.hito_id;

update _mysql.hito a set hito_loca_id = b.loca_depar_id
from(
select hito_id,loca_depar_id  from _mysql.hito a
inner join _mysql.localidad b on
st_within (st_setsrid(st_makepoint(hito_longitud::double precision, hito_latitud::double precision),4326), st_setsrid(st_geomfromtext(b.wkt),4326)) 
) b
where a.hito_id = b.hito_id;

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



update _mysql.calles set  CALL_ES_ALIAS=0 where call_es_alias is null;
update _mysql.calles set  CALL_ALIAS_DE_CALL_ID=0 where CALL_ALIAS_DE_CALL_ID is null;
update _mysql.calles  set call_tipo = 0;
update _mysql.calles set CALL_FECHA_ACTUALIZACION = now();
update _mysql.calles set CALL_ARCH_ID = 1;
update _mysql.calles set CALL_RUTA_NOMBRE = '';
update _mysql.calles set CALL_RUTA_TIPO = '';
update _mysql.calles set CALL_RUTA_DESCRIPCION = '';
update _mysql.calles set CALL_RUTA_OBSERVACION = '';
update _mysql.callesalturas set CAAL_FECHA_ACTUALIZACION = now();
update _mysql.callesalturas set CAAL_ARCH_ID = 1;

'


);
RETURN query execute ('select count(*)::int as cantidad from _mysql.calles')
;

END
$func$ LANGUAGE plpgsql;