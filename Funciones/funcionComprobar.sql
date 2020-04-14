-- Comprueba las alturas de los segmentos contra la informacion que se encuentra georeferenciada

CREATE OR REPLACE FUNCTION test.comprobar(tabla varchar(30)) RETURNS TABLE (cantidad int ) AS $func$
BEGIN
EXECUTE (

'update _cartografia.'||tabla||' set 	google = null,
                                        fuente = null,
                                        here = null,
                                        osm = null,						
                                        "check" = null;

update _cartografia.'||tabla||' set google = 1 where id in (select A.ID from _cartografia.'||tabla||' a 
    inner join varios.inverse_geocode_google b on st_intersects (st_buffer(a.geom,10), st_transform(b.geom,5347)) 
    where 
        A.PARTIDO = B.PARTIDO 
        AND	A.LOCALIDAD = B.LOCALIDAD
        and a.calle is not null
        and b.altura <> 0
        and isnumeric(right(b.calle,1)) = ''true'' 
        and altura between fromleft and toright
        AND (SIMILARITY (A.CALLE, B.NOMBRE) > 0.2
            or string_to_array(a.calle, '' '', '''') && string_to_array(b.nombre, '' '', '''')));
		
update _cartografia.'||tabla||' set google = 0 where google is null;		
update _cartografia.'||tabla||' set here = 1 where id in (select A.ID from _cartografia.'||tabla||' a 
    inner join varios.inverse_geocode_here b on st_intersects (st_buffer(a.geom,10), st_transform(b.geom,5347)) 
    where 
        A.PARTIDO = B.PARTIDO 
        AND	A.LOCALIDAD = B.LOCALIDAD
        and a.calle is not null
        and b.altura <> 0
        and isnumeric(right(b.direccion1,1)) = ''true'' 
        and altura between fromleft and toright
        AND (SIMILARITY (A.CALLE, B.NOMBRE) > 0.2
            or string_to_array(a.calle, '' '', '''') && string_to_array(b.nombre, '' '', '''')));
		
update _cartografia.'||tabla||' set here = 0 where here is null;
update _cartografia.'||tabla||' set osm = 1 where id in (select A.ID from _cartografia.'||tabla||' a 
    inner join varios.inverse_geocode_osm b on st_intersects (st_buffer(a.geom,10), st_transform(b.geom,5347)) 
    where 
        A.PARTIDO = B.PARTIDO 
        AND	A.LOCALIDAD = B.LOCALIDAD
        and a.calle is not null
        and b.altura <> 0
        and isnumeric(right(b.calle,1)) = ''true'' 
        and altura between fromleft and toright
        AND (SIMILARITY (A.CALLE, B.calle) > 0.2
            or string_to_array(a.calle, '' '', '''') && string_to_array(b.calle, '' '', '''')));

update _cartografia.'||tabla||' set osm = 0 where osm is null;'
		
)
;
RETURN query execute ('select count(*)::int as cantidad from _cartografia.'||tabla||' where (osm+here+google) <> 0;')
;

END
$func$ LANGUAGE plpgsql;


















 
 