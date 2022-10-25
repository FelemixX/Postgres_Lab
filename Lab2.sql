CREATE OR REPLACE FUNCTION check_unfinished_orders_trigger() RETURNS TRIGGER AS
$unfinished_order_check$
BEGIN
    IF ((SELECT count(*)
         FROM order_info
         WHERE order_info.customer_id = old.customer_id
           AND order_info.date_shipped IS NULL) >
        0) THEN
        RAISE EXCEPTION 'YOU CANNOT DELETE THIS CUSTOMER (%) BECAUSE OF EXISTING ORDERS', old.customer_id;
    END IF;
    DELETE FROM order_info WHERE order_info.customer_id = old.customer_id;
    RETURN OLD;
END;
$unfinished_order_check$ LANGUAGE plpgsql; --написать триггер который не дает удалить клиента если у него есть невыполненные заказы и удалить инфу о заказах пользователя которого можно удалить

CREATE TRIGGER unfinished_order_check
    BEFORE DELETE
    ON customer
    FOR EACH ROW
EXECUTE FUNCTION check_unfinished_orders_trigger();

-- CREATE OR REPLACE FUNCTION check_for_quantity_update_trigger() RETURNS TRIGGER AS --написать триггер который обновляет таблицу дозаказа при изменении количества товара в заказе
-- $check_quantity$
-- BEGIN
--     IF (new.quantity < 100 AND new.quantity > 10) THEN
--         UPDATE order_new_items
--         SET quantity_to_order = quantity_to_order + (old.quantity - new.quantity)
--         WHERE order_new_items.id = new.item_id;
--     ELSEIF (new.quantity < 10) THEN
--         UPDATE order_new_items SET quantity_to_order = quantity_to_order + 10;
--     ELSEIF (new.quantity <= 0) THEN
--         UPDATE order_new_items SET quantity_to_order = quantity_to_order + 100;
--     END IF;
--     RETURN NEW;
-- END;
-- $check_quantity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_for_quantity_update_trigger() RETURNS TRIGGER AS --написать триггер который обновляет таблицу дозаказа при изменении количества товара в заказе
$check_quantity$
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
$check_quantity$ LANGUAGE plpgsql;

drop function check_for_quantity_update_trigger()
drop trigger check_quantity on stock

CREATE TRIGGER check_quantity
    BEFORE UPDATE
    ON stock
    FOR EACH ROW
EXECUTE FUNCTION check_for_quantity_update_trigger();


create table my_logs --создать главную таблицу, создать дочерние таблицы, как наследуемые от главной.
-- Например, главная таблица содержит информацию о посещаемости сайта пользователем.
-- Дочерние таблицы буду содержать информацию о действиях пользователя за конкретный месяц.
-- Реализовать триггер для автоматического заполнения дочерних таблиц.
(
    id        serial primary key,
    user_id   int       not null,
    logdate   timestamp not null,
    data      text,
    somestate int
);

create table my_logs_2018m11
(
    check (logdate >= date'2018-11-01' and logdate < date'2018-11-30')
) inherits (my_logs);
create table my_logs_2018m12
(
    check (logdate >= date'2018-12-01' and logdate < date'2018-12-31')
) inherits (my_logs);
create index my_logs_2018m11_logdate on my_logs_2018m11 (logdate);
create index my_logs_2018m12_logdate on my_logs_2018m12 (logdate);

create or replace function my_logs_insert_trigger() returns trigger as
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
$$ language plpgsql;

INSERT INTO my_logs(user_id, logdate, data, somestate)
VALUES (6, '2018-11-20', 'test23test23', 3);

create or replace trigger insert_my_logs_trigger
    before insert
    on my_logs
    for each row
execute procedure my_logs_insert_trigger(); --создавать новую таблицу если мы не можем внести данные в эти

drop trigger insert_my_logs_trigger on my_logs;
drop function my_logs_insert_trigger();
