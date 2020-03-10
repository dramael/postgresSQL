CREATE OR REPLACE FUNCTION test.blvd(tabla varchar(30)) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (
'
create table test.blvd as select  (st_dump(st_union(st_buffer(st_centroid(geom),30)))).geom  as geom, calle,localidad 
    from _cartografia.'||tabla||'
    where calle is not null
    group by localidad,calle;
delete from test.blvd where st_area(geom)::text = (select min(st_area(geom)) as area from test.blvd)::text ;
delete from test.blvd where concat(localidad,calle) in (select concat(localidad, calle) from test.blvd group by localidad, calle having count (calle) < 4);

update _cartografia.'||tabla||'  set tcalle = 12 where id in (
    select id 
    from _cartografia.'||tabla||' a
    inner join test.blvd b on concat (b.localidad, b.calle) = concat (a.localidad, a.calle));										

CREATE TABLE TEST.TEST AS select a.id, a.calle,
    ARRAY_AGG(b.calle) as inter  
    from _cartografia.'||tabla||' a, 
    _cartografia.'||tabla||' b
    where st_intersects(a.geom, b.geom) and a.id <> b.id  AND ST_Length(A.GEOM) <20 and B.tcalle = 12
    group by a.calle, a.id
    order by 1;

DELETE FROM TEST.TEST WHERE ID IN (SELECT ID 
    FROM _CARTOGRAFIA.'||tabla||' WHERE TCALLE = 12);

update _cartografia.'||tabla||' 
    set "check" = ''FALSO'' WHERE ID IN( select id from 
    _cartografia.'||tabla||' where id in (
    SELECT ID FROM TEST.TEST
    GROUP BY UNNEST (INTER), ID, CALLE
    having count (inter) > 3));

update _cartografia.'||tabla||' set tcalle = 12 where calle in 
    (select calle from _cartografia.'||tabla||' where tcalle = 12
    and "check" is null or "check" <> ''FALSO''
    group by calle) and tcalle is null;

update _cartografia.'||tabla||' set fromleft = 0 where "check" = ''FALSO'';update _cartografia.'||tabla||' set TOLEFT = 0 where "check" = ''FALSO'';
update _cartografia.'||tabla||' set FROMRIGHT = 0 where "check" = ''FALSO'';update _cartografia.'||tabla||' set TORIGHT = 0 where "check" = ''FALSO'';

DROP TABLE if exists TEST.TEST;DROP TABLE if exists TEST.TEST2;drop table if exists test.blvd;drop table if exists test.test;');

return query execute ('select count(*)::int from _cartografia.'||tabla||' where tcalle = 12');
END
$func$ LANGUAGE plpgsql;

