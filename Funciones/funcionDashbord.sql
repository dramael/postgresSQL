CREATE OR REPLACE FUNCTION test.dashbord(tabla varchar(30)) RETURNS TABLE (tipo text, cantidad int) AS $func$

BEGIN
EXECUTE (
	'drop table if exists test.d'||tabla||' ;
	create table if not exists test.d'||tabla||' as select id, geom, calle, fromleft,toleft,fromright, toright,	localidad, contnombre, tcalle, "check" from _cartografia.'||tabla||';
	drop table if exists test.dashbord_'||tabla||';
	drop table if exists test.sub_'||tabla||';
	select test.segmentossubdividos('''||tabla||''');
	create table if not exists test.dashbord_'||tabla|| ' as
		with i'||tabla||' as (select * from _cartografia.'||tabla||'),
frecuencia as (
				select st_buffer(geom,10) as geom , calle::text, fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''frecuencia''::text as tipo from i'||tabla||'
				where 	((tcalle is null or tcalle <> 12) and ("check" <> ''FALSO'' or "check" is null) and (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and (fromleft+toleft) <> 0 and (fromright+toright) <>0) 
				and 	((right(fromleft::text,1) <> ''0'') or (right(toleft::text,1) <> ''8'') or (right(fromright::text,1) <> ''1'') or (right(toright::text,1) <> ''9''))
				or 		((fromleft > toleft)or (fromright > toright))
				or 		(fromleft > fromright and (fromright+toright) <>0)
				or 		(toleft > toright and (fromright+toright) <>0)
				or 		(toleft+1 <> toright or fromleft+1 <> fromright)
				and 	(fromleft+toleft) <> 0
				and 	(fromright+toright) <>0
			union
				select st_buffer(geom,10) as geom , calle::text, fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''frecuencia''::text as tipo from i'||tabla||'
				where 	(("check" <> ''FALSO'' or "check" is null) AND (CALLE IS NOT NULL) AND (((fromleft+toleft) <> 0 AND (fromright+toright) = 0) OR ((fromright+toright) <> 0 AND (fromleft+toleft) = 0)))
				and 	(fromleft > toleft and (fromleft+toleft) <> 0) 
				or 		(fromright > toright and fromright + toright <> 0)
				or 		((fromleft+toleft)<>0 and ((right(toleft::text,1) <> ''8'') or (right(fromleft::text,1) <> ''0'')))
				or 		((fromright+toright)<>0 and ((right(toright::text,1) <> ''9'') or (right(fromright::text,1) <> ''1'')))),
callesduplicadas as 
			(select 	st_buffer((st_dump(st_union (geom))).geom,5) as geom,calle, fromleft, toleft,fromright, toright, localidad, ''callesduplicadas'' as tipo from (
				select st_union(geom) as geom,localidad, calle, fromleft,toleft,fromright,toright from i'||tabla||'
				where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL
				group by localidad, calle, fromleft, toleft, fromright, toright
				having count (*) <> 1
				union
				select geom, localidad, calle, fromleft, toleft,fromright, toright from (select distinct (id) id, geom,a.localidad, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from i'||tabla||' a 
				inner join (
					select localidad, calle,ind from (
						select localidad, calle, generate_series(min, max) ind from (
							select id, localidad, calle,min(fromleft)min, max(toright)max from i'||tabla||'
						where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and tcalle is null
						and (fromleft+toleft) <> 0 and (fromright+toright) <>0
						group by localidad,id, calle
						) x
					) a group by localidad, calle, ind having count (concat(localidad, calle, ind)) <> 1
				) b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)) z
			) f group by localidad, calle, fromleft, toleft, fromright, toright),
continuidadaltura as (
			select st_buffer(E.geom,5) as geom, e.calle, e.fromleft, e.toleft, e.fromright, e.toright, e.localidad, ''continuidadaltura'' as tipo from 
			(select distinct (id) id , geom , x.calle, fromleft, toleft, fromright, toright, x.localidad from (
				select  a.*  from i'||tabla||' a
				inner join (
					select b.localidad,b.calle,ind from i'||tabla||' a
					right JOIN  
					(
						select  * from (
							select localidad, calle, generate_series(min, max) ind from (
							select localidad, calle,
							min(fromleft)min, max(toright)max from i'||tabla||'
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
				select a.* from i'||tabla||' a
				inner join (
					select b.localidad,b.calle,ind from i'||tabla||' a
					right JOIN  
					(
							select  * from (
							select localidad, calle, generate_series(min, max) ind from (
							select localidad, calle,
							min(fromleft)min, max(toright)max from i'||tabla||'  
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
							min(fromleft)min, max(toright)max from i'||tabla||'
							where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and tcalle is null
							and (fromleft+toleft) <> 0 and (fromright+toright) <>0
							group by localidad, calle) b
			) a group by localidad, calle
			) d
			on x.localidad = d.localidad and x.calle = d.calle
			where fromleft <> min and toright <> max 
			) E
			left join
			i'||tabla||' f on st_intersects (e.geom, f.geom)
			where e.localidad =  f.localidad and e.calle = f.calle and e.id <> f.id
			and e.toright +1 <> f.fromleft AND F.TORIGHT+1 <> E.FROMLEFT
			and (f.fromleft+f.toleft+f.fromright+f.toright) <>0 AND f.CALLE IS NOT NULL and f.tcalle is null
							and (f.fromleft+f.toleft) <> 0 and (f.fromright+f.toright) <>0),
nodos as 
			(select geom,null::text as calle, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
				null::text as localidad, ''nodos''::text as tipo from (select (st_dump(st_union(geom))).geom as geom from (
				select geom
				from (
					select distinct (b.ids)ids , b.geom from (
						select st_union(st_buffer(geom,15)) geom, string_agg(distinct (id)::text,''/'') as ids from (
							select ST_StartPoint ((st_dump(geom)).geom) as geom,id::text, ''inicial'' as tipo from i'||tabla||' 
							union
							select ST_EndPoint ((st_dump(geom)).geom) as geom,id::text, ''final'' as tipo from i'||tabla||' 
							union
							select (st_dumppoints(ST_Intersection (a.geom, a.geom))).geom as geom,id::text,''inter'' as tipo from i'||tabla||' a 
						) a 
					group by st_astext(geom)
					having count (st_astext(geom)) between  2 and 3) b 
				inner join i'||tabla||' c on st_intersects (b.geom, c.geom)
				where ids <> id::text) d
				union
			select geom from (
				select (st_dump(st_union(geom))).geom as geom from (
					select st_buffer((st_dumppoints(ST_Intersection (a.geom, a.geom))).geom,2) as geom from i'||tabla||' a 
				)a 
				)c where round(st_area(geom)) <> 12 
			) x)z),
sentido as
			(select geom, calle::text, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
				null::text as localidad,''sentido''::text as tipo from (
			select st_buffer(st_union(geom),10) as geom, calle, tipo from  (
				select ST_StartPoint ((st_dump(geom)).geom) as geom, calle, ''inicio'' as tipo from i'||tabla||'  
				where tcalle is null
				union all
				select ST_EndPoint ((st_dump(geom)).geom) as geom, calle, ''fin'' as tipo from i'||tabla||'  
				where tcalle is null
				order by 1,2,3)x
			where calle is not null
			group by st_astext(geom), calle, tipo
			having count (concat(st_astext(geom), calle, tipo)) <> 1)x),
nombre as
			(select null::geometry(polygon,5347) geom,
			concat( ''("calle"= '', k ,acalle,k,'' or "calle"=  '',k, bcalle ,k,'' ) and "localidad" =  '',k, f.localidad,k) as calle, 
			null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
			null::text as localidad, ''nombre''::text as tipo
			from i'||tabla||'   a
			inner join singlequote on k <> ''calle''
			inner join 
			(select localidad, acalle, bcalle
			from (
				select distinct on (acalleandbcalle) id, localidad, acalle, bcalle  from(select id,localidad,
				case when 
				acalle > bcalle then ARRAY[acalle, bcalle]
				else ARRAY[bcalle, acalle]
				end acalleandbcalle,
				acalle,
				bcalle
				from (
					select ROW_NUMBER() OVER() ID, c.localidad, acalle,bcalle  from (
					SELECT a.localidad, a.calle acalle, b.calle bcalle FROM (
						SELECT LOCALIDAD, CALLE FROM i'||tabla||'  
						WHERE CALLE IS NOT NULL AND CONTNOMBRE = 0
						GROUP BY 1,2
					) A
					INNER JOIN (
					SELECT LOCALIDAD, CALLE FROM i'||tabla||' 
					WHERE CALLE IS NOT NULL AND CONTNOMBRE = 0
					GROUP BY 1,2 
					) B ON A.LOCALIDAD = B.LOCALIDAD 
					WHERE SIMILARITY(A.CALLE ,B.CALLE) > 0.45
					AND A.CALLE <> B.CALLE)c
					where acalle not like ''%NORTE'' and acalle not like ''%SUR'' and acalle not like ''%ESTE'' and acalle not like ''%OESTE'' AND Bcalle not like ''%NORTE'' and Bcalle not like ''%SUR'' and
					bcalle not like ''%ESTE'' and bcalle not like ''%OESTE''  AND acalle NOT LIKE ''PJE%'' AND BCALLE NOT LIKE ''PJE%''
					and acalle not like ''%BIS'' and bcalle not like ''%BIS'' and acalle not like ''%CALLE%'' AND BCALLE NOT LIKE ''%CALLE%''
					AND acalle not like ''%DIAGONAL%'' AND bcalle not like ''%DIAGONAL%'' 
					order by 1,2,3
				) x
				order by 3) x
			) f order by 2,3)f
			on a.localidad = f.localidad and (a.calle = f.acalle or a.calle = f.bcalle)
			group by acalle, bcalle, f.localidad,k),
subdivididos as
			(select st_buffer(geom,10) as geom, calle::text, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,  null::text as localidad,''subdividido''::text as tipo
			from test.sub_'||tabla||'),
continuidadaltura2 as 
			(select st_buffer(geom,15) as geom , calle::text,fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''callesduplicadas''::text as tipo from (
				select st_buffer((st_dump(st_union (geom))).geom,15) as geom,localidad, calle, fromleft,toleft,fromright,toright from 
					(select geom, localidad, calle, fromleft, toleft,fromright, toright from 
						(
							select distinct (id) id, geom, a.localidad, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from i'||tabla||'  a 
							inner join (select localidad, calle,ind from 
								(select localidad, calle, generate_series(min, max) ind from 
									(select  ID,localidad, calle,min(fromleft)min, max(toleft)max from i'||tabla||' 
									where (fromleft+toleft) <> 0 AND (fromright+toright) = 0 and CALLE IS NOT NULL 
									group by ID,localidad, calle
									)x 
								) a group by localidad, calle, ind having count (concat(localidad, calle, ind)) <> 1
							) b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)
						) z
					) f group by localidad, calle, fromleft, toleft, fromright, toright

				union
				select (st_dump(st_union (geom))).geom as geom,localidad, calle, fromleft,toleft,fromright,toright from 
					(select geom, localidad, calle, fromleft, toleft,fromright, toright from 
						(
							select distinct (id) id, geom, a.localidad, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from i'||tabla||'  a 
							inner join (select localidad, calle,ind from 
								(select localidad, calle, generate_series(min, max) ind from 
									(select  ID,localidad, calle,min(fromright)min, max(toright)max from i'||tabla||' 
									where (fromright+toright) <> 0 AND (fromleft+toleft) = 0 and CALLE IS NOT NULL 
									group by ID,localidad, calle
									)x
								) a group by localidad, calle, ind having count (concat(localidad, calle, ind)) <> 1
							) b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)
						) z
			) f group by localidad, calle, fromleft, toleft, fromright, toright)x
		union -- continuidadaltura
			select st_buffer(geom,15) as geom, calle::text, fromleft::int, toleft::int, fromright::int, toright::int, localidad::text, ''continuidadaltura''::text as tipo  from ((select E.* from 
				(select distinct (id) id , st_buffer(geom,10) as geom , x.calle, fromleft, toleft, fromright, toright, x.localidad from (
					select  a.*  from i'||tabla||'  a
					inner join (
						select b.localidad,b.calle,ind from i'||tabla||'  a
						right JOIN   
						(
							select  * from (
								select localidad, calle, generate_series(min, max) ind from (
								select localidad, calle,
								min(fromright)min, max(toright)max from i'||tabla||' 
								where (fromright+toright) = 0 and (fromright+toright) <> 0 AND CALLE IS NOT NULL 
								group by localidad, calle) b
								order by 1,2) a 
									)b
						on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)
						where id is null -- Devuelve los valores que no se encuentra en la secuencia total x localidad y calle

					) b on a.localidad = b.localidad and a.calle = b.calle
					and ((a.fromright+a.toright) <> 0 and (fromleft+a.toleft) = 0 AND a.CALLE IS NOT NULL
								and a.toright+1 = b.ind) 
					union
					select a.* from i'||tabla||'  a
					inner join (

						select b.localidad,b.calle,ind from i'||tabla||'  a
						right JOIN  
						(
								select  * from (
								select localidad, calle, generate_series(min, max) ind from (
								select localidad, calle,
								min(fromright)min, max(toright)max from i'||tabla||' 
								where CALLE IS NOT NULL 
								and (fromright+toright) <> 0 and (fromleft + toleft) = 0
								group by localidad, calle) b
								order by 1,2) a
						)b
						on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)
						where id is null -- Devuelve los valores que no se encuentra en la secuencia total x localidad y calle
							) b on a.localidad = b.localidad and a.calle = b.calle
					and (a.CALLE IS NOT NULL  and (a.fromright+a.toright) <> 0 and (a.fromleft+a.toleft) = 0
					and b.ind+1 between a.fromright and a.toright)
					order by id
				) x
				inner join 
				(
				select  localidad, calle, min(ind), max(ind) from (
								select localidad, calle, generate_series(min, max) ind from (
								select localidad, calle,
								min(fromright)min, max(toright)max from i'||tabla||' 
								where CALLE IS NOT NULL 
								and (fromright+toright) <> 0 and (fromleft+toleft) = 0
								group by localidad, calle) b
				) a group by localidad, calle 
				) d
				on x.localidad = d.localidad and x.calle = d.calle
				where fromright <> min and toright <> max 
				) E
				right join
				i'||tabla||'  f on st_intersects (e.geom, f.geom)
				where e.localidad =  f.localidad and e.calle = f.calle and e.id <> f.id
				and e.toright + 2 <> f.fromright AND F.TOright+ 2 <> E.FROMright and
				f.CALLE IS NOT NULL 
								and (f.fromright+f.toright) <> 0 and (f.fromleft+f.toleft) = 0
				order by e.localidad, e.calle)
				union
				(select E.* from 
				(select distinct (id) id , geom , x.calle, fromleft, toleft, fromright, toright, x.localidad from (
					select  a.*  from i'||tabla||'  a
					inner join (
						select b.localidad,b.calle,ind from i'||tabla||'  a
						right JOIN   
						(
							select  * from (
								select localidad, calle, generate_series(min, max) ind from (
								select localidad, calle,
								min(fromleft)min, max(toleft)max from i'||tabla||' 
								where (fromleft+toleft) <>0 and (fromright+toright) = 0 AND CALLE IS NOT NULL 
								group by localidad, calle) b
								order by 1,2) a 
									)b
						on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)
						where id is null 

					) b on a.localidad = b.localidad and a.calle = b.calle
					and ((a.fromleft+a.toleft) <> 0 and (fromright+a.toright) = 0 AND a.CALLE IS NOT NULL
								and a.toleft+1 = b.ind) 
					union
					select a.* from i'||tabla||'  a
					inner join (

						select b.localidad,b.calle,ind from i'||tabla||'  a
						right JOIN  
						(
								select  * from (
								select localidad, calle, generate_series(min, max) ind from (
								select localidad, calle,
								min(fromleft)min, max(toleft)max from i'||tabla||' 
								where CALLE IS NOT NULL 
								and (fromleft+toleft) <> 0 and (fromright+toright) = 0
								group by localidad, calle) b
								order by 1,2) a -- Devuelve la secuenca total x localidad y calle
						)b
						on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)
						where id is null -- Devuelve los valores que no se encuentra en la secuencia total x localidad y calle
							) b on a.localidad = b.localidad and a.calle = b.calle
					and (a.CALLE IS NOT NULL  and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) = 0
					and b.ind+1 between a.fromleft and a.toleft) 
					order by id
				) x -- Devuelve todos los registros incorrectos
				inner join 
				(
				select  localidad, calle, min(ind), max(ind) from (
								select localidad, calle, generate_series(min, max) ind from (
								select localidad, calle,
								min(fromleft)min, max(toleft)max from i'||tabla||' 
								where CALLE IS NOT NULL 
								and (fromleft+toleft) <> 0 and (fromright+toright) = 0
								group by localidad, calle) b
				) a group by localidad, calle
				) d
				on x.localidad = d.localidad and x.calle = d.calle
				where fromleft <> min and toright <> max
				) E
				left join
				i'||tabla||'  f on st_intersects (e.geom, f.geom)
				where e.localidad =  f.localidad and e.calle = f.calle and e.id <> f.id
				and e.toleft + 2 <> f.fromleft AND F.TOLEFT+ 2 <> E.FROMLEFT and
				f.CALLE IS NOT NULL 
								and (f.fromleft+f.toleft) <> 0 and (f.fromright+f.toright) = 0
				order by e.localidad, e.calle))x),
