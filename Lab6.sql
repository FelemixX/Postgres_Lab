--Создать таблицу для полнотекстового поиска. Создать столбец типа tsvector
create table full_text_search
(
    id           serial
        primary key,
        text_content text not null,
    tsvector_text_content tsvector
);

alter table full_text_search
    owner to postgres;

--Заполнить столбец данными
UPDATE public.full_text_search SET text_content = 'Nam volutpat diam quis enim sodales, at faucibus ligula gravida. Sed et placerat nibh. Quisque congue augue nisi, a fermentum quam luctus eget. Mauris id tincidunt tortor. Sed elementum velit leo, sed dignissim mi lobortis ut. Etiam id magna nibh. Suspendisse eu erat ligula. Curabitur ut eros ante. Praesent blandit ac erat ut condimentum. Ut sed lobortis erat. Pellentesque malesuada, ex et pellentesque pretium, sem quam accumsan velit, eu fringilla ligula massa in diam. Nulla id nulla lacus. Vivamus aliquam efficitur ex, quis scelerisque justo. Aliquam egestas risus in nibh lacinia interdum. Morbi tristique ligula turpis, in suscipit metus pharetra eu. Fusce non ligula enim.', tsvector_text_content = null WHERE id = 1;
UPDATE public.full_text_search SET text_content = 'Nulla facilisis malesuada convallis. Duis eu rutrum justo. Suspendisse tempor suscipit egestas. Fusce congue ex urna, ut auctor urna rhoncus facilisis. Duis pretium, sapien vel efficitur dapibus, nisl tellus vulputate elit, a bibendum odio ligula vitae tellus. Etiam quis felis erat. Integer facilisis, diam pretium molestie finibus, risus elit volutpat diam, non pellentesque turpis elit eu urna. Donec tempus volutpat ultrices. Etiam convallis pretium pretium. Suspendisse commodo viverra dui ut laoreet. Nullam dictum, risus non porttitor tempus, sapien orci commodo erat, non commodo sem mauris eu nulla. Vestibulum eu dapibus mi. Cras ut nisl eget.', tsvector_text_content = null WHERE id = 2;

--Создать индекс для полнотекстового поиска
CREATE INDEX ON full_text_search USING GIN(tsvector_text_content);
CREATE INDEX ON full_text_search USING GIST(tsvector_text_content);

--Создать триггер для автоматического обновления столбца tsvector. Проверить работоспособность триггера.
DROP TRIGGER update_ts_vector_trigger ON full_text_search;

CREATE OR REPLACE FUNCTION update_ts_vector_trigger() RETURNS trigger AS $$
    BEGIN
        NEW.tsvector_text_content := to_tsvector('english', NEW.text_content);
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ts_vector_trigger BEFORE UPDATE OR INSERT ON full_text_search
    FOR EACH ROW EXECUTE FUNCTION update_ts_vector_trigger();

--Создать свою конфигурацию для полнотекстового поиска
CREATE TEXT SEARCH CONFIGURATION public.my_search_cfg (COPY = pg_catalog.russian);

CREATE TEXT SEARCH DICTIONARY russian_ispell (
    TEMPLATE = ispell,
    DictFile = ru_ru,
    AffFile = ru_ru,
    StopWords = russian
);

-- Set mapping
ALTER TEXT SEARCH CONFIGURATION my_search_cfg
    ALTER MAPPING FOR asciiword, asciihword, hword_asciipart,
                      word, hword, hword_part
    WITH russian_ispell;

-- Ignore
ALTER TEXT SEARCH CONFIGURATION my_search_cfg
    DROP MAPPING FOR email, url, url_path, sfloat, float;

-- Set default
SET default_text_search_config = 'public.my_search_cfg';
-- Show default
SHOW default_text_search_config;

-- Проверить ее работоспособность
SELECT * FROM ts_debug('public.my_search_cfg','Равным образом supernovaes frostnova консультация no с широким активом требуют определения и уточнения соответствующий условий активизации. Значимость этих проблем настолько очевидна, что укрепление и развитие структуры позволяет оценить значение позиций, занимаемых участниками в отношении поставленных задач. Значимость этих проблем настолько очевидна, что начало повседневной работы по формированию позиции позволяет выполнять важные задания по разработке соответствующий условий активизации. С другой стороны консультация с широким активом влечет за собой процесс внедрения и модернизации новых предложений. Повседневная практика показывает, что консультация с широким активом позволяет выполнять важные задания по разработке направлений прогрессивного развития. Не следует, однако забывать, что укрепление и развитие структуры способствует подготовки и реализации систем массового участия.');

-- Выполнить несколько запросов на поиск данных с использованием оператора полнотекстового поиска.
-- Данных в таблице должно быть много(несколько глав книги, несколько страниц текста и т.д.)
-- @@
SELECT ts_headline(text_content, to_tsquery('1810')) FROM full_text_search;
-- ||
SELECT text_content FROM full_text_search WHERE text_content @@ (to_tsquery('наташа') || to_tsquery('зашевелилось')) ORDER BY text_content;
-- &&
SELECT text_content FROM full_text_search WHERE text_content @@ (to_tsquery('накануне') && to_tsquery('Наташа')) ORDER BY text_content;
-- !!
SELECT text_content FROM full_text_search WHERE text_content @@  !! to_tsquery('Lorem') ORDER BY text_content;
-- <->
SELECT text_content, ts_headline(text_content, (to_tsquery('Анна') <-> to_tsquery('Павловна'))) FROM full_text_search;
SELECT text_content FROM full_text_search WHERE text_content @@ (to_tsquery('Lorem') <-> to_tsquery('ipsum')) ORDER BY text_content;

SELECT ts_debug('le réveillon');

SELECT ts_headline('english',
  'The most common type of search
is to find all documents containing given query terms
and return them in order of their similarity to the
query.dddd dsds.',
  to_tsquery('query & similarity'));
