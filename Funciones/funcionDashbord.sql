-- FUNCTION: _cartografia.dashbord(character varying)

-- DROP FUNCTION _cartografia.dashbord(character varying);

CREATE OR REPLACE FUNCTION _cartografia.dashbord(
	tabla character varying)
    RETURNS TABLE(tipo text, cantidad integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN

EXECUTE ('
		 
drop table if exists test.dashbord_'||tabla||' ;create table if not exists test.dashbord_'||tabla||' as
with base as (select * from _cartografia.'||tabla||'),

frecuencia_salida as (
	select st_buffer(geom,10) as geom , calle::text, fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''frecuencia''::text as tipo from base
	where 	((tcalle <> 12) and ("check" <> ''FALSO'' or "check" is null) and (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and (fromleft+toleft) <> 0 and (fromright+toright) <>0) 
	and 	((right(fromleft::text,1) <> ''0'') or (right(toleft::text,1) <> ''8'') or (right(fromright::text,1) <> ''1'') or (right(toright::text,1) <> ''9''))
	or 		((fromleft > toleft)or (fromright > toright))
	or 		(fromleft > fromright and (fromright+toright) <>0)
	or 		(toleft > toright and (fromright+toright) <>0)
	or 		(toleft+1 <> toright or fromleft+1 <> fromright)
	and 	(fromleft+toleft) <> 0
	and 	(fromright+toright) <>0
	union
	select st_buffer(geom,10) as geom , calle::text, fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''frecuencia''::text as tipo from base
	where 	(("check" <> ''FALSO'' or "check" is null) AND (CALLE IS NOT NULL) AND (((fromleft+toleft) <> 0 AND (fromright+toright) = 0) OR ((fromright+toright) <> 0 AND (fromleft+toleft) = 0)))
	and 	(fromleft > toleft and (fromleft+toleft) <> 0) 
	or 		(fromright > toright and fromright + toright <> 0)
	or 		((fromleft+toleft)<>0 and ((right(toleft::text,1) <> ''8'') or (right(fromleft::text,1) <> ''0'')))
	or 		((fromright+toright)<>0 and ((right(toright::text,1) <> ''9'') or (right(fromright::text,1) <> ''1'')))),

callesduplicadas_salida as (
	select 	st_buffer((st_dump(st_union (geom))).geom,10) as geom,calle, fromleft, toleft,fromright, toright, localidad, ''callesduplicadas'' as tipo from (
		select st_union(geom) as geom,localidad, calle, fromleft,toleft,fromright,toright from base
		where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and callesdup = 0
		group by localidad, calle, fromleft, toleft, fromright, toright
		having count (*) <> 1
		union
		select geom, localidad, calle, fromleft, toleft,fromright, toright from (select distinct (id) id, geom,a.localidad, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from base a 
		inner join (
			select localidad, calle,ind from (
				select localidad, calle, generate_series(min, max) ind from (
					select id, localidad, calle,min(fromleft)min, max(toright)max from base
					where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and callesdup = 0
					and (fromleft+toleft) <> 0 and (fromright+toright) <>0
					group by localidad,id, calle)x
			)a group by localidad, calle, ind having count (concat(localidad, calle, ind)) <> 1
		)b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft+1 and a.toright)) z
	)f group by localidad, calle, fromleft, toleft, fromright, toright),

continuidadaltura_salida as (
	select st_buffer(E.geom,10) as geom, e.calle, e.fromleft, e.toleft, e.fromright, e.toright, e.localidad, ''continuidadaltura'' as tipo from (
		select distinct (id) id , geom , x.calle, fromleft, toleft, fromright, toright, x.localidad from (
			select  a.*  from base a
			inner join (
				select b.localidad,b.calle,ind from base a
				right JOIN ( 
					select  * from (
						select localidad, calle, generate_series(min, max) ind from (
							select localidad, calle,
							min(fromleft)min, max(toright)max from base
							where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and contalt = 0
							and (fromleft+toleft) <> 0 and (fromright+toright) <>0
							group by localidad, calle) b
							order by 1,2) a
				 )b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)
				 where id is null 
			)b on a.localidad = b.localidad and a.calle = b.calle
			and ((a.fromleft+a.toleft+a.fromright+a.toright) <>0 AND a.CALLE IS NOT NULL  and contalt = 0
				and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) <>0
				and a.toright+1 = b.ind) 
			union
			select a.* from base a
			inner join (
				select b.localidad,b.calle,ind from base a
				right JOIN (
		 			select  * from (
						select localidad, calle, generate_series(min, max) ind from (
							select localidad, calle,
							min(fromleft)min, max(toright)max from base  
							where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL  and contalt = 0
							and (fromleft+toleft) <> 0 and (fromright+toright) <>0
							group by localidad, calle) b
						order by 1,2) a
				)b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)
				where id is null 
			) b on a.localidad = b.localidad and a.calle = b.calle
			and ((a.fromleft+a.toleft+a.fromright+a.toright) <>0 AND a.CALLE IS NOT NULL and a.tcalle = 0 and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) <>0
			and b.ind+1 between a.fromleft and a.toright) 
			order by id)x
		inner join (	
			select  localidad, calle, min(ind), max(ind) from (
				select localidad, calle, generate_series(min, max) ind from (
					select localidad, calle,
					min(fromleft)min, max(toright)max from base
					where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and contalt = 0
					and (fromleft+toleft) <> 0 and (fromright+toright) <>0
					group by localidad, calle) b
				)a group by localidad, calle
		)d on x.localidad = d.localidad and x.calle = d.calle
		where fromleft <> min and toright <> max)E
		left join
		base f on st_intersects (e.geom, f.geom)
		where e.localidad =  f.localidad and e.calle = f.calle and e.id <> f.id
		and e.toright +1 <> f.fromleft AND F.TORIGHT+1 <> E.FROMLEFT
		and (f.fromleft+f.toleft+f.fromright+f.toright) <>0 AND f.CALLE IS NOT NULL and contalt = 0
		and (f.fromleft+f.toleft) <> 0 and (f.fromright+f.toright) <>0),

