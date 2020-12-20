-- Создайте триггер на изменение цены в таблице товаров таким образом, чтобы в дополнительную таблицу сохранялись: дата изменения, старая цена, новая цена. Дополнительную таблицу (это будет некий журнал изменения цен) нужно предварительно создать.
CREATE TABLE `price_log` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` INT UNSIGNED NOT NULL,
    `edit_date` DATE NOT NULL,
    `old_price` DECIMAL(10, 2) NOT NULL,
    `new_price` DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

DELIMITER //
CREATE TRIGGER `trigger_change_price` 
AFTER UPDATE ON `products` 
FOR EACH ROW 
BEGIN
    IF (OLD.`price` != NEW.`price`) THEN
        INSERT INTO `price_log`
            (`product_id`, `edit_date`, `old_price`, `new_price`)
        VALUES
            (OLD.`id`, NOW(), OLD.`price`, NEW.`price`);
    END IF;
END//
DELIMITER ;
-- Создайте триггер на удаление группы товаров таким образом, чтобы при ее удалении все товары из этой группы оказывались не привязанными ни к одной группе, а их наличие на складе менялось в положение нет в наличии.
ALTER TABLE `products` MODIFY `group_id` INT UNSIGNED;

DELIMITER //
CREATE TRIGGER `trigger_delete_group` 
BEFORE DELETE ON `groups` 
FOR EACH ROW 
BEGIN
    UPDATE `products` SET `group_id` = NULL, `availability` = '0' WHERE `group_id` = OLD.`id`;
END//
DELIMITER ;

INSERT INTO `groups` 
    (`name`) 
VALUES 
    ('TEST');

INSERT INTO `products`
    (`name`, `group_id`, `price`)
VALUES
    ('TEST PRODUCT', '6', '9999.99');

DELETE FROM `groups` WHERE `id` = '6' LIMIT 1;