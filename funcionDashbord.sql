
CREATE OR REPLACE FUNCTION test.dashbord(tabla varchar(30))   RETURNS TABLE (
	tipo text,
	cantidad int
	
)  AS $func$
BEGIN
EXECUTE (
'drop table if exists test.d'||tabla||' ;
	
create table if not exists test.d'||tabla||' as select id, geom, calle, fromleft,toleft,fromright, toright,
localidad, contnombre,contnombre2, tcalle, "check" from _cartografia.'||tabla||';
drop table if exists test.dasbord_'||tabla||';
	
create table if not exists test.dashbord_'||tabla|| ' as

select * from (
select st_buffer(geom,10) as geom , calle::text, fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''frecuencia''::text as tipo from test.d'||tabla|| '
where 	((tcalle is null or tcalle <> 12) and ("check" <> ''FALSO'' or "check" is null) and (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and (fromleft+toleft) <> 0 and (fromright+toright) <>0) 
and 	((right(toleft::text,1) <> ''8'')and (right(fromleft::text,1) <> ''0'')and (right(fromright::text,1) <> ''1'')and (right(toright::text,1) <> ''9''))
or 	((fromleft > toleft)or (fromright > toright))
or 	(fromleft > fromright and (fromright+toright) <>0)
or 	(toleft > toright and (fromright+toright) <>0)
or 	(toleft+1 <> toright or fromleft+1 <> fromright)
and 	(fromleft+toleft) <> 0
and 	(fromright -1 <> fromleft and (fromright+toright) <>0)
union
select 	st_buffer((st_dump(st_union (geom))).geom,5) as geom,calle, fromleft, toleft,fromright, toright, localidad, ''callesduplicadas'' as tipo from (
	select st_union(geom) as geom,localidad, calle, fromleft,toleft,fromright,toright from test.d'||tabla||'
	where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL
	group by localidad, calle, fromleft, toleft, fromright, toright
	having count (*) <> 1
	union
	select geom, localidad, calle, fromleft, toleft,fromright, toright from (select distinct (id) id, geom,a.localidad, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from test.d'||tabla||' a 
	inner join (
		select localidad, calle,ind from (
			select localidad, calle, generate_series(min, max) ind from (
				select id, localidad, calle,min(fromleft)min, max(toright)max from test.d'||tabla||'
			where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and tcalle is null
			and (fromleft+toleft) <> 0 and (fromright+toright) <>0
			group by localidad,id, calle
			) x
		) a group by localidad, calle, ind having count (concat(localidad, calle, ind)) <> 1
	) b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)) z
) f group by localidad, calle, fromleft, toleft, fromright, toright
union
select st_buffer(E.geom,5) as geom, e.calle, e.fromleft, e.toleft, e.fromright, e.toright, e.localidad, ''continuidadaltura'' as tipo from 
(select distinct (id) id , geom , x.calle, fromleft, toleft, fromright, toright, x.localidad from (
	select  a.*  from test.d'||tabla|| ' a
	inner join (
		select b.localidad,b.calle,ind from test.d'||tabla|| ' a
		right JOIN  
		(
			select  * from (
				select localidad, calle, generate_series(min, max) ind from (
				select localidad, calle,
				min(fromleft)min, max(toright)max from test.d'||tabla|| '
				where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and tcalle is null
				and (fromleft+toleft) <> 0 and (fromright+toright) <>0
				group by localidad, calle) b
				order by 1,2) a
					)b
		 on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)
		where id is null 
	) b on a.localidad = b.localidad and a.calle = b.calle
	and ((a.fromleft+a.toleft+a.fromright+a.toright) <>0 AND a.CALLE IS NOT NULL and a.tcalle is null
			and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) <>0
	and a.toright+1 = b.ind) 
	union
	select a.* from test.d'||tabla|| ' a
	inner join (
		select b.localidad,b.calle,ind from test.d'||tabla|| ' a
		right JOIN  
		(
				select  * from (
				select localidad, calle, generate_series(min, max) ind from (
				select localidad, calle,
				min(fromleft)min, max(toright)max from test.d'||tabla||'  
				where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and tcalle is null
				and (fromleft+toleft) <> 0 and (fromright+toright) <>0
				group by localidad, calle) b
				order by 1,2) a
		)b
		 on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)
		where id is null 
			   ) b on a.localidad = b.localidad and a.calle = b.calle
	and ((a.fromleft+a.toleft+a.fromright+a.toright) <>0 AND a.CALLE IS NOT NULL and a.tcalle is null and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) <>0
	and b.ind+1 between a.fromleft and a.toright) 
	order by id
) x
inner join 
(
select  localidad, calle, min(ind), max(ind) from (
				select localidad, calle, generate_series(min, max) ind from (
				select localidad, calle,
				min(fromleft)min, max(toright)max from test.d'||tabla||'
				where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and tcalle is null
				and (fromleft+toleft) <> 0 and (fromright+toright) <>0
				group by localidad, calle) b
) a group by localidad, calle
) d
on x.localidad = d.localidad and x.calle = d.calle
where fromleft <> min and toright <> max 
) E
left join
test.d'||tabla|| ' f on st_intersects (e.geom, f.geom)
where e.localidad =  f.localidad and e.calle = f.calle and e.id <> f.id
and e.toright +1 <> f.fromleft AND F.TORIGHT+1 <> E.FROMLEFT
and (f.fromleft+f.toleft+f.fromright+f.toright) <>0 AND f.CALLE IS NOT NULL and f.tcalle is null
				and (f.fromleft+f.toleft) <> 0 and (f.fromright+f.toright) <>0
