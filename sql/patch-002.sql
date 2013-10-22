CREATE TABLE users (
    username TEXT PRIMARY KEY,
    password TEXT,
    registered timestamptz
);

ALTER TABLE plans add column added_by TEXT references users ( username );
