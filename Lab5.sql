--Проверить, что в строке есть число
SELECT 'L123JKDFJAL;SDJ;ASD' ~ '\d';

--Найти в стркое электронный адрес

SELECT regexp_match('gig@huig.obosralsa',
                    '(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])');

SELECT regexp_matches('keke@meme.ru aboba@mail.kek', '\w+@\w+\.\w+', 'gm');

--Найти файлы с расширением .txt

SELECT regexp_matches('lajsdf.txt lkasdjf;ljk.doc lsdkajf.txd aslhjk237143.txt', '\w+\d*\.txt', 'gm');

--Разделить поле ФИО на Имя Фамилию Отчество

SELECT substring('Usususu Афывфы Афвыфыв', '(([А-ЯЁа-яёA-Za-z]+)( [А-ЯЁа-яёA-Za-z]{1}).+( [А-ЯЁа-яёA-Za-z]{1}).+)');

--Преобразовать номер мобильного телефона к виду +7( код) 345-67-89 и записать обратно в таблицу. Вывести код оператора в отдельную колонку

SELECT regexp_match('+7(917) 194-57-34',
                    '^((8|\+374|\+994|\+995|\+375|\+7|\+380|\+38|\+996|\+998|\+993)[\- ]?)?\(?\d{3,5}\)?[\- ]?\d{1}[\- ]?\d{1}[\- ]?\d{1}[\- ]?\d{1}[\- ]?\d{1}(([\- ]?\d{1})?[\- ]?\d{1})?$');

SELECT substring('8(917) 194-57-34', '^((8|\+7)[\- ]?)?(\(?\d{3}\)?[\- ]?)?[\d\- ]{7,10}$');
--(^[\+]?\d(\(\d+\)))[\s]((\d+)\-(\d+)\-(\d+)) --ПОПРОБОВАТЬ НАПИСАТЬ ДЛЯ ЭТОГО ФУНКЦИЮ И ПРОВЕРЯТЬ СТРОКУ ЧАСТЯМИ

CREATE TABLE phones(phone_number text);
INSERT INTO phones VALUES ('+7(931) 112-66-77'), ('7(918) 491-74-43'), ('8(961) 326-05-05');

DROP FUNCTION getPhoneNumberData();

CREATE OR REPLACE FUNCTION getPhoneNumberData() RETURNS TABLE (data text[]) AS $$
DECLARE
    _row RECORD;
BEGIN
    FOR _row IN SELECT phone_number FROM phones LOOP
            RETURN QUERY SELECT regexp_matches(_row.phone_number, '(^[\+]?\d(\(\d+\)))[\s]((\d+)\-(\d+)\-(\d+))', 'm');
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT getPhoneNumberData(); --ru.stackoverflow.com/questions/714714/Регулярное-выражение-для-поиска-мобильного-телефона-в-тексте

SELECT regexp_replace('89171945734', '(?:\+|\d)[\d\-\(\) ]{9,}\d');

--Извлечь из строки данные адреса: индекс, город улица или проспект, название улицы, номер дома

SELECT regexp_matches('198320, Нижний Новгород, ул. Кубинская, 78\3',
                      '\d{6}[\,\s]*[г\.]*\s*[А-Яа-я\-|\s]{2,}[\,\s]*[ул|пер|пр|б-р]*[\.\s]*[А-Яа-я\-]{2,}[\,\s]*[д\.|c\.]*\s*\d{1,3}[\\*\d{1,3}]*[\,\s\-]*[кв\.]*\s*\d{1,3}\s*',
                      'gmi');

--Пусть в таблице хранится файл "с мусором". Убрать "мусорные" данные.

CREATE TABLE aa( v text);
INSERT INTO aa VALUES ('мама128'), ('мыл456а'), ('р789аму');

SELECT * FROM aa as data;

DROP FUNCTION removeRedundantSymbols();

CREATE OR REPLACE FUNCTION removeRedundantSymbols() RETURNS TABLE (data text[]) AS $$
DECLARE
    _row RECORD;
BEGIN
    FOR _row IN SELECT v FROM aa LOOP
            RETURN QUERY SELECT regexp_matches(_row.v, '[а-яА-Яa-zA-Z]+', 'gis');
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT removeRedundantSymbols();

--можно просто убирать цифры из строк и заносить их обратно 
