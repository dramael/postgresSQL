CREATE OR REPLACE FUNCTION test.blvd(tabla varchar(30)) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (
'create table if not exists test.i'||tabla||' as select id, geom, calle, fromleft,toleft,fromright, toright, localidad, contnombre,contnombre2, tcalle, "check" from _cartografia.'||tabla||';
create table if not exists test.b'||tabla||'  as
    with blvd as (
        select row_number() over () pk, geom,calle,localidad from test.i'||tabla||' 
        where calle in ( 
            select a.calle from test.i'||tabla||' a
        inner join test.i'||tabla||' b on st_distance (st_centroid(a.geom), st_centroid(b.geom)) < 30
        where a.calle = b.calle and a.id <> b.id
            and st_intersects(st_buffer(st_centroid(a.geom),10),st_buffer(st_centroid(a.geom),10))
            and st_length (a.geom) > 15 and st_length (b.geom) > 15
            )),
            ids as (select  unnest(ids)ids from ( 
                select ARRAY_AGG(id)ids from test.i'||tabla||' a
            inner join blvd b
            on st_intersects (a.geom, b.geom)
            where st_length (a.geom) < 35 and a.calle <> b.calle AND (A.FROMLEFT+A.TOLEFT+A.FROMRIGHT+A.TORIGHT) = 0
                    )x),
            upd as (
            update _cartografia.'||tabla||' set tcalle = 12 where concat(localidad,calle) 
            in ( select concat(localidad,calle ) from blvd))
            select array_agg(ids) ids from ids;
          
update _cartografia.'||tabla||' set "check" = ''FALSO'' where id in (select unnest(ids) from test.b'||tabla||');
drop table if exists test.b'||tabla);

return query execute ('select count(*)::int from _cartografia.'||tabla||' where tcalle = 12');
END
$func$ LANGUAGE plpgsql;