nodos as (
	select ST_StartPoint ((st_dump(geom)).geom) as geom,id::text,calle, ''inicio'' as tipo from base 
	union all
	select ST_EndPoint ((st_dump(geom)).geom) as geom,id::text,calle, ''fin'' as tipo from base),
bnodos as (
	select st_buffer(geom,3) as geom from nodos),
cantvectores as (
	select a.geom, count(distinct(b.id)) cantvectores from bnodos a
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
nodosbuf as (
	select * from(select (st_dump(st_union(geom))).geom from bnodos)x
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
segunda as (
	select st_buffer(geom,3) from (select geom from inter
	except
	select geom from nodos)x),
dnodos as (
	select distinct (geom), null::text as calle, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
					null::text as localidad,''nodos''::text as tipo  from (select * from primera union select * from segunda) x),
fnodos as (
	select a.geom from dnodos a inner join base b  
	on st_intersects (a.geom, b.geom) group by a.geom having count(b.geom) not in (5,6)),
nodos_salida as (
	select * from dnodos where geom in (select geom from fnodos)),
	
sentido as(
	select ST_StartPoint ((st_dump(geom)).geom) as geom, calle, ''inicio'' as tipo from base  
	where calle is not null and sentido <> ''1''
	union all
	select ST_EndPoint ((st_dump(geom)).geom) as geom, calle, ''fin'' as tipo from base 
	where calle is not null and sentido <> ''1''
	order by 1,2,3),
sentido2 as (
	select geom, calle from sentido
	group by geom, calle
	having count (concat(st_astext(geom), calle)) =2),
sentido_salida as (
	select geom, calle::text, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright,
				null::text as localidad,''sentido''::text as tipo from (
	(select st_buffer(st_union(geom),10) as geom, calle, tipo from sentido
	 where st_astext (geom) in (select st_astext (geom) from sentido2)
	group by geom, calle, tipo
	having count (concat(st_astext(geom), calle, tipo)) <> 1))x),
	
lines as (
	select geom,st_linemerge(st_makeline(punto order by path))linea,calle,localidad from (
		select geom,(st_dumppoints(geom)).geom punto,(st_dumppoints(geom)).path ,calle,localidad from (
			select st_linemerge(st_union(geom))geom,calle,localidad from base where contnombre=0 and calle is not null and
 		 	calle not like all (array[''% NORTE'',''% SUR'',''% ESTE'',''% OESTE'',''% BIS'',''CALLE %'',''PJE %'',''DIAGONAL %'',''RP %'',''RN %''])
 	     	group by calle,localidad)X)Y 
 	group by calle, localidad, geom),								   
nombre_salida as (
	select st_buffer(st_union(ageom,bgeom),10)geom,concat(''("calle" = '',(SELECT k FROM singlequote), acalle,(SELECT k FROM singlequote),'' or "calle" = '',(SELECT k FROM singlequote),bcalle,(SELECT k FROM singlequote),'') and "localidad" = '',(SELECT k FROM singlequote), localidad,(SELECT k FROM singlequote)) as calle,0 as fromleft,0 as toleft, 0 as fromright,0 as toright,localidad,''nombre'' as tipo from (
		select a.geom ageom,a.calle acalle,b.geom bgeom,b.calle bcalle,a.localidad,
		degrees(st_angle(st_startpoint(a.linea),st_endpoint(a.linea),(st_dump(st_boundary(b.linea))).geom))angle_ab, 
		degrees(st_angle(st_startpoint(b.linea),st_endpoint(b.linea),(st_dump(st_boundary(a.linea))).geom))angle_ba 
		from lines a 
		inner join lines b on a.calle<>b.calle and similarity(a.calle,b.calle)>0.4 and a.localidad =b.localidad and a.calle<=b.calle)x
	where (angle_ab between 175 and 190 or angle_ab between 0 and 5 or angle_ab between 355 and 360) and
	(angle_ba between 175 and 190 or angle_ba between 0 and 5 or angle_ba between 355 and 360)								
	group by acalle,ageom,bcalle,bgeom,localidad),

continuidadaltura2_salida as (
	select st_buffer(geom,10) as geom , calle::text,fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''callesduplicadas''::text as tipo from (
		select st_buffer((st_dump(st_union (geom))).geom,15) as geom,localidad, calle, fromleft,toleft,fromright,toright from 
			(select geom, localidad, calle, fromleft, toleft,fromright, toright from 
				(select distinct (id) id, geom, a.localidad, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from base  a 
				 inner join (select localidad, calle,ind from 
					(select localidad, calle, generate_series(min, max) ind from 
						(select  ID,localidad, calle,min(fromleft)min, max(toleft)max from base 
				    	 where (fromleft+toleft) <> 0 AND (fromright+toright) = 0 and CALLE IS NOT NULL 
						 group by ID,localidad, calle)x 
					 ) a group by localidad, calle, ind having count (concat(localidad, calle, ind)) <> 1
				 ) b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)) z
			 )f group by localidad, calle, fromleft, toleft, fromright, toright
		union
		select (st_dump(st_union (geom))).geom as geom,localidad, calle, fromleft,toleft,fromright,toright from 
			(select geom, localidad, calle, fromleft, toleft,fromright, toright from 
				(select distinct (id) id, geom, a.localidad, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from base  a 
				 inner join (select localidad, calle,ind from 
					(select localidad, calle, generate_series(min, max) ind from 
						(select  ID,localidad, calle,min(fromright)min, max(toright)max from base 
				    	 where (fromright+toright) <> 0 AND (fromleft+toleft) = 0 and CALLE IS NOT NULL 
						 group by ID,localidad, calle)x
					 ) a group by localidad, calle, ind having count (concat(localidad, calle, ind)) <> 1
				 ) b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)) z
			 )f group by localidad, calle, fromleft, toleft, fromright, toright)x
		union -- continuidadaltura
		select st_buffer(geom,10) as geom, calle::text, fromleft::int, toleft::int, fromright::int, toright::int, localidad::text, ''continuidadaltura''::text as tipo  from ((select E.* from 
			(select distinct (id) id , st_buffer(geom,10) as geom , x.calle, fromleft, toleft, fromright, toright, x.localidad from (
				select  a.*  from base  a
				inner join (
					select b.localidad,b.calle,ind from base  a
					right JOIN   
						(select  * from (
							select localidad, calle, generate_series(min, max) ind from (
								select localidad, calle,
								min(fromright)min, max(toright)max from base 
								where (fromright+toright) = 0 and (fromright+toright) <> 0 AND CALLE IS NOT NULL 
								group by localidad, calle) b
						order by 1,2) a )b
					on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)
					where id is null 
				 ) b on a.localidad = b.localidad and a.calle = b.calle
				 and ((a.fromright+a.toright) <> 0 and (fromleft+a.toleft) = 0 AND a.CALLE IS NOT NULL
				 and a.toright+1 = b.ind) 
				union
				select a.* from base  a
				inner join (
					select b.localidad,b.calle,ind from base  a
					right JOIN  
						(select  * from (
							select localidad, calle, generate_series(min, max) ind from (
								select localidad, calle,
								min(fromright)min, max(toright)max from base 
								where CALLE IS NOT NULL 
								and (fromright+toright) <> 0 and (fromleft + toleft) = 0
								group by localidad, calle) b
							order by 1,2) a)b
					on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)
					where id is null -- Devuelve los valores que no se encuentra en la secuencia total x localidad y calle
				) b on a.localidad = b.localidad and a.calle = b.calle
				and (a.CALLE IS NOT NULL  and (a.fromright+a.toright) <> 0 and (a.fromleft+a.toleft) = 0
				and b.ind+1 between a.fromright and a.toright)
				order by id) x
			inner join 
				(select  localidad, calle, min(ind), max(ind) from (
					select localidad, calle, generate_series(min, max) ind from (
						select localidad, calle,
						min(fromright)min, max(toright)max from base 
						where CALLE IS NOT NULL 
						and (fromright+toright) <> 0 and (fromleft+toleft) = 0
						group by localidad, calle) b
					) a group by localidad, calle ) d
			on x.localidad = d.localidad and x.calle = d.calle
			where fromright <> min and toright <> max) E
			right join
			base  f on st_intersects (e.geom, f.geom)
			where e.localidad =  f.localidad and e.calle = f.calle and e.id <> f.id
			and e.toright + 2 <> f.fromright AND F.TOright+ 2 <> E.FROMright and
			f.CALLE IS NOT NULL 
			and (f.fromright+f.toright) <> 0 and (f.fromleft+f.toleft) = 0
			order by e.localidad, e.calle)
			union
			(select E.* from 
				(select distinct (id) id , geom , x.calle, fromleft, toleft, fromright, toright, x.localidad from (
					select  a.*  from base  a
					inner join (
						select b.localidad,b.calle,ind from base  a
						right JOIN   
							(select  * from (
								select localidad, calle, generate_series(min, max) ind from (
									select localidad, calle,
									min(fromleft)min, max(toleft)max from base 
									where (fromleft+toleft) <>0 and (fromright+toright) = 0 AND CALLE IS NOT NULL 
									group by localidad, calle) b
								order by 1,2) a )b
						on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)
						where id is null 
					) b on a.localidad = b.localidad and a.calle = b.calle
					and ((a.fromleft+a.toleft) <> 0 and (fromright+a.toright) = 0 AND a.CALLE IS NOT NULL
					and a.toleft+1 = b.ind) 
					union
					select a.* from base  a
					inner join (
						select b.localidad,b.calle,ind from base  a
						right JOIN  
							(select  * from (
								select localidad, calle, generate_series(min, max) ind from (
									select localidad, calle,
									min(fromleft)min, max(toleft)max from base 
									where CALLE IS NOT NULL 
									and (fromleft+toleft) <> 0 and (fromright+toright) = 0
									group by localidad, calle) b
								order by 1,2) a -- Devuelve la secuenca total x localidad y calle
						)b on (a.localidad = b.localidad and a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)
						where id is null -- Devuelve los valores que no se encuentra en la secuencia total x localidad y calle
					)b on a.localidad = b.localidad and a.calle = b.calle
					and (a.CALLE IS NOT NULL  and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) = 0
					and b.ind+1 between a.fromleft and a.toleft) 
					order by id
				) x -- Devuelve todos los registros incorrectos
				inner join 
					(select  localidad, calle, min(ind), max(ind) from (
						select localidad, calle, generate_series(min, max) ind from (
							select localidad, calle,
							min(fromleft)min, max(toleft)max from base 
							where CALLE IS NOT NULL 
							and (fromleft+toleft) <> 0 and (fromright+toright) = 0
							group by localidad, calle) b
						)a group by localidad, calle)d
				on x.localidad = d.localidad and x.calle = d.calle
				where fromleft <> min and toright <> max) E
				left join
				base  f on st_intersects (e.geom, f.geom)
				where e.localidad =  f.localidad and e.calle = f.calle and e.id <> f.id
				and e.toleft + 2 <> f.fromleft AND F.TOLEFT+ 2 <> E.FROMLEFT and
				f.CALLE IS NOT NULL 
				and (f.fromleft+f.toleft) <> 0 and (f.fromright+f.toright) = 0
				order by e.localidad, e.calle))x),

