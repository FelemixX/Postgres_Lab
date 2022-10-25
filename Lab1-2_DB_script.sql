create type employee as enum ('gg', 'rtt', 'standard_value', 'new_value');

alter type employee owner to postgres;

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

create table employee_table
(
    id_emp              serial,
    emp_firstname       text,
    emp_lastname        text,
    workdays            integer[],
    employee            employee,
    salary              numeric(7, 2),
    vacation_start_date date,
    vacation_duration   integer,
    birth_date_2        integer
);

alter table employee_table
    owner to postgres;

grant select on employee_table to simple_user;

create table data
(
    "?column?" text
);

alter table data
    owner to postgres;

create table employee_table_audit
(
    timestamp timestamp,
    operation varchar,
    username  varchar
);

alter table employee_table_audit
    owner to postgres;

create function getemployeenameandjob(id integer) returns record
    language plpgsql
as
$$
DECLARE data RECORD;
BEGIN
  SELECT emp_firstname || ' ' || emp_lastname, employee INTO data FROM employee_table WHERE id_emp = id;
  RETURN data;
END;
$$;

alter function getemployeenameandjob(integer) owner to postgres;

create function getemployeesbysalary(salaryfrom integer, salaryto integer)
    returns TABLE(name text)
    language plpgsql
as
$$ --написать функцию, которая возвращает имя и должность по ID
BEGIN
    RETURN QUERY
  SELECT emp_firstname || ' ' || emp_lastname FROM employee_table WHERE salary BETWEEN salaryFrom AND salaryTo; --можно так же обычными логическими операторами пользоваться
END;
$$;

alter function getemployeesbysalary(integer, integer) owner to postgres;

create function getallemployee()
    returns TABLE(employee text)
    language plpgsql
as
$$ -- вывести всех клиентов: имя + фамилия
BEGIN
    RETURN QUERY
    SELECT emp_firstname || ' ' || employee_table.emp_lastname FROM employee_table;
END;
$$;

alter function getallemployee() owner to postgres;

create function employee_table_audit_trigger() returns trigger
    language plpgsql
as
$$--написать триггер аудита основной таблицы (7 задание)
    BEGIN
        INSERT INTO employee_table_audit VALUES(now(), user, TG_OP);
        RETURN NEW;
    END;
$$;

alter function employee_table_audit_trigger() owner to postgres;

create trigger employee_table_audit
    after insert or update or delete
    on employee_table
    for each row
execute procedure employee_table_audit_trigger();

create trigger employee_table_audit2
    after truncate
    on employee_table
execute procedure employee_table_audit_trigger();

create function grantaccess() returns void
    language plpgsql
as
$$ --написать функцию-обертку даюую права суперпользователя на какую-либо операцию (3 задание)
    BEGIN
        GRANT SELECT ON employee_table TO simple_user;
    END;
$$;

alter function grantaccess() owner to postgres;

create function employee_table_input_check_trigger() returns trigger
    language plpgsql
as
$$ --создать триггер, который не позволяет внести отрицательное значение зарплаты или пуcтое имя в таблицу
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
$$;

alter function employee_table_input_check_trigger() owner to postgres;

create trigger employee_table_input_check
    before insert or update
    on employee_table
    for each row
execute procedure employee_table_input_check_trigger();

