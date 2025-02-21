CREATE TABLE message (
    created     TIMESTAMP NOT NULL,
    id          VARCHAR(255) NOT NULL, -- TODO уточнить максимально допустимую длину `id=...`
    int_id      CHAR(16) NOT NULL,
    str         TEXT NOT NULL,
    status      BOOL,
    --
    CONSTRAINT  message_id_pk PRIMARY KEY(id)
);

CREATE INDEX message_created_idx ON message (created);

CREATE INDEX message_int_id_idx ON message (int_id);

CREATE TABLE log (
    created     TIMESTAMP NOT NULL,
    int_id      CHAR(16) NOT NULL,
    str         TEXT,
    address     VARCHAR(255)    -- для email-адреса 255 символов точно хватит :)
);

CREATE INDEX log_address_idx ON log (address);
