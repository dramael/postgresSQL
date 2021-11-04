-- FUNCTION: _avl_caba.caba_dashbord()

-- DROP FUNCTION _avl_caba.caba_dashbord();

CREATE OR REPLACE FUNCTION _avl_caba.caba_dashbord(
	)
    RETURNS TABLE(tipo text, cantidad bigint) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
BEGIN
EXECUTE (
   'drop table if exists test.caba_frecuencia;
	create table test.caba_frecuencia as
	select st_buffer(geom,10) as geom , calle::text, fromleft::int, toleft::int,fromright::int, toright::int, ''frecuencia''::text as tipo from _Cartografia.capitalfederal
	where 	((tcalle is null or tcalle <> 12) and ("check" <> ''FALSO'' or "check" is null) and (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and (fromleft+toleft) <> 0 and (fromright+toright) <>0) 
	and 	((right(fromleft::text,1) <> ''0'') or (right(toleft::text,1) <> ''8'') or (right(fromright::text,1) <> ''1'') or (right(toright::text,1) <> ''9''))
	or 		((fromleft > toleft)or (fromright > toright))
	or 		(fromleft > fromright and (fromright+toright) <>0)
	or 		(toleft > toright and (fromright+toright) <>0)
	or 		(toleft+1 <> toright or fromleft+1 <> fromright)
	and 	(fromleft+toleft) <> 0
	and 	(fromright+toright) <>0
	union
	select st_buffer(geom,10) as geom , calle::text, fromleft::int, toleft::int,fromright::int, toright::int,  ''frecuencia''::text as tipo from _Cartografia.capitalfederal
	where 	(("check" <> ''FALSO'' or "check" is null) AND (CALLE IS NOT NULL) AND (((fromleft+toleft) <> 0 AND (fromright+toright) = 0) OR ((fromright+toright) <> 0 AND (fromleft+toleft) = 0)))
	and 	(fromleft > toleft and (fromleft+toleft) <> 0) 
	or 		(fromright > toright and fromright + toright <> 0)
	or 		((fromleft+toleft)<>0 and ((right(toleft::text,1) <> ''8'') or (right(fromleft::text,1) <> ''0'')))
	or 		((fromright+toright)<>0 and ((right(toright::text,1) <> ''9'') or (right(fromright::text,1) <> ''1'')));

	drop table if exists test.caba_callesduplicadas;
	create table test.caba_callesduplicadas as 
	(select st_buffer((st_dump(st_union (geom))).geom,10) as geom,calle, fromleft, toleft,fromright, toright, ''callesduplicadas'' as tipo from (
	select st_union(geom) as geom, calle, fromleft,toleft,fromright,toright from _Cartografia.capitalfederal
	where (fromleft+toleft+fromright+toright) <> 0 AND CALLE IS NOT NULL and callesdup = 0
	group by calle, fromleft, toleft, fromright, toright
	having count (*) <> 1
	union
	select geom, calle, fromleft, toleft,fromright, toright from (select distinct (id) id, geom, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from _Cartografia.capitalfederal a 
	inner join (
	select  calle,ind from (
	select  calle, generate_series(min, max) ind from (
	select id,  calle,min(fromleft)min, max(toright)max from _Cartografia.capitalfederal
	where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and callesdup = 0
	and (fromleft+toleft) <> 0 and (fromright+toright) <>0
	group by id, calle
	) x
	) a group by  calle, ind having count (concat(calle, ind)) <> 1
	) b on (a.calle = b.calle and b.ind BETWEEN a.fromleft+1 and a.toright)) z
	) f group by calle, fromleft, toleft, fromright, toright);

	drop table if exists test.caba_continuidadaltura;
	create table test.caba_continuidadaltura as (
	select st_buffer(E.geom,10) as geom, e.calle, e.fromleft, e.toleft, e.fromright, e.toright,  ''continuidadaltura'' as tipo from (
	select distinct (id) id , geom , x.calle, fromleft, toleft, fromright, toright from (
	select  a.*  from _Cartografia.capitalfederal a
	inner join (
	select b.calle,ind from _Cartografia.capitalfederal a
	right JOIN (
	select  * from (
	select  calle, generate_series(min, max) ind from (
	select  calle,
	min(fromleft)min, max(toright)max from _Cartografia.capitalfederal
	where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and contalt = 0
	and (fromleft+toleft) <> 0 and (fromright+toright) <>0
	group by  calle) b
	order by 1,2) a
	)b
	on ( a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)
	where id is null 
	) b on a.calle = b.calle
	and ((a.fromleft+a.toleft+a.fromright+a.toright) <>0 AND a.CALLE IS NOT NULL  and contalt = 0
	and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) <>0
	and a.toright+1 = b.ind) 
	union
	select a.* from _Cartografia.capitalfederal a
	inner join (
	select b.calle,ind from _Cartografia.capitalfederal a
	right JOIN  (
	select  * from (
	select  calle, generate_series(min, max) ind from (
	select calle,
	min(fromleft)min, max(toright)max from _Cartografia.capitalfederal  
	where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL  and contalt = 0
	and (fromleft+toleft) <> 0 and (fromright+toright) <>0
	group by  calle) b
	order by 1,2) a
	)b
	on ( a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toright)
	where id is null 
	) b on a.calle = b.calle
	and ((a.fromleft+a.toleft+a.fromright+a.toright) <>0 AND a.CALLE IS NOT NULL and a.tcalle is null and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) <>0
	and b.ind+1 between a.fromleft and a.toright) 
	order by id
	) x
	inner join 
	(
	select   calle, min(ind), max(ind) from (
	select  calle, generate_series(min, max) ind from (
	select  calle,
	min(fromleft)min, max(toright)max from _Cartografia.capitalfederal
	where (fromleft+toleft+fromright+toright) <>0 AND CALLE IS NOT NULL and contalt = 0
	and (fromleft+toleft) <> 0 and (fromright+toright) <>0
	group by  calle) b
	) a group by  calle
	) d
	on  x.calle = d.calle
	where fromleft <> min and toright <> max 
	) E
	left join
	_Cartografia.capitalfederal f on st_intersects (e.geom, f.geom)
	where  e.calle = f.calle and e.id <> f.id
	and e.toright +1 <> f.fromleft AND F.TORIGHT+1 <> E.FROMLEFT
	and (f.fromleft+f.toleft+f.fromright+f.toright) <>0 AND f.CALLE IS NOT NULL and contalt = 0
	and (f.fromleft+f.toleft) <> 0 and (f.fromright+f.toright) <>0);

	drop table if exists test.caba_nodos;							
	create table test.caba_nodos as 
	with base as	(select geom,id,calle from _Cartografia.capitalfederal),
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
	''nodos''::text as tipo  from (select * from primera union select * from segunda) x),
	fnodos as (
	select a.geom from dnodos a inner join base b  
	on st_intersects (a.geom, b.geom) group by a.geom having count(b.geom) not in (5,6))
	select * from dnodos where geom in (select geom from fnodos);

	drop table if exists test.caba_sentido;
	create table test.caba_sentido as
	with sentido as 
	(
	select ST_StartPoint ((st_dump(geom)).geom) as geom, calle, ''inicio'' as tipo from _Cartografia.capitalfederal  
	where tcalle is null and calle is not null
	union all
	select ST_EndPoint ((st_dump(geom)).geom) as geom, calle, ''fin'' as tipo from _Cartografia.capitalfederal 
	where tcalle is null and calle is not null
	order by 1,2,3),
	sentido2 as 
	(select geom, calle from sentido
	group by geom, calle
	having count (concat(st_astext(geom), calle)) =2)
	select geom, calle::text, null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright ,''sentido''::text as tipo from (
	(select st_buffer(st_union(geom),10) as geom, calle, tipo from sentido
	where st_astext (geom) in (select st_astext (geom) from sentido2)
	group by geom, calle, tipo
	having count (concat(st_astext(geom), calle, tipo)) <> 1))x;

	drop table if exists test.caba_nombre;
	create table test.caba_nombre as
	select null::geometry(polygon,5347) geom,
	concat( ''("calle"= '', k ,acalle,k,'' or "calle"=  '',k, bcalle ,k,'' ) '') as calle, 
	null::int as fromleft, null::int as toleft, null::int as fromright, null::int as toright, ''nombre''::text as tipo
	from _Cartografia.capitalfederal   a
	inner join singlequote on k <> ''calle''
	inner join (
	select split_part(ats,'','',1) acalle,split_part(ats,'','',2)bcalle from (select array_to_string(acalleandbcalle,'','') ats from (select 
	case when 
	acalle > bcalle then ARRAY[acalle, bcalle]
	else ARRAY[bcalle, acalle]
	end acalleandbcalle
	from (select  acalle, bcalle
	from (
	select distinct on (acalleandbcalle) id,  acalle, bcalle  from(select id,
	case when 
	acalle > bcalle then ARRAY[acalle, bcalle]
	else ARRAY[bcalle, acalle]
	end acalleandbcalle,
	acalle,
	bcalle
	from (
	select ROW_NUMBER() OVER() ID,  acalle,bcalle  from (
	SELECT  a.calle acalle, b.calle bcalle FROM (
	SELECT  CALLE FROM _Cartografia.capitalfederal  
	WHERE CALLE IS NOT NULL AND CONTNOMBRE = 0
	GROUP BY 1
	) A
	INNER JOIN (
	SELECT  CALLE FROM _Cartografia.capitalfederal 
	WHERE CALLE IS NOT NULL AND CONTNOMBRE = 0
	GROUP BY 1
	) B ON 
	SIMILARITY(A.CALLE ,B.CALLE) > 0.45
	AND A.CALLE <> B.CALLE)c
	where 
	acalle not like ''%NORTE'' and acalle not like ''%SUR'' and acalle not like ''%ESTE'' and acalle not like ''%OESTE''
	AND Bcalle not like ''%NORTE'' and Bcalle not like ''%SUR'' and	bcalle not like ''%ESTE'' and bcalle not like ''%OESTE''  
	AND acalle NOT LIKE ''PJE%'' AND BCALLE NOT LIKE ''PJE%''
	and acalle not like ''%BIS'' and bcalle not like ''%BIS'' 
	and acalle not like ''%CALLE%'' AND BCALLE NOT LIKE ''%CALLE%''
	AND acalle not like ''%DIAGONAL%'' AND bcalle not like ''%DIAGONAL%'' 
	AND bcalle not like ''%COLECTORA%''and acalle not like ''%COLECTORA%''
	AND bcalle not like ''%EJE %''and acalle not like ''%EJE %''
	AND bcalle not like ''%LATERAL%''and acalle not like ''%LATERAL%''
	order by 1,2,3
	) x
	order by 3) x
	) f order by 2 )x
	)x)x
	)f
	on a.calle = f.acalle or a.calle = f.bcalle
	group by acalle, bcalle, k;

	drop table if exists test.caba_continuidadaltura2;			
	create table test.caba_continuidadaltura2 as 
	(select st_buffer(geom,10) as geom , calle::text,fromleft::int, toleft::int,fromright::int, toright::int, ''callesduplicadas''::text as tipo from (
	select st_buffer((st_dump(st_union (geom))).geom,15) as geom, calle, fromleft,toleft,fromright,toright from 
	(select geom, calle, fromleft, toleft,fromright, toright from 
	(
	select distinct (id) id, geom,  a.calle, a.fromleft,a.toleft,a.fromright,a.toright from _Cartografia.capitalfederal  a 
	inner join (select  calle,ind from 
	(select  calle, generate_series(min, max) ind from 
	(select  ID, calle,min(fromleft)min, max(toleft)max from _Cartografia.capitalfederal 
	where (fromleft+toleft) <> 0 AND (fromright+toright) = 0 and CALLE IS NOT NULL 
	group by ID, calle
	)x 
	) a group by  calle, ind having count (concat( calle, ind)) <> 1
	) b on ( a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)
	) z
	) f group by  calle, fromleft, toleft, fromright, toright
	union
	select (st_dump(st_union (geom))).geom as geom, calle, fromleft,toleft,fromright,toright from 
	(select geom,  calle, fromleft, toleft,fromright, toright from 
	(
	select distinct (id) id, geom, a.calle, a.fromleft,a.toleft,a.fromright,a.toright from _Cartografia.capitalfederal  a 
	inner join (select  calle,ind from 
	(select  calle, generate_series(min, max) ind from 
	(select  ID, calle,min(fromright)min, max(toright)max from _Cartografia.capitalfederal 
	where (fromright+toright) <> 0 AND (fromleft+toleft) = 0 and CALLE IS NOT NULL 
	group by ID, calle
	)x
	) a group by  calle, ind having count (concat( calle, ind)) <> 1
	) b on (a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)
	) z
	) f group by  calle, fromleft, toleft, fromright, toright)x
	union -- continuidadaltura
	select st_buffer(geom,15) as geom, calle::text, fromleft::int, toleft::int, fromright::int, toright::int, ''continuidadaltura''::text as tipo  from ((select E.* from 
	(select distinct (id) id , st_buffer(geom,10) as geom , x.calle, fromleft, toleft, fromright, toright from (
	select  a.*  from _Cartografia.capitalfederal  a
	inner join (
	select b.calle,ind from _Cartografia.capitalfederal  a
	right JOIN   
	(
	select  * from (
	select  calle, generate_series(min, max) ind from (
	select  calle,
	min(fromright)min, max(toright)max from _Cartografia.capitalfederal 
	where (fromright+toright) = 0 and (fromright+toright) <> 0 AND CALLE IS NOT NULL 
	group by  calle) b
	order by 1,2) a 
	)b
	on ( a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)
	where id is null -- Devuelve los valores que no se encuentra en la secuencia total x  y calle
	) b on a.calle = b.calle
	and ((a.fromright+a.toright) <> 0 and (fromleft+a.toleft) = 0 AND a.CALLE IS NOT NULL
	and a.toright+1 = b.ind) 
	union
	select a.* from _Cartografia.capitalfederal  a
	inner join (
	select b.calle,ind from _Cartografia.capitalfederal  a
	right JOIN  
	(
	select  * from (
	select  calle, generate_series(min, max) ind from (
	select  calle,
	min(fromright)min, max(toright)max from _Cartografia.capitalfederal 
	where CALLE IS NOT NULL 
	and (fromright+toright) <> 0 and (fromleft + toleft) = 0
	group by  calle) b
	order by 1,2) a
	)b
	on ( a.calle = b.calle and b.ind BETWEEN a.fromright and a.toright)
	where id is null -- Devuelve los valores que no se encuentra en la secuencia total x  y calle
	) b on a.calle = b.calle
	and (a.CALLE IS NOT NULL  and (a.fromright+a.toright) <> 0 and (a.fromleft+a.toleft) = 0
	and b.ind+1 between a.fromright and a.toright)
	order by id
	) x
	inner join 
	(
	select   calle, min(ind), max(ind) from (
	select  calle, generate_series(min, max) ind from (
	select  calle,
	min(fromright)min, max(toright)max from _Cartografia.capitalfederal 
	where CALLE IS NOT NULL 
	and (fromright+toright) <> 0 and (fromleft+toleft) = 0
	group by  calle) b
	) a group by  calle 
	) d
	on  x.calle = d.calle
	where fromright <> min and toright <> max 
	) E
	right join
	_Cartografia.capitalfederal  f on st_intersects (e.geom, f.geom)
	where e.calle = f.calle and e.id <> f.id
	and e.toright + 2 <> f.fromright AND F.TOright+ 2 <> E.FROMright and
	f.CALLE IS NOT NULL 
	and (f.fromright+f.toright) <> 0 and (f.fromleft+f.toleft) = 0
	order by  e.calle)
	union
	(select E.* from 
	(select distinct (id) id , geom , x.calle, fromleft, toleft, fromright, toright from (
	select  a.*  from _Cartografia.capitalfederal  a
	inner join (
	select b.calle,ind from _Cartografia.capitalfederal  a
	right JOIN   
	(
	select  * from (
	select  calle, generate_series(min, max) ind from (
	select  calle,
	min(fromleft)min, max(toleft)max from _Cartografia.capitalfederal 
	where (fromleft+toleft) <>0 and (fromright+toright) = 0 AND CALLE IS NOT NULL 
	group by  calle) b
	order by 1,2) a 
	)b
	on (a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)
	where id is null 
	) b on a.calle = b.calle
	and ((a.fromleft+a.toleft) <> 0 and (fromright+a.toright) = 0 AND a.CALLE IS NOT NULL
	and a.toleft+1 = b.ind) 
	union
	select a.* from _Cartografia.capitalfederal  a
	inner join (
	select b.calle,ind from _Cartografia.capitalfederal  a
	right JOIN  
	(
	select  * from (
	select  calle, generate_series(min, max) ind from (
	select  calle,
	min(fromleft)min, max(toleft)max from _Cartografia.capitalfederal 
	where CALLE IS NOT NULL 
	and (fromleft+toleft) <> 0 and (fromright+toright) = 0
	group by  calle) b
	order by 1,2) a -- Devuelve la secuenca total x  y calle
	)b
	on ( a.calle = b.calle and b.ind BETWEEN a.fromleft and a.toleft)
	where id is null -- Devuelve los valores que no se encuentra en la secuencia total x  y calle
	) b on a.calle = b.calle
	and (a.CALLE IS NOT NULL  and (a.fromleft+a.toleft) <> 0 and (a.fromright+a.toright) = 0
	and b.ind+1 between a.fromleft and a.toleft) 
	order by id
	) x -- Devuelve todos los registros incorrectos
	inner join 
	(
	select   calle, min(ind), max(ind) from (
	select  calle, generate_series(min, max) ind from (
	select  calle,
	min(fromleft)min, max(toleft)max from _Cartografia.capitalfederal 
	where CALLE IS NOT NULL 
	and (fromleft+toleft) <> 0 and (fromright+toright) = 0
	group by  calle) b
	) a group by  calle
	) d
	on x.calle = d.calle
	where fromleft <> min and toright <> max
	) E
	left join
	_Cartografia.capitalfederal  f on st_intersects (e.geom, f.geom)
	where  e.calle = f.calle and e.id <> f.id
	and e.toleft + 2 <> f.fromleft AND F.TOLEFT+ 2 <> E.FROMLEFT and
	f.CALLE IS NOT NULL 
	and (f.fromleft+f.toleft) <> 0 and (f.fromright+f.toright) = 0
	order by e.calle))x);
	
	drop table if exists test.caba_inconexos;
	create table test.caba_inconexos as 	
	(select st_buffer(geom,10) as geom , calle::text,fromleft::int, toleft::int,fromright::int, toright::int, localidad::text, ''inconexos''::text as tipo from _cartografia.capitalfederal 
	where id in (
		select a.id from _cartografia.capitalfederal a
		inner join _cartografia.capitalfederal b on st_intersects(a.geom, b.geom)
		inner join _cartografia.capitalfederal c on st_intersects(a.geom, c.geom)
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
		union
		select a.id from _cartografia.capitalfederal a
		inner join _cartografia.capitalfederal b on st_intersects(a.geom,b.geom)
		where a.calle = b.calle and (a.fromleft+a.toleft+a.fromright+a.toright) = 0 and (b.fromleft+b.toleft+b.fromright+b.toright) <> 0)
	and inconexos = 0 and ("check"<>''FALSO'' OR "check" is null) 
	and concat(calle, fromleft,toleft,fromright,toright,localidad) not in (
	select concat(calle, fromleft,toleft,fromright,toright,localidad) from test.caba_callesduplicadas
	union all select concat(calle, fromleft,toleft,fromright,toright,localidad) from test.caba_continuidadaltura)
	order by calle,fromleft,fromright,localidad);
	
	drop table if exists test.caba_nombresinconexos;
	create table test.caba_nombresinconexos as 
	with base as (select geom,id,calle from _Cartografia.capitalfederal),
	nodos as (
		select ST_StartPoint ((st_dump(geom)).geom) as geom,id::text,calle, ''inicio'' as tipo from base 
		union all
		select ST_EndPoint ((st_dump(geom)).geom) as geom,id::text,calle, ''fin'' as tipo from base),
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
		where x.angle between 175 and 185)
	select st_buffer(geom,10) as geom, calle, 0 as fromleft,0 as toleft,0 as fromright,0 as toright,null as localidad ,''nombresinconexos'' as tipo from _cartografia.capitalfederal
	where id::int in (select id::int from inco4 union select id::int from inco6);
	
	drop table if exists test.caba_subdivididos; create table if not exists test.caba_subdivididos as 
	with base as (select * from _cartografia.capitalfederal),
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
			inner join base b on b.id::text  = split_part(a.ids,'','',1) inner join base c on c.id::text  = split_part(a.ids,'','',2))x)
	select st_buffer(geom,10) geom, calle, 0 fromleft, 0 toleft,0 fromright, 0 toright, localidad, ''subdivido'' as tipo from subdivididos_2;

	drop table if exists test.caba_locparinconexos;
	create table test.caba_locparinconexos as 
	with locparinconexos as (
	select partido,provincia from _Cartografia.capitalfederal
	group by partido,provincia order by count (partido) desc limit 1),
	adminconexos2 as
	(select a.partido,a.provincia from capas_gral.localidades a inner join locparinconexos b
	on a.provincia=b.provincia and (a.partido=b.partido or b.PROVINCIA=''CIUDAD DE BUENOS AIRES'')  
	group by a.partido,a.provincia)
	select st_buffer(geom,10),calle,fromleft,toleft,fromright,toright,''adminconexos''::text as tipo
	from _Cartografia.capitalfederal where trim(concat (partido,provincia))  
	not in (select concat (partido,provincia) from adminconexos2);

	drop table if exists test.caba_largo; create table test.caba_largo as (
	select st_buffer(geom,10),calle,fromleft,toleft,fromright,toright,''largo''::text as tipo
	from _Cartografia.capitalfederal where length(st_astext(geom))> 4000);
	
	drop table if exists test.caba_altura_suelta; create table test.caba_altura_suelta as (
	select  geom,calle,''sentido altura''::text as tipo from (
	select a.geom, A.CALLE,A.id, STRING_AGG(distinct(B.CALLE),'','') calles from _cartografia.capitalfederal a
LEFT join _cartografia.capitalfederal b on st_intersects (a.geom, b.geom) AND A.ID <> B.ID 
							 
							 
 where a.sentido::int = 0 and a.fromleft+a.toleft+a.toright+a.fromright <>0
GROUP BY A.ID, A.CALLE, a.geom)x
where calles  not LIKE ''%'' || calle || ''%'')
	
	');
	
RETURN query execute ('select tipo::text,count (tipo) cantidad from test.caba_frecuencia group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_callesduplicadas group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_continuidadaltura group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_nodos group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_sentido group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_nombre group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_continuidadaltura2 group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_locparinconexos group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_subdivididos group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_inconexos group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_nombresinconexos group by tipo
					  union
					  select tipo::text,count (tipo) cantidad from test.caba_altura_suelta group by tipo
					  ');

END
$BODY$;

ALTER FUNCTION _avl_caba.caba_dashbord()
    OWNER TO gabriela;
