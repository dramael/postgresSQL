CREATE OR REPLACE FUNCTION test.actualizacionporinterseccion(tabla varchar(30)) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (
'
create table test.act1 as select a.id, a.geom, a.fromleft, a.toleft,a.fromright, a.toright,a.localidad, 
ARRAY_AGG(distinct(b.calle) order by b.calle) AS INTER 
from _cartografia.'||tabla||' a
inner join _cartografia.'||tabla||' b on st_intersects (a.geom, b.geom)
where a.id <> b.id and a.calle <> b.calle and a.calle is not null and b.calle is not null
and (a.fromleft+a.toleft)<>0 and (a.fromright+a.toright) <>0
group by a.id, a.calle, a.localidad order by 1;

delete from test.act1 where array_length(inter,1) <> 2;

create table test.act2 as 
select a.id, a.geom, a.calle, a.fromleft, a.toleft,a.fromright, a.toright,a.localidad,  
ARRAY_AGG(distinct(b.calle) order by b.calle) AS INTER 
from _cartografia.'||tabla||' a
inner join _cartografia.'||tabla||' b on st_intersects (a.geom, b.geom)
where a.id <> b.id and a.calle <> b.calle and a.calle is not null and b.calle is not null 
and a.check is null
and (a.fromleft+a.toleft+a.fromright+a.toright) =0 
group by a.id, a.calle, a.localidad
order by 1;

delete from test.act2 where array_length(inter,1) <> 2;

create table test.act3 as 
select distinct (a.id), b.fromleft, b.toleft, b.fromright, b.toright, a.localidad, 
st_distance(a.geom, b.geom) as dist, 
ROW_NUMBER () OVER (PARTITION BY a.id ORDER BY st_distance(a.geom, b.geom)) as orden
from test.act2 a
inner join test.act1 b on a.inter = b.inter
order by 1;

delete from test.act3
where fromleft = 0 or toleft = 0 or fromright = 0 or toright = 0;

update _cartografia.'||tabla||' a set 	fromleft = b.fromleft,
											toleft = b.toleft,
											fromright = b.fromright,
											toright = b.toright,
											"check" = ''P''
from (select id, fromleft, toleft, fromright, toright, localidad from test.act3
 where orden=1  order by id) b
where a.id = b.id and a.tcalle is null and a.localidad = b.localidad and a.check is null
;

drop table if exists test.act1;drop table if exists test.act2;drop table if exists test.act3');

return query execute ('select count(*)::int from _cartografia.'||tabla||' where "check" = ''P''');
END
$func$ LANGUAGE plpgsql;

