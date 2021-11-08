CREATE OR REPLACE FUNCTION _cartografia.segmentossubdividos(tabla varchar(30)) 
RETURNS TABLE (cantidad int) AS $func$
BEGIN
EXECUTE (
	'
	drop table if exists test.sub_'||tabla||';
	create table if not exists test.d'||tabla||' as select id, geom, calle, fromleft,toleft,fromright, toright,	localidad, contnombre, tcalle, "check" from _cartografia.'||tabla||';
	create table if not exists test.sub_'||tabla||' as 
	with calles as (
		select row_number() over () pk, calles, ids from (select st_union(geom) as geom, string_agg(calle,'',''order by calle desc)calles, 
		string_agg(id::Text,'','' order by id asc) as ids  from (
		select ST_StartPoint((st_dump(geom)).geom) as geom, id,calle, fromleft,toleft,fromright,toright from test.d'||tabla||'
		union
		select ST_EndPoint((st_dump(geom)).geom) as geom, id,calle, fromleft,toleft,fromright,toright from test.d'||tabla||'
		) a
		group by st_astext(geom)
		having count (st_Astext(geom)) = 2) b
		where split_part(calles,'','',1) = split_part(calles,'','',2)
		),
		correcto as (
			select a.pk, a.ids from calles a
			inner join calles b on a.calles = b.calles
			where string_to_array(a.ids,'','',''['') && string_to_array(b.ids,'','',''['') or string_to_array(b.ids,'','',''['') && string_to_array(a.ids,'','',''['')
			group by a.pk, a.ids
			having count (a.pk::text) = 1
			), 
			Sinsertar as (
				select ST_LineMerge(st_union(geom)) as geom, calle, 
				min(fromleft)fromleft, max(toleft)toleft, min (fromright)fromright, max(toright)toright, b.ids 
				from test.d'||tabla||' a
				inner join correcto b on a.id::text in (split_part(ids,'','',1) , split_part(ids,'','',2))
				group by pk, calle, b.ids
			), 
			insertar as (
					insert into _cartografia.'||tabla||' (geom, calle, fromleft, toleft, fromright, toright) 
					select st_multi(geom), calle, fromleft, toleft, fromright, toright from Sinsertar),
			borrado as (
					delete from _cartografia.'||tabla||' where id::text in 	(select unnest(string_to_array(ids,'','',''['')) from Sinsertar))
			
			select distinct((st_dump(st_linemerge(st_union(geom)))).geom )as geom, calle from test.d'||tabla||' a
			inner join calles b on a.id::text in	(select unnest(string_to_array(ids,'','',''['')) from calles a)
			where id::text in 						(select unnest(string_to_array(ids,'','',''['')) from calles a)
			and id::text not in 					(select unnest(string_to_array(ids,'','',''['')) from Sinsertar)
			group by calle,pk;'

);
return query execute ('
	select count(*)::int from test.sub_'||tabla); 
END
$func$ LANGUAGE plpgsql;










