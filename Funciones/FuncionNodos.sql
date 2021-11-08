CREATE OR REPLACE FUNCTION _cartografia.nodos (tabla text) RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE ('
	drop table if exists test.nodos_'||tabla||';

	create table if not exists  test.nodos_'||tabla||' as

	select st_union(geom) as geom, string_agg(calle,'','') as calle from (
	select  (
		st_buffer((st_dump(geom)).geom,10)) as geom, calle from (
																select  distinct (a.id) id, st_intersection (a.geom, b.geom) as geom , a.calle
																from _cartografia.'||tabla||' a 
																inner join _cartografia.'||tabla||' b 
																on st_intersects (a.geom, b.geom) 
																and a.id <> b.id where a.localidad = b.localidad 
		) b
															where st_astext(geom) not in (
																select st_astext((st_dumppoints(ST_Intersection (a.geom, a.geom))).geom) 
																from _cartografia.'||tabla||' a
		)
		group by geom, calle) x
		group by st_astext(geom)'
		
		
		
		
		);
RETURN query execute ( 'select count(*)::int from test.nodos_'||tabla);
END
$func$ LANGUAGE plpgsql;

