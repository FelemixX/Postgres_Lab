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
CREATE OR REPLACE FUNCTION findNearestAttraction(userLocation point) RETURNS table (attraction_location point, attraction_name varchar, distance float)  AS $$
BEGIN
    RETURN QUERY
    SELECT cities_attraction.attraction_location, cities_attraction.attraction_name FROM cities_attraction ORDER BY cities_attraction.attraction_location <-> userLocation LIMIT 10;
END;
$$ LANGUAGE plpgsql;

drop function findNearestAttraction(userLocation point);

SELECT findNearestAttraction(point '(2.5, 1.0)');

CREATE INDEX ON cities_attraction USING GIST(attraction_location); --выводить расстояние от пользовател до точки // использовать тип данных record? Надо делать в цикле ?
