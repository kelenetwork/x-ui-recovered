CREATE TABLE `users` (`id` integer PRIMARY KEY AUTOINCREMENT,`username` text,`password` text);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE `inbounds` (`id` integer PRIMARY KEY AUTOINCREMENT,`user_id` integer,`up` integer,`down` integer,`total` integer,`remark` text,`enable` numeric,`expiry_time` integer,`listen` text,`port` integer,`protocol` text,`settings` text,`stream_settings` text,`tag` text,`sniffing` text,CONSTRAINT `uni_inbounds_tag` UNIQUE (`tag`));
CREATE TABLE `settings` (`id` integer PRIMARY KEY AUTOINCREMENT,`key` text,`value` text);
CREATE TABLE `client_traffics` (`id` integer PRIMARY KEY AUTOINCREMENT,`inbound_id` integer,`enable` numeric,`email` text,`up` integer,`down` integer,`expiry_time` integer,`total` integer,`reset` integer DEFAULT 0,CONSTRAINT `fk_inbounds_client_stats` FOREIGN KEY (`inbound_id`) REFERENCES `inbounds`(`id`),CONSTRAINT `uni_client_traffics_email` UNIQUE (`email`));
