CREATE OR REPLACE FUNCTION _mysql.borrar() RETURNS TABLE (tabla text, cantidad int) AS $func$
BEGIN
EXECUTE (
    '
TRUNCATE TABLE _MYSQL.pais restart identity;
TRUNCATE TABLE _mysql.provincia restart identity;
truncate table _mysql.departamento restart identity;
truncate table _mysql.localidad restart identity;
truncate table _mysql.calles restart identity;
truncate table _mysql.callesalturas restart identity;
truncate table _mysql.callesintersecciones2 restart identity;
truncate table _mysql.hito restart identity;
truncate table _mysql.hito_tipo restart identity;
truncate table _mysql.archivosdbf restart identity;
truncate table _mysql.cuadricula restart identity;
ALTER SEQUENCE _mysql.calles_seq RESTART WITH 1;
ALTER SEQUENCE _mysql.callesaltura_seq RESTART WITH 1;
ALTER SEQUENCE _mysql.callesintersecciones2_seq RESTART WITH 1;


');
RETURN query execute ('
select ''cantidad pais''::text, count (*)::int from _MYSQL.pais
union
select ''cantidad provincia''::text, count (*)::int from _MYSQL.provincia
union
select ''cantidad departamento''::text, count (*)::int from _MYSQL.departamento
union
select ''cantidad callesalturas''::text, count (*)::int from _MYSQL.callesalturas
union
select ''cantidad callesintersecciones2''::text, count (*)::int from _MYSQL.callesintersecciones2
union
select ''cantidad hito''::text, count (*)::int from _MYSQL.hito
union
select ''cantidad hito_tipo''::text, count (*)::int from _MYSQL.hito_tipo
union
select ''cantidad archivosdbf''::text, count (*)::int from _MYSQL.archivosdbf
union
select ''cantidad archivosdbf''::text, count (*)::int from _MYSQL.localidad
');

END
$func$ LANGUAGE plpgsql;
