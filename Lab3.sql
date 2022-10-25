SELECT workdays[1]
FROM employee_table
WHERE id_emp = 2; --Выяснить работает ли работник 2 во вторник

SELECT *
FROM employee_table
WHERE workdays[5] = 1
  and workdays[6] = 1
  and workdays[7] = 1; -- выяснить, какие сотрудники работает с пятницы по воскресенье

UPDATE employee_table
SET workdays[1] = 0; -- установить всем выходной в понедельник

SELECT * FROM employee_table WHERE workdays = '{0,0,0,0,1,1,1}';

SELECT upper(emp_firstname || emp_lastname)
from employee_table; -- соединить имя и фамилию сотрудников в одно поле и привести к верхнему регистру

ALTER TYPE employee ADD VALUE 'new_value';-- внести новое значение в список должностей

SELECT enum_range(null::employee);

ALTER TABLE employee_table
    ADD COLUMN IF NOT EXISTS vacation_start_date date; --добавить в таблицу дат начала отпуска сотрудника
ALTER TABLE employee_table
    ADD COLUMN IF NOT EXISTS vacation_duration int; --и его продолжительность

UPDATE employee_table SET vacation_start_date = vacation_start_date + 25 WHERE id_emp = 3; -- для сотрудника с номером 3 сдвинуть срок отпуска на 14 дней вперед или назад
UPDATE employee_table SET vacation_duration = vacation_duration + 14 WHERE id_emp = 3;  --или так


SELECT * employee_table FOR SHARE;

ALTER TABLE employee_table ADD COLUMN  IF NOT EXISTS birth_date_2 int; --создать поле с датой рождения типа int

ALTER TABLE employee_table ALTER COLUMN birth_date_2 TYPE DATE USING employee_table.birth_date_2::TEXT::DATE; ; --преобразовать его к типу "дата" без потери данных и обратно
ALTER TABLE employee_table ALTER COLUMN birth_date_2 TYPE INTEGER USING to_char(birth_date_2, 'YYMMDD')::INTEGER; -- и обратно


SELECT workdays[1]
FROM employee_table
WHERE id_emp = 2; --Выяснить работает ли работник 2 во вторник

SELECT *
FROM employee_table
WHERE workdays[5] = 1
  and workdays[6] = 1
  and workdays[7] = 1; -- выяснить, какие сотрудники работает с пятницы по воскресенье

UPDATE employee_table
SET workdays[1] = 0; -- установить всем выходной в понедельник

SELECT * FROM employee_table WHERE workdays = '{0,0,0,0,1,1,1}';

SELECT upper(emp_firstname || emp_lastname)
from employee_table; -- соединить имя и фамилию сотрудников в одно поле и привести к верхнему регистру

ALTER TYPE employee ADD VALUE 'new_value';-- внести новое значение в список должностей

SELECT enum_range(null::employee);

ALTER TABLE employee_table
    ADD COLUMN IF NOT EXISTS vacation_start_date date; --добавить в таблицу дат начала отпуска сотрудника
ALTER TABLE employee_table
    ADD COLUMN IF NOT EXISTS vacation_duration int; --и его продолжительность

UPDATE employee_table SET vacation_start_date = vacation_start_date + 25 WHERE id_emp = 3; -- для сотрудника с номером 3 сдвинуть срок отпуска на 14 дней вперед или назад
UPDATE employee_table SET vacation_duration = vacation_duration + 14 WHERE id_emp = 3;  --или так

SELECT * FROMemployee_table FOR UPDATE; --ДОДЕЛАТЬ!

SELECT * employee_table FOR SHARE;

ALTER TABLE employee_table ADD COLUMN  IF NOT EXISTS birth_date_2 int; --создать поле с датой рождения типа int

ALTER TABLE employee_table ALTER COLUMN birth_date_2 TYPE DATE USING employee_table.birth_date_2::TEXT::DATE; ; --преобразовать его к типу "дата" без потери данных и обратно
ALTER TABLE employee_table ALTER COLUMN birth_date_2 TYPE INTEGER USING to_char(birth_date_2, 'YYMMDD')::INTEGER; -- и обратно