inconexos as (
			select st_buffer(geom,15) as geom , calle::text,fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''inconexos''::text as tipo from _cartografia.'||tabla||' where id in (
				select a.id from _cartografia.'||tabla||' a
				inner join _cartografia.'||tabla||' b on st_intersects(a.geom, b.geom)
				inner join _cartografia.'||tabla||' c on st_intersects(a.geom, c.geom)
				where a.calle = b.calle and a.calle = c.calle
				and b.fromleft < c.fromleft and a.fromleft <> b.toright+1 and a.toright+1 <> c.fromleft
				and a.id <> b.id and a.id <> c.id
				and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) <>0 and
					 (b.fromleft+b.toleft) <> 0 and (b.fromright+b.toright) <> 0 and
					 (c.fromleft+c.toleft)<> 0 and (c.fromright+c.toright) <>0
			) and (fromleft+toleft) <> 0 and (fromright+toright) <>0 and tcalle is null
			and concat(calle, fromleft,toleft,fromright,toright,localidad) not in (
			select concat(calle, fromleft,toleft,fromright,toright,localidad) from callesduplicadas
			union all select concat(calle, fromleft,toleft,fromright,toright,localidad) from continuidadaltura
			union all select concat(calle, fromleft,toleft,fromright,toright,localidad) from continuidadaltura2)) 
	select * from frecuencia union all select * from callesduplicadas union all select * from continuidadaltura union all select * from nodos 
	union all select * from sentido union all select * from nombre union  select * from subdivididos union select * from continuidadaltura2 union select * from inconexos;

	select test.frecuencia('''||tabla||''');
	drop table if exists test.d'||tabla);
RETURN query execute ('
	select tipo, count(*)::int as cantidad from  test.dashbord_'||tabla||' 	group by tipo');

END
$func$ LANGUAGE plpgsql;