create table if not exists userinfo (
    id        INT NOT NULL PRIMARY KEY,
    name      VARCHAR(32),
    password  VARCHAR(65535),
    num_lend  INT
);

create table if not exists lendinfo{
    id         INTEGER NOT NULL PRIMARY KEY,
    user_id    INTEGER NOT NULL,
    book_id    INTEGER NOT NULL,
    finish     INTEGER 
}