inconexos_salida as (
	select st_buffer(geom,10) as geom , calle::text,fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''inconexos''::text as tipo from base 
	where id in (
		select a.id from base a
		inner join base b on st_intersects(a.geom, b.geom)
		inner join base c on st_intersects(a.geom, c.geom)
		where a.calle = b.calle and a.calle = c.calle and a.id <> b.id and a.id <> c.id and
		((b.fromleft < c.fromleft and a.fromleft <> b.toright+1 and a.toright+1 <> c.fromleft
		and (b.fromleft+b.toleft)<>0 and (b.fromright+b.toright)<>0
		and	(c.fromleft+c.toleft)<>0 and (c.fromright+c.toright) <>0) or
		(b.fromleft < c.fromleft and a.fromleft <> b.toleft+2 and a.toleft+2 <> c.fromleft
		and (b.fromleft+b.toleft) <> 0 and (b.fromright+b.toright)=0
		and	(c.fromleft+c.toleft)<>0 and (c.fromright+c.toright) =0) or
		(b.fromright < c.fromright and a.fromright <> b.toright+2 and a.toright+2 <> c.fromright
		and (b.fromright+b.toright) <> 0 and (b.fromleft+b.toleft)=0
		and	(c.fromright+c.toright)<>0 and (c.fromleft+c.toleft) =0)))
	and inconexos = 0 and ("check"<>''FALSO'' OR "check" is null) 
	and concat(calle, fromleft,toleft,fromright,toright,localidad) not in (
	select concat(calle, fromleft,toleft,fromright,toright,localidad) from callesduplicadas_salida
	union all select concat(calle, fromleft,toleft,fromright,toright,localidad) from continuidadaltura_salida
	union all select concat(calle, fromleft,toleft,fromright,toright,localidad) from continuidadaltura2_salida)
	order by calle,fromleft,fromright,localidad),

