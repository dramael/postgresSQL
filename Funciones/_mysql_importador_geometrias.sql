CREATE
OR REPLACE FUNCTION _mysql.importador_geometrias(tabla varchar(30)) RETURNS TABLE (cantidad int) AS $func$ BEGIN EXECUTE (
  '

create table if not exists _mysql.pais (pais_id int, pais_descripcion text, pais_fecha_actualizacion text, pais_habilitado int, wkt text);

TRUNCATE TABLE _MYSQL.PAIS;

INSERT INTO _MYSQL.pais (wkt, PAIS_ID,PAIS_DESCRIPCION,PAIS_FECHA_ACTUALIZACION, PAIS_HABILITADO)
select 	st_astext(GEOM), id,pais,now() as FECHAMOD,''1'' from capas_gral.pais WHERE pais in (select DISTINCT(PAIS) from capas_gral.departamento where PROVINCIA = ''' || tabla || ''');



create table if not exists _mysql.provincia 
(prov_id int, prov_pais_id int, prov_descripcion text, prov_fecha_actualizacion text,pais_habilitado int, wkt text);

TRUNCATE TABLE _MYSQL.PROVINCIA;

INSERT INTO _MYSQL.PROVINCIA (PROV_ID,prov_pais_id, PROV_DESCRIPCION,prov_fecha_actualizacion,wkt,pais_habilitado)
SELECT IDSOFLEX_PROV::INT,B.ID,PROVINCIA,FECHAMOD,st_Astext(SIMPLE),1 FROM CAPAS_GRAL.PROVINCIA A INNER JOIN CAPAS_GRAL.PAIS B ON A.PAIS = B.PAIS
WHERE a.pais in (select DISTINCT(PAIS) from capas_gral.departamento where PROVINCIA = ''' || tabla || ''') ORDER BY IDSOFLEX_PROV;





create table if not exists _mysql.departamento
(depar_id int, depar_prov_id int, depar_descripcion text,depar_fecha_actualizacion text, depar_habilitado int, depar_archivo_dbf text, depar_fecha_archivo_dbf text, wkt text);

TRUNCATE TABLE _MYSQL.DEPARTAMENTO;

 insert into _mysql.departamento  (DEPAR_PROV_ID,  depar_id,  depar_descripcion,  depar_fecha_actualizacion,  depar_habilitado,  depar_archivo_dbf,  wkt)   SELECT b.id,IDSOFLEX_PROV::INT,PROVINCIA,FECHAMOD,1,1,st_Astext(SIMPLE) FROM CAPAS_GRAL.DEPARTAMENTO  a inner join capas_gral.pais b on a.pais = b.pais    where provincia = ''' || tabla || ''' and a.pais in (select DISTINCT(PAIS) from capas_gral.departamento where PROVINCIA = ''' || tabla || ''')  ORDER BY IDSOFLEX_PROV;





create table if not exists _mysql.localidad
(loca_id int, loca_depar_id int, loca_descripcion text, loca_fecha_actualizacion text, loca_habilitado int, loca_archivo_dbf text, loca_fecha_archivo_dbf text, wkt text);

TRUNCATE TABLE _MYSQL.LOCALIDAD;

insert into _mysql.localidad (LOCA_DEPAR_ID, loca_id,loca_descripcion,loca_fecha_actualizacion,loca_habilitado,loca_fecha_archivo_dbf, wkt,loca_archivo_dbf)
SELECT CONCAT(IDSOFLEX_PROV,idsoflex_DPTO)::INT,CONCAT(IDSOFLEX_PROV,idsoflex_local)::INT,localidad,fechamod,''1'',now()::timestamp::text,st_astext(simple),''0'' FROM CAPAS_gRAL.LOCALIDADES WHERE PROVINCIA = ''' || tabla || ''' and localidad not like ''%ZONA RURAL%'' and idsoflex_local is not null
ORDER BY idsoflex_local ASC;


create table if not exists _mysql.archivosdbf 
(id int,arch_id int, arch_nombre text, arch_fecha_modificacion text,arch_fecha_actualizacion text, wkt text );

TRUNCATE TABLE _MYSQL.ARCHIVOSDBF;


insert into _mysql.archivosdbf
(id, arch_id, arch_nombre, arch_fecha_modificacion,arch_fecha_actualizacion,wkt)
select id,arch_id,concat(shp,''.dbf'') as arch_nombre,now()::timestamp::text as arch_fecha_modificacion ,now()::timestamp::text as arch_fecha_actualizacion, st_Astext(simple)  from capas_gral.departamento where provincia = ''' || tabla || ''';



update _mysql.archivosdbf set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.departamento set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.localidad set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.pais set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;
update _mysql.provincia set geom = st_multi(st_setsrid(st_geomfromtext(wkt),4326)) where geom is null;


CREATE INDEX IF NOT EXISTS GEOMDBF	 ON _MYSQL.archivosdbf 		USING GIST (GEOM);
CREATE INDEX IF NOT EXISTS GEOMDPTO	 ON _MYSQL.departamento 	USING GIST (GEOM);
CREATE INDEX IF NOT EXISTS GEOMLOC	 ON _MYSQL.localidad 		USING GIST (GEOM);
CREATE INDEX IF NOT EXISTS GEOMPAIS	 ON _MYSQL.pais 			USING GIST (GEOM);
CREATE INDEX IF NOT EXISTS GEOMPROV	 ON _MYSQL.provincia 		USING GIST (GEOM);


-- actualiza el valor de pais en provncia
update _mysql.provincia set prov_pais_id = 1 WHERE prov_pais_id is null;

-- actualiza el valor de depar_prov_id en departamento

-- Realiza el update de departamento id y dbf en localidades

-- Realiza el update de localidad id y lo normaliza


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

where provincia =''' || tabla || ''';

'
);
RETURN query execute (
  'select count(*)::int as cantidad from _mysql.calles'
);
END $func$ LANGUAGE plpgsql;