-- Comprueba las alturas de los segmentos contra la informacion que se encuentra georeferenciada

CREATE OR REPLACE FUNCTION test.comprobarfaltantes(tabla varchar(30)) RETURNS TABLE (cantidad int ) AS $func$
BEGIN
EXECUTE (

'    
update _cartografia.'||tabla||' 
    set "check" = ''OK'', fuente = ''HERE2'', here = 1 where id in
    (select a.id from 	_cartografia.'||tabla||' a
            inner join 	test.comprobar'||tabla||' b  
    on a.id = b.id where altura between fromleft and toright
    and similarity (a.calle, b.calle) > 0.2 );

update _cartografia.'||tabla||' 
    set "check" = ''CHECK'', osm = 0, here = 0, google=0, fuente = ''null''
    where id in (select * from test.singeo'||tabla||')
    and calle is null and (fromleft+toleft+fromright+toright) = 0

delete from varios.inverse_geocode_here where id in (
    select distinct(b.id) as id from (select * 
                                    from 	_cartografia.'||tabla||'
    where id in (select id from 			test.comprobar'||tabla||'
    ) ) a
    inner join varios.inverse_geocode_here b on st_intersects (b.geom,st_buffer(a.geom,10))
    where a.partido = b.partido
    and a.localidad = b.localidad);

insert into varios.inverse_geocode_here (geom, direccion1, nombre,altura,id_carto)
    select st_setsrid(st_makepoint(x::float, y::float),4326) as geom,concat(calle,'' '',altura) as direccion1, calle, altura,id from test.comprobar'||tabla||'

update varios.inverse_geocode_here a set 
										localidad = b.localidad, 
										partido = b.partido, 
										provincia = b.provincia
from capas_gral.localidades b
where  st_within (st_transform(a.geom,4326), st_transform(b.geom,4326))
and a.localidad is null;

drop table if exists test.comprobar'||tabla||';
drop table if existes test.sigeo'||tabla||';

update _cartografia.'||tabla||' set "check" = ''OK'',	
    fuente = ''adyacentes''
    where id in (
    select a.id from _cartografia.'||tabla||' a
    inner join _cartografia.'||tabla||' b on st_intersects (a.geom,b.geom)
    where a.id <> b.id and a.calle = b.calle
    and a."check" is null
    and b."check" = ''OK''
    and (a.fromleft+a.toleft+a.toright+a.fromright) <>0
    group by a.id
    having count (b.id) >1
    order by a.id);

with 
    comprobar as (
        select a.id,a.calle, 
        string_to_array(string_agg(DISTINCT(b.calle), ',' order by b.calle),',','') inter , 
        a.fromleft, a.toleft, a.fromright, a.toright, a.localidad,a."check"
            from 		_Cartografia.'||tabla||' a
            inner join _cartografia.'||tabla||' b 
        on st_intersects (a.geom, b.geom)
        where a.calle <> b.calle and a.id <> b.id
        group by a.id,a.calle,a.fromleft, a.toleft, a.fromright, a.toright, a.localidad, a."check" 
        ), 
        comprobado as (select inter, localidad,fromleft,toleft,fromright,toright from comprobar 
                    where "check" = ''OK'' and array_length(inter, 1) = 2 
                    group by inter, localidad,fromleft,toleft,fromright,toright),
        unsegmento as (SELECT inter, localidad, string_agg(concat(fromleft,'','',toleft,'','',fromright,'','',toright)::text,'','') alturas FROM COMPROBADO group by inter,localidad having count (inter) = 1),
        sindato as (select * from comprobar where "check" is null),
        paralelos as (select a.id from sindato a
        inner join unsegmento b on a.inter = b.inter
        where a."check" is null
        and a.localidad = b.localidad
        and a.fromleft::text = split_part(alturas,'','',1)
        and a.toleft::text = split_part(alturas,'','',2)
        and a.fromright::text = split_part(alturas,'','',3)
        and a.toright::text = split_part(alturas,'','',4))
        update _cartografia.'||tabla||' set "check" = ''OK'', fuente = ''paralelos''
        where id in (select id from paralelos)

UPDATE _cartografia.'||tabla||' set "check" = ''CHECK''
where fromleft+toleft+fromright+toright  = 0 and calle is null and "check" is null;

UPDATE _cartografia.'||tabla||' set "check" = ''NOMBRE''
where fromleft+toleft+fromright+toright  = 0 and calle is not null and "check" is null;
'
 	
)
;
RETURN query execute ('select count(*)::int as cantidad from _cartografia.'||tabla||' where fuente is null;')
;

END
$func$ LANGUAGE plpgsql;


















 
 