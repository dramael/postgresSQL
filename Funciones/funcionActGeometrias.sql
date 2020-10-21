CREATE OR REPLACE FUNCTION test.actualizaciondegeometrias () RETURNS TABLE (tabla text, cantidad int) AS $func$
BEGIN
EXECUTE (
    'create table test.general as select id, (st_dump(st_transform(geom,4326))).geom as "simple" from 
    capas_gral.asentamientos
    where fechamod ::date = ''today'';
    update capas_gral.asentamientos a 
    set "simple" = b."simple"
    from test.general b
    where a.id = b.id
    and a.fechamod ::date = ''today'';
    drop table test.general;
    update capas_gral.asentamientos set nombre = upper (nombre) where fechamod ::date = ''today'';
    update capas_gral.asentamientos a set localidad = b.localidad
    from capas_gral.localidades b
    where st_within (st_centroid(a.geom),b.geom) and a.localidad is null and a.fechamod ::date = ''today'';
    update capas_gral.asentamientos a set provincia = b.provincia
    from capas_gral.departamento b
    where st_within (st_centroid(a.geom),b.geom)and a.fechamod ::date = ''today'';
    update capas_gral.asentamientos a set departamen = b.partido
    from capas_gral.departamento b
    where st_within (st_centroid(a.geom),b.geom) and a.departamen is null and a.fechamod ::date = ''today'';
    update capas_gral.asentamientos set borrado = ''f'' where borrado is null and fechamod ::date = ''today'';

    create table test.general as select id, (st_dump(st_transform(geom,4326))).geom as "simple" from 
    capas_gral.departamento
    where fechamod ::date = ''today'';
    update capas_gral.departamento a 
    set "simple" = b."simple"
    from test.general b
    where a.id = b.id
    and a.fechamod ::date = ''today'';
    drop table test.general;
    update capas_gral.departamento a set provincia = b.provincia
    from capas_gral.provincia b
    where st_within (a.geom, b.geom) and a.provincia is null and a.fechamod ::date = ''today'';
    update capas_gral.departamento set partido = upper (partido) where fechamod ::date = ''today'';

    create table test.general as select id, (st_dump(st_transform(geom,4326))).geom as "simple" from 
    capas_gral.barrios
    where fechamod ::date = ''today'';
    update capas_gral.barrios a 
    set "simple" = b."simple"
    from test.general b
    where a.id = b.id
    and a.fechamod ::date = ''today'';
    drop table test.general;
    update capas_gral.barrios set barrio = upper(barrio) where fechamod ::date = ''today'';
    update capas_gral.barrios a set localidad = b.localidad
    from capas_gral.localidades b
    where st_within (st_centroid(a.geom),b.geom) and a.localidad is null and a.fechamod ::date = ''today'';
    update capas_gral.barrios a set partido = b.partido
    from capas_gral.departamento b
    where st_within (st_centroid(a.geom),b.geom) and a.partido is null and a.fechamod ::date = ''today'';
    update capas_gral.barrios a set provincia = b.provincia
    from capas_gral.provincia b
    where st_within (st_centroid(a.geom),b.geom) and a.provincia is null and a.fechamod ::date = ''today'';

    create table test.general as select id, (st_dump(st_transform(geom,4326))).geom as "simple" from 
    capas_gral.provincia
    where fechamod ::date = ''today'';
    update capas_gral.provincia a 
    set "simple" = b."simple"
    from test.general b
    where a.id = b.id
    and a.fechamod ::date = ''today'';
    drop table test.general;

    create table test.general as select id, (st_dump(st_transform(geom,4326))).geom as "simple" from 
    capas_gral.localidades
    where fechamod ::date = ''today'';
    update capas_gral.localidades a 
    set "simple" = b."simple"
    from test.general b
    where a.id = b.id
    and a.fechamod ::date = ''today'';
    drop table test.general;
    update capas_gral.localidades set localidad = upper(localidad) where fechamod ::date = ''today'';
    update capas_gral.localidades a set partido = b.partido
    from capas_gral.departamento b
    where st_within (st_centroid(a.geom),b.geom) and a.partido is null and a.fechamod ::date = ''today'';
    update capas_gral.localidades a set provincia = b.provincia
    from capas_gral.provincia b
    where st_within (st_centroid(a.geom),b.geom) and a.provincia is null and a.fechamod ::date = ''today'';

    create table test.general as select id, (st_dump(st_transform(geom,4326))).geom as "simple" from 
    capas_gral.comisaria_circunscripciones_argentina
    where fechamod ::date = ''today'';
    update capas_gral.comisaria_circunscripciones_argentina a 
    set "simple" = b."simple"
    from test.general b
    where a.id = b.id
    and a.fechamod ::date = ''today'';
    drop table test.general;	

    update capas_gral.comisaria_circunscripciones_argentina a set partido = b.partido
    from capas_gral.departamento b
    where st_within (st_centroid(a.geom),b.geom) and a.fechamod ::date = ''today'';

    update capas_gral.comisaria_circunscripciones_argentina a set provincia = upper(b.provincia)
    from capas_gral.provincia b
    where st_within (st_centroid(a.geom), b.geom) and a.fechamod ::date = ''today'';

    update capas_gral.comisaria_circunscripciones_argentina set cliente = upper(cliente) where fechamod::date = ''today'';

    update capas_gral.comisaria_circunscripciones_argentina set circunscri = upper (circunscri) where fechamod::date = ''today'';

    update capas_gral.comisaria_circunscripciones_argentina set descripcio = upper (descripcio) where fechamod::date = ''today'';

    update capas_gral.comisaria_cuadricula_argentina a set comin = b.cria
    from capas_gral.comisaria_zona_argentina b 
    where st_within (st_centroid(st_transform(a.geom,4326)), st_transform(b.geom,4326)) and a.comin is  null and a.fechamod ::date = ''today'' and a.cliente = b.cliente;
    
    update capas_gral.comisaria_cuadricula_argentina set cria = comin
    where cria is null and fechamod ::date = ''today'';

    update capas_gral.bomberos_jurisdicciones_argentina a set simple = b.simple
    from (select id,(st_dump(st_transform(geom,4326))).geom as simple from capas_gral.bomberos_jurisdicciones_argentina) b
    where a.id = b.id;
    
    update capas_gral.bomberos_jurisdicciones_argentina a set division = upper(division);
    update capas_gral.bomberos_jurisdicciones_argentina a set nombre = upper(nombre);
    update capas_gral.bomberos_jurisdicciones_argentina a set tipo = upper(tipo);
                    
    create table test.general as select id, (st_dump(st_transform(geom,4326))).geom as "simple" from 
    capas_gral.comisaria_zona_argentina
    where fechamod ::date = ''today'';

    update capas_gral.comisaria_zona_argentina a 
    set "simple" = b."simple"
    from test.general b
    where a.id = b.id
    and a.fechamod ::date = ''today'';
    drop table test.general;

    update capas_gral.comisaria_zona_argentina set cliente = upper(cliente) where fechamod ::date = ''today'';

    update capas_gral.comisaria_zona_argentina set comin = upper(comin) where fechamod ::date = ''today'';

    update capas_gral.comisaria_zona_argentina set departamen = upper (departamen) where fechamod ::date = ''today'';

    update capas_gral.comisaria_zona_argentina a set localidad = b.localidad
    from capas_gral.localidades b
    where st_within (st_centroid(a.geom),b.geom) and a.localidad is null and a.fechamod ::date = ''today'';

    update capas_gral.comisaria_zona_argentina a set partido = b.partido
    from capas_gral.departamento b
    where st_within (st_centroid(a.geom),b.geom) and a.partido is null and a.fechamod ::date = ''today'';

    update capas_gral.comisaria_zona_argentina a set provincia = upper(b.provincia)
    from capas_gral.provincia b
    where st_within (st_centroid(a.geom), b.geom) and a.fechamod ::date = ''today'';

    update capas_gral.comisaria_zona_argentina a set departamen = b.circunscri
    from capas_gral.comisaria_circunscripciones_argentina b 
    where st_within (st_centroid(st_transform(a.geom,4326)), st_transform(b.geom,4326)) and a.departamen is  null and a.fechamod ::date = ''today'';

    update capas_gral.comisaria_zona_argentina a set departamen	= concat(''JEF. DE '', partido) WHERE departamen is  null and fechamod ::date = ''today'';
                                                                                                                        
    create table test.general as select id, (st_dump(st_transform(geom,4326))).geom as "simple" from 
    capas_gral.comisaria_cuadricula_argentina
    where fechamod ::date = ''today'';
    update capas_gral.comisaria_cuadricula_argentina a 
    set "simple" = b."simple"
    from test.general b
    where a.id = b.id
    and a.fechamod ::date = ''today'';
    drop table test.general;

    update capas_gral.comisaria_cuadricula_argentina set cliente = upper(cliente) where fechamod ::date = ''today'';

    update capas_gral.comisaria_cuadricula_argentina set comin = upper(comin) where fechamod ::date = ''today'';
    
    update capas_gral.comisaria_cuadricula_argentina a set localidad = b.localidad
    from capas_gral.localidades b
    where st_within (st_centroid(a.geom),b.geom) and a.localidad is null and a.fechamod ::date = ''today'';
    
    update capas_gral.comisaria_cuadricula_argentina a set partido = b.partido
    from capas_gral.departamento b
    where st_within (st_centroid(a.geom),b.geom) and a.fechamod ::date = ''today'';
    
    update capas_gral.comisaria_cuadricula_argentina a set provincia = upper(b.provincia)
    from capas_gral.provincia b
    where st_within (st_centroid(a.geom), b.geom) and a.fechamod ::date = ''today'';

    update capas_gral.comisaria_cuadricula_argentina a set departamen = b.circunscri
    from capas_gral.comisaria_circunscripciones_argentina b 
    where st_within (st_centroid(st_transform(a.geom,4326)), st_transform(b.geom,4326)) and a.departamen is  null and a.fechamod ::date = ''today'' and a.cliente = b.cliente;
    
    update capas_gral.comisaria_cuadricula_argentina a set departamen	= concat(''JEF. DE '', partido) WHERE departamen is  null and fechamod ::date = ''today'';

    update capas_gral.comisaria_cuadricula_argentina set departamen = upper (departamen) where fechamod ::date = ''today'';



    update capas_Gral.departamento a set idsoflex_prov = b.idsoflex_prov
    from
    (select a.id,b.idsoflex_prov from capas_gral.departamento a
    inner join capas_gral.provincia b on st_within (a.geom, b.geom)) b
    where a.id = b.id and fechamod ::date = ''today'' and a.idsoflex_prov is null;

    update capas_Gral.localidades a set idsoflex_prov = b.idsoflex_prov, idsoflex_dpto = b.idsoflex_dpto
    from
    (select a.id,b.idsoflex_prov, b.idsoflex_dpto from capas_gral.localidades a
    inner join capas_gral.departamento b on st_within (a.geom, b.geom) ) b
    where a.id = b.id and fechamod ::date = ''today'' and a.idsoflex_prov is null and a.idsoflex_dpto is null;

    UPDATE capas_Gral.comisaria_cuadricula_argentina set borrado = 0 where borrado is null and fechamod ::date = ''today'';
    UPDATE capas_Gral.comisaria_zona_argentina set borrado = 0 where borrado is null and fechamod ::date = ''today'';




    ');
RETURN query execute ('
    select concat(a.fechamod::date, '' Asentamientos'')::text, count (a.fechamod::date)::int
    from
    capas_gral.asentamientos a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    union 
    select concat(a.fechamod::date, '' Departamentos'')::text, count (a.fechamod::date)::int
    from
    capas_gral.departamento a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    UNION
    select concat(a.fechamod::date, '' Barrios'')::text, count (a.fechamod::date)::int
    from
    capas_gral.barrios a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    UNION
    select concat(a.fechamod::date, '' Provincia'')::text, count (a.fechamod::date)::int
    from
    capas_gral.provincia a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    UNION
    select concat(a.fechamod::date, '' Localidades'')::text, count (a.fechamod::date)::int
    from
    capas_gral.localidades a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    UNION
    select concat(a.fechamod::date, '' Comisaria circunscripcion'')::text, count (a.fechamod::date)::int
    from
    capas_gral.comisaria_circunscripciones_argentina a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    UNION
    select concat(a.fechamod::date, '' Comisaria cuadricula'')::text, count (a.fechamod::date)::int
    from
    capas_gral.comisaria_cuadricula_argentina a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    UNION
    select concat(a.fechamod::date, '' Comisaria zona'')::text, count (a.fechamod::date)::int
    from
    capas_gral.comisaria_zona_argentina a
    group by a.fechamod::date
    having  count (fechamod::date) < 20000
    order by 1 desc');

END
$func$ LANGUAGE plpgsql;