inco1 as (
	select a.geom,a.id,a.calle,a.tipo,b.id as bid, b.calle as bcalle from nodos a
	inner join nodos b on st_astext(a.geom)=st_astext(b.geom)
	where a.id::int<>b.id::int and a.calle is not null and b.calle is not null),		
inco2 as (
	select id from inco1 where calle=bcalle group by id),
inco3 as (
	select id, calle, tipo, bcalle from inco1 
	where id not in (select id from inco2)
	group by id, calle, tipo, bcalle 
	having count (concat(id, calle, tipo, bcalle))=1),
inco4 as (
	select id, calle, bcalle from inco3 group by id, calle, bcalle
	having count(concat(id, calle, bcalle))>1),
inco5 as (
	select a.id,c.calle,a.geom ageom,b.geom bgeom,c.geom cgeom,d.geom dgeom from nodos a inner join nodos b
	on a.id=b.id and st_astext(a.geom)<>st_astext (b.geom) and a.calle is null inner join nodos c on
	a.id<>c.id and st_astext(b.geom)=st_astext(c.geom) and st_astext(a.geom)<>st_astext(c.geom)
	and c.calle is not null inner join nodos d on c.id=d.id and st_astext(c.geom)<>st_astext(d.geom)),
inco6 as (
	select id, angle from (
		select id, degrees(st_angle(ageom,bgeom,dgeom)) angle from inco5)x
	where x.angle between 175 and 185),
