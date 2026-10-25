create table data_2022_oct 
(
    event_time  timestamptz,
    event_type char(100),
    product_id  integer,
    price real,
    user_id bigint,
    user_session text
);