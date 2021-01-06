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
				where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and callesdup = 0
				group by localidad, calle, fromleft, toleft, fromright, toright
				having count (*) <> 1
				union
				select geom, localidad, calle, fromleft, toleft,fromright, toright from (select distinct (id) id, geom,a.localidad, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from i'||tabla||' a 
				inner join (
					select localidad, calle,ind from (
						select localidad, calle, generate_series(min, max) ind from (
							select id, localidad, calle,min(fromleft)min, max(toright)max from i'||tabla||'
						where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and callesdup = 0
						and (fromleft+toleft) <> 0 and (fromright+toright) <>0
						group by localidad,id, calle
						) x
					) a group by localidad, calle, ind having count (concat(localidad, calle, ind)) <> 1
				) b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft+1 and a.toright)) z
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
							where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and contalt = 0
							and (fromleft+toleft) <> 0 and (fromright+toright) <>0
							group by localidad, calle) b
							order by 1,2) a
								)b
					on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)
					where id is null 
				) b on a.localidad = b.localidad and a.calle = b.calle
				and ((a.fromleft+a.toleft+a.fromright+a.toright) <>0 AND a.CALLE IS NOT NULL  and contalt = 0
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
							where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL  and contalt = 0
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
							where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and contalt = 0
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
			and (f.fromleft+f.toleft+f.fromright+f.toright) <>0 AND f.CALLE IS NOT NULL and contalt = 0
							and (f.fromleft+f.toleft) <> 0 and (f.fromright+f.toright) <>0),
base as 
			(select geom,id,calle from i'||tabla||'),
		nodos as
			(select ST_StartPoint ((st_dump(geom)).geom) as geom,id::text,calle, ''inicio'' as tipo from base 
			union all
			select ST_EndPoint ((st_dump(geom)).geom) as geom,id::text,calle, ''fin'' as tipo from base),
		bnodos as 
			(select st_buffer(geom,3) as geom from nodos),
		cantvectores as 
			(select a.geom, count(distinct(b.id)) cantvectores from bnodos a
			inner join base b on st_intersects (a.geom, b.geom)
			group by a.geom),
		cantnodos as (
			select geom, count (geom) as cantnodos from bnodos
			group by 1),
		nodossalida as (
			select (st_dump(st_union(geom))).geom from (
			SELECT a.*, cantnodos from cantvectores a
			inner join cantnodos b on st_astext(a.geom) = st_astext(b.geom))x 
			where cantnodos<>cantvectores),
		nodosbuf as (select * from(select (st_dump(st_union(geom))).geom from bnodos)x
						 where round(st_area(geom)) <> 28),
	primera as (
	select geom from (select * from nodossalida
	union
	select * from nodosbuf)x),
		inter as (
			select (st_dumppoints(ST_Intersection (a.geom, b.geom))).geom as geom
			from base a
			inner join base b on st_intersects(a.geom, b.geom)
			where a.id <> b.id ),
	segunda as
	(select st_buffer(geom,3) from (select geom from inter
	except
	select geom from nodos)x),
dnodos as (
	select distinct (geom), null::text as calle, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
					null::text as localidad,''nodos''::text as tipo  from (select * from primera union select * from segunda) x),
fnodos as (
	select a.geom from dnodos a inner join base b  
	on st_intersects (a.geom, b.geom) group by a.geom having count(b.geom) not in (5,6)),
snodos as (
select * from dnodos where geom in (select geom from fnodos)),
	

sentido as
			(
				
				select ST_StartPoint ((st_dump(geom)).geom) as geom, calle, ''inicio'' as tipo from i'||tabla||'  
	where tcalle is null and calle is not null
	union all
	select ST_EndPoint ((st_dump(geom)).geom) as geom, calle, ''fin'' as tipo from i'||tabla||' 
	where tcalle is null and calle is not null
	order by 1,2,3),

sentido2 as 
	(select geom, calle from sentido
	group by geom, calle
	having count (concat(st_astext(geom), calle)) =2),

