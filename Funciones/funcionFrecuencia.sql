CREATE OR REPLACE FUNCTION test.frecuencia(tabla varchar(30)) RETURNS TABLE (cantidad int ) AS $func$
BEGIN
EXECUTE (

    'drop table if exists test.f'||tabla||';
        create table if not exists test.f'||tabla||' as 
        select id, geom, calle, fromleft,toleft,fromright, toright,	localidad, contnombre, tcalle, "check" 
        from _cartografia.'||tabla||';	
    with frec as (
            Select a.id,
            Case When b.fromleft < b.toleft And b.fromleft < b.fromright and b.fromleft < b.toright  and b.fromleft <> 0 Then b.fromleft
            When b.toleft < b.fromleft And b.toleft < b.fromright and b.toleft < b.toright and b.toleft <>0 Then b.toleft 
            When b.fromright < b.toright And b.fromright < b.fromleft and b.fromright < b.toleft and b.fromright <>0 and b.fromright <> 0 Then b.fromright 
            Else b.toright
            End As minimo,
            Case When b.fromleft > b.toleft And b.fromleft > b.fromright and b.fromleft > b.toright Then b.fromleft
            When b.toleft > b.fromleft And b.toleft > b.fromright and b.toleft > b.toright Then b.toleft 
            When b.fromright > b.toright And b.fromright > b.fromleft and b.fromright > b.toleft Then b.fromright 
            Else b.toright
            End As maximo	
            From   test.dashbord_'||tabla||' b
            inner join _cartografia.'||tabla||' a on st_within (a.geom, b.geom)
            where b.fromleft <> 0 and b.toleft <> 0 and b.fromright <> 0 and b.toright <> 0 and b.tipo = ''frecuencia''
        union
            select a.id,
            case when b.fromleft < b.toleft then b.fromleft-(right(b.fromleft::text,1))::int
            else b.toleft-(right(b.toleft::text,1))::int
            end "minimo",
            case when b.fromleft > b.toleft then b.fromleft
            else b.toleft
            end "maximo"
            From   test.dashbord_'||tabla||' b
            inner join _cartografia.'||tabla||' a on st_within (a.geom, b.geom)
            where b.fromleft <> 0 and b.toleft <> 0 and (b.fromright + b.toright) = 0 
            and b.tipo = ''frecuencia''
        union
            select a.id,
            case when b.fromright < b.toright then (b.fromright-(right(b.fromright::text,1))::int)+1
            else (b.toright-(right(b.toright::text,1))::int)+1
            end "minimo",
            case when b.fromright > b.toright then b.fromright
            else b.toright
            end "maximo"
            From   test.dashbord_'||tabla||' b
            inner join _cartografia.'||tabla||' a on st_within (a.geom, b.geom)
            where (a.fromleft+a.toleft) = 0 and a.fromright <> 0 and a.toright <> 0 
        and b.tipo = ''frecuencia''), 
            frec2 as (
            select a.id, (a.minimo-(right(a.minimo::text,1))::int) as from , a.maximo as to, a.maximo - (a.minimo-(right(a.minimo::text,1))::int) as dif  
            from frec a
            inner join _cartografia.'||tabla||' b on a.id = b.id
            where b.fromleft <> 0 and b.toleft <> 0 and b.fromright <> 0 and b.toright <> 0 and a.id = b.id
            union
            select a.id, a.minimo as from, a.maximo as to, "maximo"-"minimo" as dif 
            from frec a
            inner join _cartografia.'||tabla||' b on a.id = b.id
            where (b.fromleft <> 0 and b.toleft <> 0 and (b.fromright + b.toright) = 0)
            or  (b.fromright <> 0 and b.toright <> 0 and (b.fromleft + b.toleft) = 0)
            and a.id = b.id
            order by id) ,
            upd1 as 
                (update _cartografia.'||tabla||' a set fromleft = b.fromleft,
                toleft = b.toleft,
                fromright = b.fromright,
                toright = b.toright
                from (select id,
                "from" as fromleft,
                case 	when right(dif::text,1) = ''0'' then "to"-2
                when right(dif::text,1) = ''9'' then "to"-1
                else ("to"-(right("to"::text,1))::int+8)
                end toleft,
                "from"+1 as fromright,
                case 	when right(dif::text,1) = ''0'' then "to"-1
                when right(dif::text,1) = ''9'' then "to"
                else ("to"-(right("to"::text,1))::int+9)
                end toright
                from frec2) b
                where a.id = b.id and a.fromleft <> 0 and a.toleft <> 0 and a.fromright <> 0 and a.toright <> 0),
            upd2 as (
                update _cartografia.'||tabla||' a set 	fromleft = b.fromleft,
                toleft = b.toleft
                from(
                select id, "from" as fromleft ,
                case 	when right(dif::text,1) = ''0'' then "to"-2
                when right(dif::text,1) = ''8'' then "to"
                else ("to"-(right("to"::text,1))::int+8)
                end toleft
                from frec2) b
                where a.id = b.id and a.fromleft <> 0 and a.toleft <> 0 and (a.fromright + a.toright) = 0), 
            upd3 as (
                update _cartografia.'||tabla||' a set 	fromright = b.fromright,
                toright = b.toright
                from(
                select id, "from" as fromright ,
                case 	when right("to"::text,1) = ''9'' then "to"
                when right("to"::text,1) = ''0'' then "to"-1
                else ("to"-(right("to"::text,1))::int+9)
                end toright
                from frec2) b
                where a.id = b.id and a.fromright <> 0 and a.toright <> 0 and (a.fromleft + a.toleft) = 0)
    select * from frec2;
    drop table if exists test.f'||tabla
);
RETURN query execute (
    'select count(*)::int as cantidad from _cartografia.'||tabla||' 
					  where ((fromleft+toleft)<>0 and ((right(toleft::text,1) <> ''8'') or (right(fromleft::text,1) <> ''0'')))
				or 		((fromright+toright)<>0 and ((right(toright::text,1) <> ''9'') or (right(fromright::text,1) <> ''1'')))')
;

END
$func$ LANGUAGE plpgsql;