union
select geom,null::text as calle, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
	null::text as localidad, ''nodos''::text as tipo from (select (st_dump(st_union(geom))).geom as geom from (
	select geom
	from (
		select distinct (b.ids)ids , b.geom from (
			select st_union(st_buffer(geom,15)) geom, string_agg(distinct (id)::text,''/'') as ids from (
				select ST_StartPoint ((st_dump(geom)).geom) as geom,id::text, ''inicial'' as tipo from test.d'||tabla|| ' 
				union
				select ST_EndPoint ((st_dump(geom)).geom) as geom,id::text, ''final'' as tipo from test.d'||tabla|| ' 
				union
				select (st_dumppoints(ST_Intersection (a.geom, a.geom))).geom as geom,id::text,''inter'' as tipo from test.d'||tabla|| ' a 
			) a 
		group by st_astext(geom)
		having count (st_astext(geom)) between  2 and 3) b 
	inner join test.d'||tabla|| ' c on st_intersects (b.geom, c.geom)
	where ids <> id::text) d
	union
select geom from (
	select (st_dump(st_union(geom))).geom as geom from (
		select st_buffer((st_dumppoints(ST_Intersection (a.geom, a.geom))).geom,2) as geom from test.d'||tabla|| ' a 
	)a 
	)c where round(st_area(geom)) <> 12 
) x)z
union
	select geom, calle::text, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
		null::text as localidad,''sentido''::text as tipo from (
	select st_buffer(st_union(geom),10) as geom, calle, tipo from  (
		select ST_StartPoint ((st_dump(geom)).geom) as geom, calle, ''inicio'' as tipo from test.d'||tabla||'  
		union all
		select ST_EndPoint ((st_dump(geom)).geom) as geom, calle, ''fin'' as tipo from test.d'||tabla|| '  
		order by 1,2,3)x
	where calle is not null
	group by st_astext(geom), calle, tipo
	having count (concat(st_astext(geom), calle, tipo)) <> 1)x)t;	
	
	
drop table if exists test.d'||tabla) 	
;
	RETURN query execute ('
select tipo, count(*)::int as cantidad from  test.dashbord_'||tabla||' 
group by tipo'
);
		
END
$func$ LANGUAGE plpgsql;