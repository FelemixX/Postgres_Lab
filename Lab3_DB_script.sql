create sequence table_name_id_seq
    as integer;

alter sequence table_name_id_seq owner to postgres;

create table customer
(
    customer_id serial
        constraint customer_pk
            primary key,
    tile        char(4),
    first_name  varchar(32) not null,
    last_name   varchar(32) not null,
    addressline varchar(64),
    town        varchar(32),
    zipcode     char(10),
    phone       varchar(16)
);

alter table customer
    owner to postgres;

create table order_info
(
    orderinfo_id serial
        constraint orderinfo_pk
            primary key,
    customer_id  integer not null
        constraint orderinfo_customer_id_fk
            references customer,
    date_placed  date    not null,
    date_shipped date,
    shipping     numeric(7, 2) default 0.0
);

alter table order_info
    owner to postgres;

create table item
(
    item_id     serial
        constraint item_pk
            primary key,
    description varchar(64) not null,
    sell_price  numeric(7, 2),
    cost_price  numeric(7, 2)
);

alter table item
    owner to postgres;

create table stock
(
    item_id  integer not null
        constraint stock_pk
            primary key
        constraint stock_item_id_fk
            references item,
    quantity integer not null
);

alter table stock
    owner to postgres;

create table my_logs
(
    id        serial
        primary key,
    user_id   integer   not null,
    logdate   timestamp not null,
    data      text,
    somestate integer
);

alter table my_logs
    owner to postgres;

create table my_logs_2018m11
(
    constraint my_logs_2018m11_logdate_check
        check ((logdate >= '2018-11-01'::date) AND (logdate < '2018-11-30'::date))
)
    inherits (my_logs);

alter table my_logs_2018m11
    owner to postgres;

create index my_logs_2018m11_logdate
    on my_logs_2018m11 (logdate);

create table my_logs_2018m12
(
    constraint my_logs_2018m12_logdate_check
        check ((logdate >= '2018-12-01'::date) AND (logdate < '2018-12-31'::date))
)
    inherits (my_logs);

alter table my_logs_2018m12
    owner to postgres;

create index my_logs_2018m12_logdate
    on my_logs_2018m12 (logdate);

create table order_new_items
(
    id                integer default nextval('table_name_id_seq'::regclass) not null
        constraint table_name_pkey
            primary key
        constraint table_name_item_item_id_fk
            references item
            on update cascade on delete cascade,
    item_id           integer,
    quantity_to_order integer
);

alter table order_new_items
    owner to postgres;

alter sequence table_name_id_seq owned by order_new_items.id;

create table my_logs_unfiltered
(
)
    inherits (my_logs);

alter table my_logs_unfiltered
    owner to postgres;

create function check_unfinished_orders_trigger() returns trigger
    language plpgsql
as
$$
BEGIN
    IF ((SELECT count(*) FROM order_info WHERE order_info.customer_id = old.customer_id AND order_info.date_shipped IS NULL) >
        0) THEN
        RAISE EXCEPTION 'YOU CANNOT DELETE THIS CUSTOMER (%) BECAUSE OF EXISTING ORDERS', old.customer_id;
    END IF;
    DELETE FROM order_info WHERE order_info.customer_id = old.customer_id;
    RETURN OLD;
END;
$$;

alter function check_unfinished_orders_trigger() owner to postgres;

create trigger unfinished_order_check
    before delete
    on customer
    for each row
execute procedure check_unfinished_orders_trigger();

create function check_for_quantity_update_trigger() returns trigger
    language plpgsql
as
$$
BEGIN
    IF (new.quantity >= 50 AND new.quantity < 100) THEN
        UPDATE order_new_items
        SET quantity_to_order = quantity_to_order + 25
        WHERE order_new_items.id = new.item_id;
    ELSEIF (new.quantity < 50 AND new.quantity != 0) THEN
        UPDATE order_new_items
        SET quantity_to_order = quantity_to_order + 50
        WHERE order_new_items.id = new.item_id;
    ELSEIF (SELECT count(quantity_to_order)
            FROM order_new_items
            WHERE order_new_items.id = new.item_id
              AND order_new_items.quantity_to_order > 100) > 0 THEN
        UPDATE order_new_items SET quantity_to_order = quantity_to_order + 1 WHERE order_new_items.id = new.item_id;
    ELSEIF (new.quantity = 0) THEN
        UPDATE order_new_items
        SET quantity_to_order = 100
        WHERE order_new_items.id = new.item_id;
    ELSEIF (new.quantity >= 100) THEN
        UPDATE order_new_items
        SET quantity_to_order = 0
        WHERE order_new_items.id = new.item_id;
    END IF;
    RETURN NEW;
END;
$$;

alter function check_for_quantity_update_trigger() owner to postgres;

create trigger check_quantity
    before update
    on stock
    for each row
execute procedure check_for_quantity_update_trigger();

create function my_logs_insert_trigger() returns trigger
    language plpgsql
as
$$
begin
    if (new.logdate >= date'2018-11-01' and new.logdate < date'2018-12-01')
    then
        INSERT INTO my_logs_2018m11 (id, user_id, logdate, data, somestate)
        VALUES (NEW.id, NEW.user_id, NEW.logdate, NEW.data, NEW.somestate);
    elseif (new.logdate >= date'2018-12-01' and new.logdate < date'2019-01-01')
    then
        INSERT INTO my_logs_2018m12 (id, user_id, logdate, data, somestate)
        VALUES (NEW.id, NEW.user_id, NEW.logdate, NEW.data, NEW.somestate);
    else
        CREATE TABLE IF NOT EXISTS my_logs_unfiltered
        (
        ) inherits (my_logs);
        INSERT INTO my_logs_unfiltered (id, user_id, logdate, data, somestate)
        VALUES (new.id, new.user_id, new.logdate, new.data, new.somestate);
    end if;
    return null;
end;
$$;

alter function my_logs_insert_trigger() owner to postgres;

create trigger insert_my_logs_trigger
    before insert
    on my_logs
    for each row
execute procedure my_logs_insert_trigger();