CREATE OR REPLACE FUNCTION getEmployeeNameAndJob(id int) RETURNS record AS $$ --написать функцию, которая возвращает имя и должность по ID
DECLARE data RECORD;
BEGIN
  SELECT emp_firstname || ' ' || emp_lastname, employee INTO data FROM employee_table WHERE id_emp = id;
  RETURN data;
END;
$$ LANGUAGE plpgsql;

SELECT getEmployeeNameAndJob(5);

SELECT n.nspname AS test_db_2, --показать эту функцию
       p.proname AS getEmployeeNameAndJob,
       l.lanname AS plpgsql,
       CASE WHEN l.lanname = 'internal' THEN p.prosrc
            ELSE pg_get_functiondef(p.oid)
            END AS definition,
       pg_get_function_arguments(p.oid) AS function_arguments,
       t.typname as return_type
FROM pg_proc p
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
LEFT JOIN pg_language l ON p.prolang = l.oid
LEFT JOIN pg_type t ON t.oid = p.prorettype
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY test_db_2, getEmployeeNameAndJob;


CREATE OR REPLACE FUNCTION getEmployeesBySalary(salaryFrom int, salaryTo int) RETURNS table (name text) AS $$ --написать функцию, которая возвращает имя и должность по ID
BEGIN
    RETURN QUERY
  SELECT emp_firstname || ' ' || emp_lastname FROM employee_table WHERE salary BETWEEN salaryFrom AND salaryTo; --можно так же обычными логическими операторами пользоваться
END;
$$ LANGUAGE plpgsql;

SELECT getEmployeesBySalary(1, 500);

SELECT emp_firstname || ' ' || emp_lastname, salary FROM employee_table WHERE salary >= 100 AND salary <= 500;

CREATE OR REPLACE FUNCTION grantAccess() RETURNS VOID AS $$ --написать функцию-обертку даюую права суперпользователя на какую-либо операцию (3 задание)
    BEGIN
        GRANT SELECT ON employee_table TO simple_user;
    END;
$$ LANGUAGE plpgsql;

SELECT grantAccess();

CREATE OR REPLACE FUNCTION getAllEmployee() RETURNS table (employee text) AS $$ -- вывести всех клиентов: имя + фамилия(5 задание с нового листка)
BEGIN
    RETURN QUERY
    SELECT emp_firstname || ' ' || employee_table.emp_lastname FROM employee_table;
END;
$$ LANGUAGE plpgsql;

SELECT getAllEmployee();

CREATE OR REPLACE FUNCTION employee_table_input_check_trigger() RETURNS TRIGGER AS $data_check_trigger$ --создать триггер, который не позволяет внести отрицательное значение зарплаты или пуcтое имя в таблицу
    BEGIN -- 6 задание
        IF (new.salary < 0) THEN
            raise exception 'Salary out of range';
        ELSEIF(new.emp_firstname) IS NULL OR new.emp_firstname = '' THEN
            raise exception  'First name can not be empty';
        ELSEIF(new.emp_lastname) IS NULL OR new.emp_lastname = ''THEN
            raise exception  'Last name can not be empty';
        END IF;
        RETURN NEW;
    END;
$data_check_trigger$ LANGUAGE plpgsql;

CREATE TRIGGER employee_table_input_check
BEFORE INSERT OR UPDATE ON employee_table
    FOR EACH ROW EXECUTE FUNCTION employee_table_input_check_trigger();


CREATE OR REPLACE FUNCTION employee_table_audit_trigger() RETURNS TRIGGER AS $audit_trigger$--написать триггер аудита основной таблицы (7 задание)
    BEGIN
        INSERT INTO employee_table_audit VALUES(now(), user, TG_OP);
        RETURN NEW;
    END;
$audit_trigger$ LANGUAGE plpgsql;

CREATE TRIGGER employee_table_audit
AFTER INSERT OR UPDATE OR DELETE ON employee_table
    FOR EACH ROW EXECUTE FUNCTION employee_table_audit_trigger();

CREATE TRIGGER employee_table_audit2
AFTER TRUNCATE ON employee_table
    FOR STATEMENT EXECUTE FUNCTION employee_table_audit_trigger();
select * from information_schema.table_privileges


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
