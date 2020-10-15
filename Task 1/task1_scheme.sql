-- create database semester5task1;

create table `groups` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

create table `products` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `group_id` INT UNSIGNED NOT NULL,
    `price` DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (`id`, `name`),
    CONSTRAINT `products_group_id_foreign` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`)
) DEFAULT CHARSET=utf8;

create table `salesmen` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `firstname` VARCHAR(255) NOT NULL,
    `lastname` VARCHAR(255) NOT NULL,
    `rate` FLOAT NOT NULL,
    PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

create table `sales` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `salesman_id` INT UNSIGNED NOT NULL,
    `product_id` INT UNSIGNED NOT NULL,
    `count` INT NOT NULL DEFAULT 0,
    `date` DATETIME,
    PRIMARY KEY (`id`),
    CONSTRAINT `sales_salesman_id_foreign` FOREIGN KEY (`salesman_id`) REFERENCES `salesmen` (`id`),
    CONSTRAINT `sales_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) DEFAULT CHARSET=utf8;