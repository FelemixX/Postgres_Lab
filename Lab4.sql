create table cities --Создать таблицу
-- (или таблицы) городов и дорог в этих городах, а также положение достопримечательностей
-- и прямоугольные зона торговых ценров, используя геометрический тип данных
(
    id        serial
        primary key,
    city_name varchar(86)
);

alter table cities
    owner to postgres;

create table cities_attraction
(
    cities_id           integer not null
        constraint cities_id
            references cities
            on update cascade on delete cascade,
    attraction_location point,
    attraction_name      varchar(85)
);

alter table cities_attraction
    owner to postgres;

create table cities_roads
(
    cities_id integer
        constraint cities_id
            references cities
            on update cascade on delete cascade,
    road      lseg,
    road_name varchar(85)
);

alter table cities_roads
    owner to postgres;

create table cities_malls
(
    cities_id  integer
        constraint cities_id
            references cities
            on update cascade on delete cascade,
    zone_plain box,
    mall_name  varchar(85)
);

alter table cities_malls
    owner to postgres;

-- заполнить таблицы 4-5 строками. Соре мне лень делать дамп

    --Выполнить запросы: найти по заданному местоположению пользователя ближайшую достопримечательность
CREATE OR REPLACE FUNCTION findNearestAttraction(userLocation point) RETURNS table (attraction_location point, attraction_name varchar)  AS $$
BEGIN
    RETURN QUERY
    SELECT cities_attraction.attraction_location, cities_attraction.attraction_name FROM cities_attraction ORDER BY cities_attraction.attraction_location <-> userLocation LIMIT 10;
END;
$$ LANGUAGE plpgsql;

SELECT findNearestAttraction(point '(2.5, 1.0)');

CREATE INDEX ON cities_attraction USING GIST(attraction_location); --выводить расстояние от пользователя до точки // использовать тип данных record? Надо делать в цикле ?


--3
CREATE FUNCTION getNearestAttraction(userLocation point) RETURNS RECORD AS $$
    DECLARE
        min INT = 1000000;
        tmpMin INT = 0;
        _row RECORD;
        _result_row RECORD;

    BEGIN
        FOR _row IN SELECT cities.city_name, cities_attraction.attraction_location FROM cities JOIN cities_attraction on cities.id = cities_attraction.cities_id
            LOOP
                SELECT INTO tmpMin _row.attraction_location <-> userLocation;
                IF (tmpMin < min) THEN
                    min = tmpMin;
                    _result_row = _row;
                END IF;
            END LOOP;
        RETURN _result_row;
    END;

$$ LANGUAGE plpgsql;

SELECT getNearestAttraction('(100500,30)');

--4 найти параллельные дороги

DROP FUNCTION get_parallel_roads;

CREATE FUNCTION get_parallel_roads()
    RETURNS TABLE ( road1_name varchar, road1_len  int,road2_name varchar, road2_len  int )AS $$
    DECLARE
        _row RECORD;
        _row2 RECORD;
    BEGIN
        FOR _row IN SELECT * FROM cities_roads
            LOOP
                FOR _row2 IN SELECT * FROM cities_roads
                    LOOP
                        IF NOT (_row.road = _row2.road) THEN
                            IF (_row.road ?|| _row2.road) THEN
                                RETURN QUERY SELECT _row.road_name,(SELECT @-@ _row.road)::int, _row2.road_name, (SELECT @-@ _row2.road)::int;
                            END IF;
                        END IF;
                    END LOOP;
            END LOOP;
    END;
$$
LANGUAGE plpgsql;

SELECT get_parallel_roads();


-- CREATE FUNCTION getParallelRoadsAndItsNames () RETURNS TABLE (road_name varchar) AS $$
--     BEGIN
--          LOOP
--              SELECT cities_roads.road, cities_roads.road_name, LEAD(cities_roads.road), LEAD(cities_roads.road_name) FROM cities_roads GROUP BY cities_roads.road, cities_roads.road_name;
--          END LOOP;
--     END;
-- $$ LANGUAGE plpgsql;


-- SELECT cities_roads.road, cities_roads.road_name FROM cities_roads a1 where


--5 Пусть в заданной точке на карте случилась авария, выведите список достопримечательностей, которые попадут в зону опастности.
-- Радиус зоны задайте сами. Найти самый большой по площади торговый центр из ближайших к заданной дороге.


CREATE OR REPLACE FUNCTION getAttractionsNearCatastrophy(danger_zone_radius circle) RETURNS TABLE (attraction_location point, attraction_name varchar) AS $$
    BEGIN
        RETURN QUERY
        SELECT cities_attraction.attraction_location, cities_attraction.attraction_name FROM cities_attraction WHERE danger_zone_radius @> cities_attraction.attraction_location;
    END;
$$ LANGUAGE plpgsql;

SELECT getAttractionsNearCatastrophy('((15,200),100500)');

--Найти самый большой по площади торговаый центр из ближайших к заданной дороге
SELECT cities_malls.mall_name, cities_malls.zone_plain,
       '[(100,500), (400,300)]'::lseg <-> cities_malls.zone_plain,
       area(zone_plain)
FROM cities_malls
WHERE 2 > '[(100,500), (400,300)]'::lseg <-> cities_malls.zone_plain


--можно пользоваться PostGis

--Архивирование
--1. .\pg_dump.exe -U postgres -Ft -f "[path\filename.extension]" "[db_name]"
--2. .\pg_restore.exe -U postgres -d "[db_name]" "[path\filename.extension]"
--3. .\pg_dump.exe -U postgres -d "[db_name] "-t "[table_name]" -Fc -f "[path\filename.extension]"
--4. .\pg_restore.exe -U postgres -d "[db_name]" -t "[table_name]" -Fc "[path\filename.extension]" --пробовать через psql
--5. .\pg_dump.exe -U postgres -a -Ft -f "[path\filename.extension]" "[db_name]"
--6. .\pg_dump.exe -U postgres -s "[db_name]" > "[path\filename.extension]"
--7. .\pg_dump.exe -U postgres "[db_name]" > "[path\filename.extension]" -- переделать это и 8 пункт
--8. .\psql.exe -U postgres -d "[db_name]"  -f "[path\filename.extension]" -- почему-то отказывается работать
