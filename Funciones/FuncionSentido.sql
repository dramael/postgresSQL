CREATE OR REPLACE FUNCTION _cartografia.sentido(tabla varchar(30)) 
RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE ('
with calles as (select geom, calle,id,sentido from _cartografia.'||tabla||'),
	nodos as (
		-- Genera la matriz de puntos
			select geom, calle from (
				select st_union(geom) as geom, calle  from (select distinct(geom) geom, string_agg(nodo::text,'','') as nodos, calle
				from (
				select id, st_startpoint (((st_dump (geom)).geom)) as geom, calle, 0 as nodo from
				calles
				where calle is not null and sentido is null
				union
				select id, st_endpoint (((st_dump (geom)).geom)) as geom, calle, 1 as nodo from
				calles
				where calle is not null and sentido is null) x
				group by geom,calle
				having count (nodo) >1) x
				where nodos not in (''1,0'', ''0,1'') and length(nodos) <4 group by calle)x),

	unionlinea as (
		-- Genera las lineas base
		select distinct(st_linemerge(st_union(geom))) as geom, calle from calles where calle in (select calle from nodos) group by calle),
	lineadump as (
		--Dump de geometria
		select (st_dump((st_split(st_transform(A.geom,5347) ,st_transform(B.geom,5347))))).geom as geom,
				a.calle
				from unionlinea a
				inner join nodos b on st_intersects (a.geom, b.geom)
				where a.calle = b.calle),
	lineapunto as (
		--Selecciona las lineas que intersectan con los nodos de corto
		SELECT row_number () over () as id, geom, calle from (
			select distinct (A.geom) geom, A.CALLE from lineadump a 
			inner join nodos b on st_intersects (a.geom, b.geom)
			WHERE A.CALLE = B.CALLE)x),
	valor as (
		-- Genera el array de ids
		select a.id,a.geom, a.calle, string_to_array(string_agg(b.id::text,'','' order by b.id),'','') ids from lineapunto a
		inner join calles b on st_within (st_centroid(b.geom), st_buffer(a.geom,5))
		where a.calle = b.calle 
		group by a.id, a.geom, a.calle
		),
	dumppoint as (
		select distinct(geom) geom, row_number()over() numnodos, calle  from (select ((st_dump(geom)).geom) , calle from nodos)x),
	final as (
		select distinct (b.geom) , a.id, a.calle, a.ids, b.numnodos from valor a
		inner join dumppoint b on st_intersects (a.geom, b.geom)
		WHERE a.calle = b.calle),
	posible as (
	select st_reverse(geom) as geom, calle, id from calles where id::text in (select ids  from (select distinct(a.id), a.calle, unnest(a.ids) ids from final a
	inner join final b on a.numnodos = b.numnodos
	where a.id <> b.id
	and array_length(a.ids,1) < array_length(b.ids,1)
	order by 3)x)),
	noes as (
	 select B.IDS from final a
	inner join final b on a.numnodos = b.numnodos
	where a.id <> b.id
	and array_length(a.ids,1) < array_length(b.ids,1))
	update _cartografia.'||tabla||' set geom = st_reverse(geom) where id in (
	select  id from calles where id::text in (select id::text from posible except (select unnest(ids) from noes)) )');
return query execute (
    'select count(*)::int from test.dashbord_'||tabla||' where tipo = ''sentido'''); 
END
$func$ LANGUAGE plpgsql;
