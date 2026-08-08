CREATE TABLE IF NOT EXISTS `keystore` (
    `device_id` CHAR(36) NOT NULL PRIMARY KEY,
    `client_pubkey` VARCHAR(255),
    `server_pubkey` VARCHAR(255),
    `server_prvkey` VARCHAR(255),
    `expires` BIGINT NOT NULL
);