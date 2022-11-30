create table aa
(
    v text
);

alter table aa
    owner to postgres;

create table phones
(
    phone_number text
);

alter table phones
    owner to postgres;

create function removeredundantsymbols()
    returns TABLE(data text[])
    language plpgsql
as
$$
DECLARE
    _row RECORD;
BEGIN
    FOR _row IN SELECT v FROM aa LOOP
            RETURN QUERY SELECT regexp_matches(_row.v, '[а-яА-Яa-zA-Z]+', 'gis');
    END LOOP;
END;
$$;

alter function removeredundantsymbols() owner to postgres;

create function getphonenumberdata()
    returns TABLE(data text[])
    language plpgsql
as
$$
DECLARE
    _row RECORD;
BEGIN
    FOR _row IN SELECT phone_number FROM phones LOOP
            RETURN QUERY SELECT regexp_matches(_row.phone_number, '(^[\+]?\d(\(\d+\)))[\s]((\d+)\-(\d+)\-(\d+))', 'm');
    END LOOP;
END;
$$;

alter function getphonenumberdata() owner to postgres;