nombresinconexos_salida as (				 
	select st_buffer(geom,10) as geom, calle, 0 as fromleft,0 as toleft,0 as fromright,0 as toright,null as localidad ,''nombresinconexos'' as tipo from base
	where id::int in (select id::int from inco4 union select id::int from inco6)),

partprov as (
	select partido,provincia from base group by partido,provincia order by count (partido) desc limit 1),
adminconexos as (
	select a.id,a.geom,b.localidad,b.partido from base a
	inner join capas_gral.localidades b on st_within(st_centroid(a.geom),b.geom)),
adminconexos_salida as(
	select st_buffer(geom,10)geom, null as calle, 0 as fromleft,0 as toleft,0 as fromright,0 as toright,localidad,''adminconexos''::text as tipo from adminconexos
	where partido <> (select partido from partprov)
	union
	select st_buffer(geom,10)geom, null as calle, 0 as fromleft,0 as toleft,0 as fromright,0 as toright,localidad,''adminconexos''::text as tipo from base 
	where id not in (select id from adminconexos)),

largo_salida as (
	select st_buffer(geom,10),calle,fromleft,toleft,fromright,toright,localidad,''largo''::text as tipo
	from base where length(st_astext(geom))> 4000),
	
subdivididos as (
	select row_number() over () pk, calles, ids from (
		select st_union(geom) as geom, string_agg(calle,'',''order by calle desc)calles, string_agg(id::Text,'','' order by id asc) as ids from (
			select ST_StartPoint(geom) as geom, id,calle, fromleft,toleft,fromright,toright,localidad from base
			union
			select ST_EndPoint(geom) as geom, id,calle, fromleft,toleft,fromright,toright,localidad from base) a
		group by st_astext(geom)
		having count (st_Astext(geom)) = 2) b
	where split_part(calles,'','',1) = split_part(calles,'','',2)),
