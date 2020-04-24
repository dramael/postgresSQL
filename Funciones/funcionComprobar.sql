-- Comprueba las alturas de los segmentos contra la informacion que se encuentra georeferenciada

CREATE OR REPLACE FUNCTION test.comprobar(tabla varchar(30)) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (

'update _cartografia.'||tabla||' set 	google = null,
                                        fuente = null,
                                        here = null,
                                        osm = null					
                                        where "check" is null;


update _cartografia.'||tabla||' set google = 1 where id in (select A.ID from _cartografia.'||tabla||' a 
    inner join varios.inverse_geocode_google b on st_intersects (st_buffer(a.geom,10), st_transform(b.geom,5347)) 
    where 
        A.PARTIDO = B.PARTIDO 
        AND	A.LOCALIDAD = B.LOCALIDAD
        and a.calle is not null
        and b.altura <> 0
        and isnumeric(right(b.calle,1)) = ''true'' 
        and (altura between fromleft and toleft or altura between fromright and toright)
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
       and (altura between fromleft and toleft or altura between fromright and toright)
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
        and (altura between fromleft and toleft or altura between fromright and toright)
        AND (SIMILARITY (A.CALLE, B.calle) > 0.2
            or string_to_array(a.calle, '' '', '''') && string_to_array(b.calle, '' '', '''')));

update _cartografia.'||tabla||' set osm = 0 where osm is null;

update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''google/osm/here'' WHERE google+here+osm = 3;
update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''google/osm'' WHERE google+osm = 2 and here = 0;
update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''google/here'' WHERE google+here = 2 and osm = 0;
update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''here/osm'' WHERE osm+here = 2 and google = 0;
update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''google'' WHERE google = 1 and here+osm = 0;
update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''osm'' WHERE osm = 1 and google+here = 0;
update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''here'' WHERE here = 1 and google+osm = 0;

update _cartografia.'||tabla||' set "check" = ''OK'',	
    fuente = ''adyacentes''
    where id in (
    select a.id from _cartografia.'||tabla||' a
    inner join _cartografia.'||tabla||' b on st_intersects (a.geom,b.geom)
    where a.id <> b.id and a.calle = b.calle
    and a."check" is null
    and b."check" = ''OK''
    and (a.fromleft+a.toleft+a.toright+a.fromright) <>0
    group by a.id
    having count (b.id) >1
    order by a.id);

with 
    comprobar as (
        select a.id,a.calle, 
        string_to_array(string_agg(DISTINCT(b.calle), '','' order by b.calle),'','','''') inter , 
        a.fromleft, a.toleft, a.fromright, a.toright, a.localidad,a."check"
            from 		_Cartografia.'||tabla||' a
            inner join _cartografia.'||tabla||' b 
        on st_intersects (a.geom, b.geom)
        where a.calle <> b.calle and a.id <> b.id
        group by a.id,a.calle,a.fromleft, a.toleft, a.fromright, a.toright, a.localidad, a."check" 
        ), 
        comprobado as (select inter, localidad,fromleft,toleft,fromright,toright from comprobar 
                    where "check" = ''OK'' and array_length(inter, 1) = 2 
                    group by inter, localidad,fromleft,toleft,fromright,toright),
        unsegmento as (SELECT inter, localidad, string_agg(concat(fromleft,'','',toleft,'','',fromright,'','',toright)::text,'','') alturas FROM COMPROBADO group by inter,localidad having count (inter) = 1),
        sindato as (select * from comprobar where "check" is null),
        paralelos as (select a.id from sindato a
        inner join unsegmento b on a.inter = b.inter
        where a."check" is null
        and a.localidad = b.localidad
        and a.fromleft::text = split_part(alturas,'','',1)
        and a.toleft::text = split_part(alturas,'','',2)
        and a.fromright::text = split_part(alturas,'','',3)
        and a.toright::text = split_part(alturas,'','',4))
        update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''paralelos''
        where id in (select id from paralelos)'

)
;
RETURN query execute ('select count(*)::int as cantidad from _cartografia.'||tabla||' where fuente is null;')
;

END
$func$ LANGUAGE plpgsql;

