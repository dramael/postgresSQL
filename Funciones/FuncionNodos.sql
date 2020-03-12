CREATE OR REPLACE FUNCTION test.nodos (tabla text) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE ('
drop table if exists test.n'||tabla||';

create table if not exists  test.n'||tabla||' as
select (st_dump(geom)).geom as geom, calle from (select  distinct (a.id) id, st_intersection (a.geom, b.geom) as geom , a.calle
				  from _cartografia.'||tabla||' a 
			inner join _cartografia.'||tabla||' b 
				  on st_intersects (a.geom, b.geom) 
	and a.id <> b.id where a.localidad = b.localidad ) b
where st_astext(geom) not in (
select st_astext((st_dumppoints(ST_Intersection (a.geom, a.geom))).geom) 
	from _cartografia.'||tabla||' a)
	group by geom, calle');
RETURN query execute ( 'select count(*)::int from test.n'||tabla);
END
$func$ LANGUAGE plpgsql;