subdivididos_2 as (
	select st_linemerge(st_union(geom1,geom2))geom,calle,localidad from (
		select b.geom geom1,c.geom geom2, b.calle, b.localidad from subdivididos a
		inner join base b on b.id::text  = split_part(a.ids,'','',1) inner join base c on c.id::text  = split_part(a.ids,'','',2)
		where b.localidad = c.localidad)x),
subdividido_salida as (
	select st_buffer(geom,10) geom, calle, 0 fromleft, 0 toleft,0 fromright, 0 toright, localidad, ''subdivido'' as tipo from subdivididos_2),

sentido_alturas as (
		 select st_buffer(geom,10) geom,calle,0 fromleft,0 toleft,0 fromright,0 toright, null localidad,''sentido altura''::text as tipo from (
			select a.geom, A.CALLE, A.id, STRING_AGG(distinct(B.CALLE),'','') calles from base a
			LEFT join base b on st_intersects (a.geom, b.geom) AND A.ID <> B.ID 
			where a.sentido::int = 0 and a.fromleft+a.toleft+a.toright+a.fromright <>0
			GROUP BY A.ID, A.CALLE, a.geom)x
		  where calles not LIKE ''%'' || calle || ''%''
		  union
		  select st_buffer(geom,10)geom, calle, fromleft, toleft, fromright, toright, null localidad, ''sentido altura''::text as tipo from base where id in(
		 	select id from (
		 		with sent as 
				(select ST_StartPoint ((st_dump(geom)).geom) as geom, id, calle, ''INICIAL'' as nodo, fromleft, toleft,fromright,toright from base 
				union
				select ST_endPoint ((st_dump(geom)).geom) as geom, id, calle, ''FINAL'' as nodo, fromleft, toleft,fromright,toright from base)
				,sent2 as 
				(select a.id, a.calle, a.fromleft, a.toleft,a.fromright,a.toright, a.nodo, b.id as bid, b.nodo as bnodo, b.fromleft as bfromleft, b.toleft as btoleft,b.fromright as bfromright,b.toright as btoright 
				from sent a inner join sent b on a.geom = b.geom WHERE a.calle = b.calle and a.id <> b.id 
				and (((a.fromleft + a.toleft) <> 0 and (b.fromleft + b.toleft) <> 0) or
				((a.fromright + a.toright) <> 0 and (b.fromright + b.toright) <> 0)))
				select * from sent2 where 
				(nodo = ''INICIAL'' and bfromleft > toleft and (fromleft + toleft)<>0 and (bfromleft + btoleft)<>0) 
				 or (nodo = ''INICIAL'' and bfromright > toright and (fromright + toright) <> 0 and (bfromright + btoright) <> 0) or
				(nodo = ''FINAL'' and bfromleft < toleft and (fromleft+toleft) <> 0 and (bfromleft + btoleft) <> 0) 
				 or (nodo = ''FINAL'' and bfromright < toright and (fromright + toright) <> 0 and (bfromright + btoright) <> 0))x))

select * from nodos_salida
union all
select * from nombresinconexos_salida
union all
select * from nombre_salida	
union all 
select * from frecuencia_salida
union all
select * from callesduplicadas_salida
union all 
select * from continuidadaltura_salida 
union all
select * from continuidadaltura2_salida
union all 
select * from inconexos_salida 
union all
select * from adminconexos_salida
union all
select * from subdividido_salida
union all 
select * from sentido_salida
union all
select * from largo_salida
union all
select * from sentido_alturas
		 
');

RETURN query execute ('select tipo, count(*)::int as cantidad from  test.dashbord_'||tabla||' group by tipo');

END
$BODY$;