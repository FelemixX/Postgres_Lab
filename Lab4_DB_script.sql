create table cities
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
    attraction_name     varchar(85)
);

alter table cities_attraction
    owner to postgres;

create index cities_attraction_attraction_location_idx
    on cities_attraction using gist (attraction_location);

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

create function get_parallel_roads()
    returns TABLE(road1_name character varying, road1_len integer, road2_name character varying, road2_len integer)
    language plpgsql
as
$$
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
$$;

alter function get_parallel_roads() owner to postgres;

create function getnearestattraction(userlocation point) returns record
    language plpgsql
as
$$
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

$$;

alter function getnearestattraction(point) owner to postgres;

create function getattractionsnearcatastrophy(danger_zone_radius circle)
    returns TABLE(attraction_location point, attraction_name character varying, range integer)
    language plpgsql
as
$$
    BEGIN
        RETURN QUERY
            SELECT cities_attraction.attraction_location, cities_attraction.attraction_name,
                   (attraction_location <-> danger_zone_radius)::int
            FROM cities_attraction
            WHERE danger_zone_radius @> cities_attraction.attraction_location;
    END;
$$;

alter function getattractionsnearcatastrophy(circle) owner to postgres;

create function thebiggestmallneartheroad(road_coordinates lseg) returns record
    language plpgsql
as
$$
    DECLARE
    data RECORD;
    BEGIN
            SELECT cities_malls.mall_name,
                   cities_malls.zone_plain,
                   road_coordinates <-> cities_malls.zone_plain,
                   area(zone_plain)
            FROM cities_malls
            WHERE 100 > road_coordinates <-> cities_malls.zone_plain;
            RETURN data;
    END;
$$;

alter function thebiggestmallneartheroad(lseg) owner to postgres;