sentido3 as 
	(select geom, calle::text, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
				null::text as localidad,''sentido''::text as tipo from (
	(select st_buffer(st_union(geom),10) as geom, calle, tipo from sentido
	 where st_astext (geom) in (select st_astext (geom) from sentido2)
	group by geom, calle, tipo
	having count (concat(st_astext(geom), calle, tipo)) <> 1))x),
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
			select st_buffer(geom,15) as geom , calle::text,fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''inconexos''::text as tipo from _cartografia.'||tabla||' 
			where id in (
				select a.id from _cartografia.'||tabla||' a
				inner join _cartografia.'||tabla||' b on st_intersects(a.geom, b.geom)
				inner join _cartografia.'||tabla||' c on st_intersects(a.geom, c.geom)
				where a.calle = b.calle and a.calle = c.calle and a.id <> b.id and a.id <> c.id and
				((b.fromleft < c.fromleft and a.fromleft <> b.toright+1 and a.toright+1 <> c.fromleft
				and (b.fromleft+b.toleft)<>0 and (b.fromright+b.toright)<>0
				and	(c.fromleft+c.toleft)<>0 and (c.fromright+c.toright) <>0) or
				(b.fromleft < c.fromleft and a.fromleft <> b.toleft+2 and a.toleft+2 <> c.fromleft
				and (b.fromleft+b.toleft) <> 0 and (b.fromright+b.toright)=0
				and	(c.fromleft+c.toleft)<>0 and (c.fromright+c.toright) =0) or
				(b.fromright < c.fromright and a.fromright <> b.toright+2 and a.toright+2 <> c.fromright
				and (b.fromright+b.toright) <> 0 and (b.fromleft+b.toleft)=0
				and	(c.fromright+c.toright)<>0 and (c.fromleft+c.toleft) =0))
				) and inconexos = 0 and ("check"<>''FALSO'' OR "check" is null) 
			and concat(calle, fromleft,toleft,fromright,toright,localidad) not in (
			select concat(calle, fromleft,toleft,fromright,toright,localidad) from callesduplicadas
			union all select concat(calle, fromleft,toleft,fromright,toright,localidad) from continuidadaltura
			union all select concat(calle, fromleft,toleft,fromright,toright,localidad) from continuidadaltura2)
			order by calle,fromleft,fromright,localidad),

		inco1 as 
		(select a.geom,a.id,a.calle,a.tipo,b.id as bid, b.calle as bcalle from nodos a
		inner join nodos b on st_astext(a.geom)=st_astext(b.geom)
		where a.id::int<>b.id::int),

		inco2 as 
		(select id from inco1 where calle=bcalle group by id),

		inco3 as 
		(select id, calle, tipo, bcalle from inco1 
		where id not in(select id from inco2)
		group by id, calle, tipo, bcalle 
		having count (concat(id, calle, tipo, bcalle))=1),

		inco4 as 
		(select id, calle, bcalle from inco3 group by id, calle, bcalle
		having count(concat(id, calle, bcalle))>1),

nombresinconexos as (				 
	select st_buffer(geom,10) as geom, calle, 0 as fromleft,0 as toleft,0 as fromright,0 as toright,null as localidad ,''nombresinconexos'' as tipo from base
	where id::int in (select id::int from inco4 where bcalle is not null) ),


locparinconexos as (


select partido,provincia from _cartografia.'||tabla||'
group by partido,provincia order by count (partido) desc limit 1),
adminconexos2 as
(select a.localidad,a.partido,a.provincia from capas_gral.localidades a inner join locparinconexos b
on a.provincia=b.provincia and (a.partido=b.partido or b.PROVINCIA=''CIUDAD DE BUENOS AIRES'')  
group by a.localidad,a.partido,a.provincia),  
adminconexos3 as
(select st_buffer(geom,10),calle,fromleft,toleft,fromright,toright,localidad,''adminconexos''::text as tipo
from _cartografia.'||tabla||' where trim(concat (localidad,partido,provincia))  
not in (select concat (localidad,partido,provincia) from adminconexos2)),

largo as (
	select st_buffer(geom,10),calle,fromleft,toleft,fromright,toright,localidad,''largo''::text as tipo
	from _cartografia.'||tabla||' where length(st_astext(geom))> 4000)


	select * from frecuencia
	union all 
	select * from callesduplicadas 
	union all 
	select * from continuidadaltura 
	union all 
	select * from snodos 
	union all 
	select * from sentido3
	union all 
	select * from nombre 
	union all
	select * from subdivididos 
	union all 
	select * from continuidadaltura2 
	union all 
	select * from inconexos 
	union all
	select * from nombresinconexos
	union all
	select * from adminconexos3
	union all
	select * from largo
;

	select test.nodos('''||tabla||''');
	drop table if exists test.nodos_'||tabla||';
	drop table if exists test.sub_'||tabla||';
	drop table if exists test.d'||tabla);
RETURN query execute ('
	select tipo, count(*)::int as cantidad from  test.dashbord_'||tabla||' 	group by tipo');

END
$func$ LANGUAGE plpgsql;