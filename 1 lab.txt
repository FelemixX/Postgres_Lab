    SELECT *
    FROM generate_series(1, 5); --наделать столбцов с номерами от 1 до 5 и заполнить их числами от 1 до 5

    SELECT date(generate_series(now(), now() + '1 week', '1 day')); /*выбрать конвертировать в дату(сгенерировать числа(от время начала текущей транзакции
     до время начала текущей транзации с конкатенацией несолькоих строк ) */

    SELECT generate_series(1, 10) AS key, (random() * 100)::numeric(4, 2), repeat('1', (random() * 25)::integer)
    ORDER BY random();
    /*выбрать сгенерированные числа от 1 до 10 назвать столбик key. Еще выбрать рандомные числа до 100, приведенные к
    числам с плавающей запятой (четыре знака в общем, из них два после запятой) повторить один раз (сгенерировать число размером до 25) сортировать по рандомному числу  */
    SELECT (random() * 21 + 22)::int as size
    from generate_series(1, 3);
    /* выбрать (рандомные числа между 21 и 22) привести к целому числу из столбцов от 1 до 3*/
    SELECT md5(random()::text) AS product_name
    FROM generate_series(1, 3);
    /* выбрать сгенерировать мд5 хэш(рандомная строка) дать ему имя product_name из столбцов от 1 до 3 */
    SELECT (array ['red', 'green', ' blue'])[ceil(random() * 3)] as color
    from generate_series(1, 5);
    /* выбрать (массив из строк rgb ) (массив округленных в большую сторону рандомных чисел не больше тройки) импортировать как color вставить
       в строчки от 1 до 5 */
    SELECT random()::int::bool
    from generate_series(1, 3);
    /* выбрать (случайное число, приведенное к целочисленному типу, который потом приведет к булевому) из столбцов от 1 до 3 */


    CREATE TABLE employees as
    select generate_series(1, 3)                                    as id,
           md5(random()::text)                                      as name,
           array [make_date(2023, 01, 10), make_date(2023, 03, 10)] as vacation,
           floor(random() * (30 - 10) + 25)                         as age;
    --ВОЗРАСТ, ИМЯ, ОТПУСК[от, до] (2023 год, с января до марта)

    CREATE TABLE random_values AS
    SELECT generate_series(1, 100000) as id,
           random() + 100             as random;

    SELECT *
    FROM random_values
    LIMIT 10;

    EXPLAIN
    SELECT *
    FROM random_values
    WHERE random >= 100.844;

    CREATE INDEX rand_index ON random_values (random);
    --одно поле с ID (100k), другое поле со всякими рандомными данными
    --Seq Scan on random_values  (cost=0.00..1791.00 rows=15516 width=12)


    select now() - query_start as runinr_for, query
    from pg_stat_activity
    order by 1 desc
    limit 5;
    select *
    from pg_locks
    where not granted;
    select a1.query as blocking_query, a2.query as waiting_query, t.schemaname || '.' || t.relname as locked_table
    from pg_stat_activity a1
             join pg_locks p1 on a1.pid = p1.pid and p1.granted
             join pg_locks p2 on p1.relation = p2.relation and not p2.granted
             join pg_stat_activity a2 on a2.pid = p2.pid
             join pg_stat_all_tables t on p1.relation = t.relid;



    create table my_logs
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
            raise exception 'date out of range';
        end if;
        return null;
    end;
    $$ language plpgsql;



    create or replace trigger insert_my_logs_trigger
        before insert
        on my_logs
        for each row
    execute procedure my_logs_insert_trigger();

    -- select *
    -- from my_logs;
    -- select *
    -- from only my_logs;
    -- select *
    -- from my_logs_2018m11;
    --
    -- set constraint_exclusion = off;
    -- explain
    -- select *
    -- from my_logs
    -- where (logdate > date'2018-12-01');
    --
    -- set constraint_exclusion = on;
    -- explain
    -- select *
    -- from my_logs
    -- where (logdate > date'2018-12-01');

    INSERT INTO my_logs(user_id, logdate, data, somestate) VALUES (3, '2018-12-10', 'testtest', 1)
    select * from pg_trigger;

    SELECT
        routine_definition
    FROM
        information_schema.routines
    WHERE
        specific_schema LIKE 'public'
