-- FUNCTION: _mysql.importador_geometrias(character varying)

-- DROP FUNCTION _mysql.importador_geometrias(character varying);

CREATE OR REPLACE FUNCTION _mysql.importador_geometrias(
	tabla character varying)
    RETURNS TABLE(cantidad integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN EXECUTE (
  '

create table if not exists _mysql.pais (pais_id int, pais_descripcion text, pais_fecha_actualizacion text, pais_habilitado int, wkt text);

INSERT INTO _MYSQL.pais (wkt, PAIS_ID,PAIS_DESCRIPCION,PAIS_FECHA_ACTUALIZACION, PAIS_HABILITADO)
SELECT st_astext(st_transform(GEOM,4326)), id,pais,now() as FECHAMOD,''1'' 
	from capas_gral.pais 
		WHERE pais in (select DISTINCT(PAIS) from capas_gral.partidos where PROVINCIA = ''' || tabla || ''') 
		AND PAIS NOT IN (SELECT PAIS_DESCRIPCION FROM _MYSQL.pais);

create table if not exists _mysql.provincia 
(prov_id int, prov_pais_id int, prov_descripcion text, prov_fecha_actualizacion text,pais_habilitado int, wkt text);

INSERT INTO _MYSQL.PROVINCIA (PROV_ID,prov_pais_id, PROV_DESCRIPCION,prov_fecha_actualizacion,wkt,pais_habilitado)
SELECT IDSOFLEX_PROV::INT,B.ID,PROVINCIA,FECHAMOD,st_Astext(ST_TRANSFORM(A.GEOM,4326)),1 
	FROM capas_gral.provincias A 
	INNER JOIN CAPAS_GRAL.PAIS B ON A.PAIS = B.PAIS
		WHERE a.pais in (select DISTINCT(PAIS) from capas_gral.partidos where PROVINCIA = ''' || tabla || ''') 
		AND PROVINCIA NOT IN (SELECT PROV_DESCRIPCION FROM _MYSQL.PROVINCIA) ORDER BY IDSOFLEX_PROV;

create table if not exists _mysql.departamento
(depar_id int, depar_prov_id int, depar_descripcion text,depar_fecha_actualizacion text, depar_habilitado int, depar_archivo_dbf text, depar_fecha_archivo_dbf text, wkt text);

INSERT into _mysql.departamento  (DEPAR_PROV_ID,  depar_id,  depar_descripcion,  depar_fecha_actualizacion,  depar_habilitado,  depar_archivo_dbf,  wkt)   
	SELECT IDSOFLEX_PROV::INT,CONCAT(IDSOFLEX_PROV,IDSOFLEX_DPTO)::INT,PARTIDO,FECHAMOD,1,ARCH_ID,st_Astext(ST_TRANSFORM(A.GEOM,4326)) 
	FROM capas_gral.partidos  a 
	inner join capas_gral.pais b on a.pais = b.pais    
		where provincia = ''' || tabla || ''' 
		and a.pais in (select DISTINCT(PAIS) from capas_gral.partidos where PROVINCIA = ''' || tabla || ''')
		AND PARTIDO NOT IN (SELECT depar_descripcion FROM _mysql.departamento)
	ORDER BY IDSOFLEX_PROV;

create table if not exists _mysql.localidad
(loca_id int, loca_depar_id int, loca_descripcion text, loca_fecha_actualizacion text, loca_habilitado int, loca_archivo_dbf text, loca_fecha_archivo_dbf text, wkt text);

insert into _mysql.localidad (LOCA_DEPAR_ID, loca_id,loca_descripcion,loca_fecha_actualizacion,loca_habilitado,loca_fecha_archivo_dbf, wkt,loca_archivo_dbf)
SELECT CONCAT(IDSOFLEX_PROV,idsoflex_DPTO)::INT,CONCAT(IDSOFLEX_PROV,idsoflex_local)::INT,localidad,fechamod,''1'',now()::timestamp::text,st_astext(st_transform(a.geom,4326)),b.depar_archivo_dbf 
	FROM CAPAS_gRAL.LOCALIDADES a
	inner join _mysql.departamento b on b.depar_id = CONCAT(IDSOFLEX_PROV,idsoflex_DPTO)::INT
		WHERE PROVINCIA = ''' || tabla || ''' 
		AND localidad not like ''%ZONA RURAL%'' 
		and idsoflex_local is not null
		
		and CONCAT(IDSOFLEX_PROV,idsoflex_local)::INT  NOT IN (select LOCA_ID from _mysql.localidad)
ORDER BY idsoflex_local ASC;

create table if not exists _mysql.archivosdbf 
(id int,arch_id int, arch_nombre text, arch_fecha_modificacion text,arch_fecha_actualizacion text, wkt text );

insert into _mysql.archivosdbf
(id, arch_id, arch_nombre, arch_fecha_modificacion,arch_fecha_actualizacion,wkt)
select id,arch_id,lower(concat(shp,''.dbf'')) as arch_nombre,now()::timestamp::text as arch_fecha_modificacion ,now()::timestamp::text as arch_fecha_actualizacion, st_Astext(st_transform(geom,4326))  from capas_gral.partidos 
where provincia = ''' || tabla || ''' and lower(concat(shp,''.dbf'')) not in (select arch_nombre from _mysql.archivosdbf);

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

'
);
RETURN query execute (
  'select count(*)::int as cantidad from _mysql.calles'
);
END
$BODY$;