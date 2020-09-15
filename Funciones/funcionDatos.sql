CREATE OR REPLACE FUNCTION test.actualizadordatos(tabla varchar(30)) RETURNS TABLE (tipo text, cantidad int) AS $func$
BEGIN
EXECUTE (
	'update _cartografia.'||tabla||' set geom = st_multi(ST_SimplifyPreserveTopology(geom,0.1)) WHERE fechamod = ''today'';
	delete  from _cartografia.'||tabla||' where ST_Length(geom) < 0.1 and fechamod = ''today'';
	delete  from _cartografia.'||tabla||' where ST_Length(geom) is null and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle2 = concat (upper(calle),''/'', fromleft, ''/'', toleft, ''/'', fromright, ''/'', toright)
	where calle2 is null or calle2 <> concat (upper(calle),''/'', fromleft, ''/'', toleft, ''/'', fromright, ''/'', toright);
	UPDATE _cartografia.'||tabla||' SET CALLE3 = NULL WHERE LENGTH(CALLE3)<1;
	update _cartografia.'||tabla||'
	set calle3 = upper (calle3)
	where calle3 is not null  and fechamod = ''today'';
	update _cartografia.'||tabla||'
	set "check" = null 
	where (fromleft + toleft + fromright + toright) = 0 and calle is null and  "check" = ''OK'' and fechamod = ''today'';
	update _cartografia.'||tabla||'
	set "check" = null 
	where (fromleft + toleft + fromright + toright) = 0 and calle is not null and  "check" = ''OK'' and fechamod = ''today'';
	UPDATE _cartografia.'||tabla||'
	set calle = upper(calle)
	where fechamod =''today'';
	UPDATE _cartografia.'||tabla||'
	set "check" = upper("check")
	where fechamod =''today'';
	update _cartografia.'||tabla||'
	set calle = null 
	where calle is null and fechamod = ''today'';
	update _cartografia.'||tabla||' 
	set fromleft = 0 
	where fromleft is null and fechamod = ''today'';
	update _cartografia.'||tabla||' 
	set toleft = 0 
	where toleft is null and fechamod = ''today'';
	update _cartografia.'||tabla||' 
	set fromright = 0 
	where fromright is null and fechamod = ''today'';
	update _cartografia.'||tabla||' 
	set toright = 0 
	where toright is null and fechamod = ''today'';
	UPDATE _cartografia.'||tabla||'
	set calle = concat (calle,'' ('',calle3, '')'')
	where calle3 is not null and calle not like ''%(%'' and fechamod  = ''today'' AND LENGTH(concat (calle,'' ('',calle3, '')'')) <41;
	UPDATE _CARTOGRAFIA.'||tabla||'
	SET GOOGLE = 0 
	WHERE fechamod = ''today'' AND GOOGLE IS NULL;
	update _cartografia.'||tabla||'
	set fuente = (google + here + osm)
	where fuente is null and fechamod = ''today'' AND GOOGLE = 1 AND HERE = 1 AND OSM = 1;
	update _cartografia.'||tabla||' 
	set "check" = ''OK''
	where fuente = ''3'' and "check" is null;
	update _cartografia.'||tabla||'
	set fuente = ''OSM - HERE''
	where OSM = 1 and here = 1 and fechamod = ''today'';
	update _cartografia.'||tabla||' 
	set "check" = ''OK''
	where (fuente IS NOT NULL and OSM = 1) AND (fuente IS NOT NULL and here = 1) and "check" is null;
	update _cartografia.'||tabla||'
	set "check" = ''OK'' , fuente = ''OSM''
	where OSM = 1 and "check" is null and calle is not null and (fromleft + toleft + fromright + toright) <> 0 and fuente is null and fechamod = ''today'';
	update _cartografia.'||tabla||'
	set "check" = ''OK'' , fuente = ''HERE''
	where here = 1 and "check" is null and calle is not null and (fromleft + toleft + fromright + toright) <> 0 and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''BOULEVARD'', ''BLVD'') 	where calle like ''%BOULEVARD%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''GOBERNADOR'', ''GDOR'') where calle like ''%GOBERNADOR%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''AVENIDA'', ''AV'') 		where calle like ''%AVENIDA%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''CALLEJON'', ''CJON'') 	where calle like ''%CALLEJON%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''PASAJE'', ''PJE'') 		where calle like ''%PASAJE%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''.'', '''') 				where calle like ''%.%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''DOCTOR'', ''DR'') 		where calle like ''%DOCTOR%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''GENERAL'', ''GRAL'') 	where calle like ''%GENERAL%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''TENIENTE'', ''TTE'') 	where calle like ''%TENIENTE%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''CAPITAN'', ''CAP'') 	where calle like ''%CAPITAN%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set CALLE = replace(CALLE , ''Á'',''A'')			where CALLE like ''%Á%'' and fechamod = ''today''; 			
	update _cartografia.'||tabla||' set CALLE = replace(CALLE , ''É'',''E'')			where CALLE like ''%É%'' and fechamod = ''today''; 		
	update _cartografia.'||tabla||' set CALLE = replace(CALLE , ''Í'',''I'')			where CALLE like ''%Í%''  and fechamod = ''today''; 
	update _cartografia.'||tabla||' set CALLE = replace(CALLE , ''Ó'',''O'')			where  CALLE like ''%Ó%'' and fechamod = ''today''; 
	update _cartografia.'||tabla||' set CALLE = replace(CALLE , ''À'',''O'')			where CALLE like ''%À%'' and fechamod = ''today'';  
	update _cartografia.'||tabla||' set CALLE = replace(CALLE , ''Ú'',''U'')				where CALLE like ''%Ú%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set CALLE = replace(CALLE , ''Ü'',''U'')				where CALLE like ''%Ú%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set CALLE = replace(CALLE,''REPUBLICA'', ''REP'') 	where CALLE like ''%REPUBLICA%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set CALLE = replace(CALLE , ''º'','''')				where CALLE like ''%º%'' AND fechamod = ''today''; 
	update _cartografia.'||tabla||' set calle = replace(calle,''BV'', ''BLVD'') 			where calle like ''BV %'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle = replace(calle,''BULEVAR'', ''BLVD'') 		where calle like ''%BULEVAR%'' and fechamod = ''today'';
	update _CARTOGRAFIA.'||tabla||' set calle = replace(calle,''├Æ'',''Ñ'') 				where CALLE LIKE ''%├Æ%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''REPUBLICA'', ''REP'') 	where calle3 like ''%REPUBLICA%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''AVENIDA'', ''AV'') 		where calle3 like ''%AVENIDA%'' and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''CALLEJON'', ''CJON'') 	where calle3 like ''%CALLEJON%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''PASAJE'', ''PJE'') 		where calle3 like ''%PASAJE%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''.'', '''') 				where calle3 like ''%.%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''DOCTOR'', ''DR'') 		where calle3 like ''%DOCTOR%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''GENERAL'', ''GRAL'') 		where calle3 like ''%GENERAL%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''TENIENTE'', ''TTE'') 		where calle3 like ''%TENIENTE%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''CAPITAN'', ''CAP'') 		where calle3 like ''%CAPITAN%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3 , ''Á'',''A'')				where calle3 like ''%Á%'' and fechamod = ''today''; 			
	update _cartografia.'||tabla||' set calle3 = replace(calle3 , ''É'',''E'')				where calle3 like ''%É%'' and fechamod = ''today''; 		
	update _cartografia.'||tabla||' set calle3 = replace(calle3 , ''Í'',''I'')				where calle3 like ''%Í%''  and fechamod = ''today''; 
	update _cartografia.'||tabla||' set calle3 = replace(calle3 , ''Ó'',''O'')				where  calle3 like ''%Ó%'' and fechamod = ''today''; 
	update _cartografia.'||tabla||' set calle3 = replace(calle3 , ''À'',''O'')				where calle3 like ''%À%'' and fechamod = ''today'';  
	update _cartografia.'||tabla||' set calle3 = replace(calle3 , ''Ú'',''U'')				where calle3 like ''%Ú%'' and fechamod = ''today''; 
	update _cartografia.'||tabla||' set CALLE3 = replace(CALLE3 , ''º'','''')				where CALLE3 like ''%º%'' AND fechamod = ''today''; 
	

	UPDATE _cartografia.'||tabla||' a
	SET localidad = upper(b.localidad),
	partido = upper (b.partido), 
	provincia = upper(b.provincia)
	FROM capas_gral.localidades b
	WHERE ST_WITHIN(st_centroid(a.geom), b.geom) and ((a.fechamod = ''today'') or 
	(a.partido is null or a.provincia is null or a.localidad is null));

	update _cartografia.'||tabla||' set geom = st_multi(ST_LineMerge(geom)) where fechamod = ''today'';

	update _cartografia.'||tabla||' set callesdup = 0 where callesdup is null and fechamod = ''today'';
	update _cartografia.'||tabla||' set contalt = 0 where contalt is null and fechamod = ''today'';
	update _cartografia.'||tabla||' set inconexos = 0 where inconexos is null and fechamod = ''today'';
	update _cartografia.'||tabla||' set sentido = 0 where sentido is null and fechamod = ''today'';
	update _cartografia.'||tabla||' set contnombre = 0 where contnombre is null and fechamod = ''today'';
	
	update _cartografia.'||tabla||' set fromleft = 0 where "check" = ''FALSO'';
	update _cartografia.'||tabla||' set TOLEFT = 0 where "check" = ''FALSO'';
	update _cartografia.'||tabla||' set FROMRIGHT = 0 where "check" = ''FALSO'';
	update _cartografia.'||tabla||' set TORIGHT = 0 where "check" = ''FALSO'' ;

	update _cartografia.'||tabla||' set calle = replace(calle,''-'', '' '')	where calle like ''%-%''and fechamod = ''today'';
	update _cartografia.'||tabla||' set calle3 = replace(calle3,''-'', '' '')	where calle3 like ''%-%''and fechamod = ''today'';




update _cartografia.'||tabla||' set calle = replace(calle,(SELECT k FROM public.singlequote), '' '')	where fechamod = ''today'';
update _cartografia.'||tabla||' set calle3 = replace(calle3,(SELECT k FROM public.singlequote), '' '') where fechamod = ''today'';

	'
	
	);
RETURN query execute (
	'select "check"::text, count(*)::int as cantidad from  _cartografia.'||tabla||' 
	where "check" is null group by "check"::text' );
END
$func$ LANGUAGE plpgsql;

