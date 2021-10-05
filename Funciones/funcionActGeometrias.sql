-- FUNCTION: test.act_geometrias()

-- DROP FUNCTION test.act_geometrias();

CREATE OR REPLACE FUNCTION test.act_geometrias(
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

EXECUTE ('
		 update capas_gral.provincias set provincia = upper (provincia) where fechamod ::date = ''today'';
		 
		 update capas_gral.partidos set partido = upper (partido) where fechamod ::date = ''today'';
		 update capas_Gral.partidos a set idsoflex_prov = b.idsoflex_prov from
         (select a.id,b.idsoflex_prov from capas_gral.partidos a
         inner join capas_gral.provincias b on st_within (st_centroid(a.geom), b.geom)) b
         where a.id = b.id and a.idsoflex_prov is null and fechamod::date = ''today'';
		 
		 update capas_gral.localidades set localidad = upper(localidad) where fechamod ::date = ''today'';
		 update capas_Gral.localidades a set idsoflex_prov = b.idsoflex_prov, idsoflex_dpto = b.idsoflex_dpto from (
    	 select a.id, b.idsoflex_prov, b.idsoflex_dpto, b.partido from capas_Gral.localidades a
    	 inner join capas_gral.partidos b on st_intersects (st_centroid(a.geom), b.geom)
    	 where a.idsoflex_prov is null or a.idsoflex_dpto is null
    	 order BY ID) b
    	 where a.id = b.id and fechamod::date = ''today'';
		 
		 update capas_gral.barrios set nombre = upper(nombre) where fechamod ::date = ''today''; 
		 update capas_gral.asentamientos set nombre = upper (nombre) where fechamod ::date = ''today'';
    	 
		 update capas_gral.comisaria_circunscripciones set cliente = upper(cliente) where fechamod::date = ''today'';
         update capas_gral.comisaria_circunscripciones set circunscri = upper (circunscri) where fechamod::date = ''today'';
         update capas_gral.comisaria_circunscripciones set descripcio = upper (descripcio) where fechamod::date = ''today'';
		 
		 update capas_gral.comisaria_zonas set cliente = upper(cliente) where fechamod ::date = ''today'';
 	     update capas_gral.comisaria_zonas set comin = upper(comin) where fechamod ::date = ''today'';
    	 update capas_gral.comisaria_zonas a set departamen = b.circunscri from capas_gral.comisaria_circunscripciones b 
		 where st_within (st_centroid(a.geom), b.geom) and a.departamen is  null and a.fechamod ::date = ''today'';
		 update capas_gral.comisaria_zonas a set departamen	= concat(''JEF. DE '', partido) WHERE departamen is  null and fechamod ::date = ''today'';
		 update capas_gral.comisaria_zonas set departamen = upper (departamen) where fechamod ::date = ''today'';
		 update capas_Gral.comisaria_zonas set borrado = 0 where borrado is null and fechamod ::date = ''today'';
		 update capas_Gral.comisaria_zonas set circ = departamen where circ is null and fechamod ::date = ''today'';
		 
		 update capas_gral.comisaria_cuadriculas a set comin = b.cria from capas_gral.comisaria_zonas b 
    	 where st_within (st_centroid(a.geom), b.geom) and a.comin is  null and a.fechamod ::date = ''today'' and a.cliente = b.cliente; 
    	 update capas_gral.comisaria_cuadriculas set cria = comin where cria is null and fechamod ::date = ''today'';
		 update capas_gral.comisaria_cuadriculas set cliente = upper(cliente) where fechamod ::date = ''today'';
		 update capas_gral.comisaria_cuadriculas set comin = upper(comin) where fechamod ::date = ''today'';
		 update capas_gral.comisaria_cuadriculas a set departamen = b.circunscri from capas_gral.comisaria_circunscripciones b 
		 where st_within (st_centroid(a.geom), b.geom) and a.departamen is  null and a.fechamod ::date = ''today'' and a.cliente = b.cliente;
		 update capas_gral.comisaria_cuadriculas a set departamen = concat(''JEF. DE '', partido) where departamen is  null and fechamod ::date = ''today'';
		 update capas_gral.comisaria_cuadriculas set departamen = upper (departamen) where fechamod ::date = ''today'';
		 update capas_Gral.comisaria_cuadriculas set borrado = 0 where borrado is null and fechamod ::date = ''today'';
		 
		 update capas_gral.bomberos_jurisdicciones a set division = upper(division);
    	 update capas_gral.bomberos_jurisdicciones a set nombre = upper(nombre);
         update capas_gral.bomberos_jurisdicciones a set tipo = upper(tipo);
		 
		 ');

FOR tabla IN
	
	SELECT tablename FROM pg_catalog.pg_tables where schemaname='capas_gral'
	and tablename in ('asentamientos','localidades','comisaria_cuadriculas','barrios','comisaria_circunscripciones','partidos','comisaria_zonas','provincias') 
	
	LOOP
	
	EXECUTE ('
			 update capas_gral.'||tabla||' set geom = st_makevalid(geom) where st_isvalid(geom) = ''false'' and fechamod ::date = ''today'';
			 update capas_gral.'||tabla||' set geom = ST_ForcePolygonCW (geom) where  ST_IsPolygonCW (geom) = ''false'' and fechamod ::date = ''today'';
			 			 ');
			 
	IF TABLA <> 'pais' THEN EXECUTE ('update capas_gral.'||tabla||' a set pais = b.pais from capas_gral.pais b
										   where st_within (st_centroid(a.geom), b.geom) and a.pais is null and a.fechamod ::date = ''today''
									 ');		 
	END IF;
	
	IF TABLA <> 'provincias' THEN EXECUTE ('
										   update capas_gral.'||tabla||' a set provincia = b.provincia from capas_gral.provincias b
										   where st_within (st_centroid(a.geom), b.geom) and a.provincia is null and a.fechamod ::date = ''today''
										   ');
	END IF;
		
	IF TABLA NOT IN ('provincias','partidos') THEN EXECUTE ('
															update capas_gral.'||tabla||' a set partido = b.partido
															from capas_gral.partidos b
												            where st_within (st_centroid(a.geom),b.geom) and a.partido is null and a.fechamod ::date = ''today''
															');
	END IF;
	
	IF TABLA IN ('barrios','asentamientos','comisaria_zonas','comisaria_cuadriculas') THEN EXECUTE ('
																									update capas_gral.'||tabla||' a set localidad = b.localidad
																									from capas_gral.localidades b
																									where st_within (st_centroid(a.geom),b.geom) and a.localidad is null and a.fechamod ::date = ''today''
																									');
	END IF;
	
	END LOOP;
	

		 
RETURN QUERY EXECUTE ('
    select concat(a.fechamod::date, '' Asentamientos'')::text, count (a.fechamod::date)::int
    from capas_gral.asentamientos a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    union 
    select concat(a.fechamod::date, '' Partidos'')::text, count (a.fechamod::date)::int
    from capas_gral.partidos a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    union
    select concat(a.fechamod::date, '' Barrios'')::text, count (a.fechamod::date)::int
    from capas_gral.barrios a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    union
    select concat(a.fechamod::date, '' Provincias'')::text, count (a.fechamod::date)::int
    from capas_gral.provincias a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    union 
    select concat(a.fechamod::date, '' Localidades'')::text, count (a.fechamod::date)::int
    from capas_gral.localidades a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    union
    select concat(a.fechamod::date, '' Comisaria Circunscripciones'')::text, count (a.fechamod::date)::int
    from capas_gral.comisaria_circunscripciones a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    union
    select concat(a.fechamod::date, '' Comisaria Cuadriculas'')::text, count (a.fechamod::date)::int
    from capas_gral.comisaria_cuadriculas a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    union
    select concat(a.fechamod::date, '' Comisaria Zonas'')::text, count (a.fechamod::date)::int
    from capas_gral.comisaria_zonas a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    order by 1 desc');

END;
$BODY$;

ALTER FUNCTION test.act_geometrias()
    OWNER TO gabriela;
