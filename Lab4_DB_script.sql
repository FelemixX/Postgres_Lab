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

