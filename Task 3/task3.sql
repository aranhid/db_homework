-- Функция, определяющая по дате рождения, является ли человек юбиляром в текущем году. Функция возвращает возраст юбиляра, в противном случае – NULL.
DELIMITER //
CREATE FUNCTION `jubilee`(birth_date DATE)
RETURNS INT
NO SQL
BEGIN
    DECLARE age INT;
    SET age = YEAR(NOW()) - YEAR(birth_date);
    IF MOD(age, 5) = 0 THEN
        RETURN age;
    ELSE
        RETURN NULL;
    END IF;
END//
DELIMITER ;

-- Функция, преобразующая значение ФИО в фамилию с инициалами (например, Иванов Иван Сергеевич в Иванов И.С.). При невозможности преобразования функция возвращает строку ######.
DELIMITER //
CREATE FUNCTION `initials`(`fullName` VARCHAR(255))
RETURNS VARCHAR(255)
NO SQL
BEGIN
    DECLARE `initials` VARCHAR(255);
    DECLARE `_fullname` VARCHAR(255);
    DECLARE `surname` VARCHAR(255);
    DECLARE `names` VARCHAR(255);
    DECLARE `name` VARCHAR(255);
    DECLARE `patronymic` VARCHAR(255);

    SET `_fullname` = TRIM(`fullName`);
    IF LENGTH(`_fullName`) - LENGTH(REPLACE(`_fullName`,' ','')) = 2 THEN
        SET `surname` = SUBSTRING_INDEX(`_fullName`, ' ', 1);
        SET `names` = SUBSTRING_INDEX(`_fullName`, ' ', -2);
        SET `name` = SUBSTRING_INDEX(`names`, ' ', 1);
        SET `patronymic` = SUBSTRING_INDEX(`names`, ' ', -1);
        SET `initials` = CONCAT(`surname`, ' ', LEFT(`name`, 1), '.', LEFT(`patronymic`, 1), '.');
        RETURN `initials`;
    ELSE
        RETURN '######';
    END IF;
END//
DELIMITER ;

-- Функция, высчитывающая доход торгпреда с продажи, исходя из ставки и суммы продажи.
drop function if exists `salesman_income`;
DELIMITER //
CREATE FUNCTION `salesman_income`(`sale_id` INT)
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE `income` DECIMAL(10, 2);
    DECLARE `salesman_id` INT;
    DECLARE `rate` FLOAT;
    DECLARE `price` DECIMAL(10, 2);
    DECLARE `count` INT;
    SELECT `sales`.`salesman_id` INTO `salesman_id` FROM `sales` WHERE `id` = `sale_id`;
    SELECT `salesmen`.`rate` INTO `rate` FROM `salesmen` WHERE `id` = `salesman_id`;
    SELECT `sales`.`price` INTO `price` FROM `sales` WHERE `id` = `sale_id`;
    SELECT `sales`.`count` INTO `count` FROM `sales` WHERE `id` = `sale_id`;
    SET `income` = `price` * `count` * `rate`;
    RETURN `income`;
END//
DELIMITER ;
select `salesman_income`(1);

-- Функция, высчитывающая доход компании с продажи, исходя из стоимости товара и проданного количества.
drop function if exists `company_income`;
DELIMITER //
CREATE FUNCTION `company_income`(`sale_id` INT)
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE `income` DECIMAL(10, 2);
    DECLARE `price` DECIMAL(10, 2);
    DECLARE `count` INT;
    SELECT `sales`.`price` INTO `price` FROM `sales` WHERE `id` = `sale_id`;
    SELECT `sales`.`count` INTO `count` FROM `sales` WHERE `id` = `sale_id`;
    SET `income` = `price` * `count`;
    RETURN `income`;
END//
DELIMITER ;
select `company_income`(1);

-- Процедура, выводящая список всех торгпредов–юбиляров текущего года (с указанием даты юбилея и возраста).
DROP PROCEDURE IF EXISTS `get_all_jubilees`;
DELIMITER //
CREATE PROCEDURE `get_all_jubilees`()
    LANGUAGE SQL
    NOT DETERMINISTIC
    CONTAINS SQL
    SQL SECURITY DEFINER
BEGIN
    SELECT `lastname`, `firstname`, `birth_date`, `jubilee`(`birth_date`) as 'age' FROM `salesmen` WHERE `jubilee`(birth_date); 
END//
DELIMITER ;
CALL `get_all_jubilees`();

-- Процедура, выводящая список всех товаров в заданной группе (по id группы) в виде: товар, группа, артикул, отпускная цена, наличие на складе.
DROP PROCEDURE IF EXISTS `get_all_products_by_group_id`;
DELIMITER //
CREATE PROCEDURE `get_all_products_by_group_id`(IN `group_id` INT)
    LANGUAGE SQL
    NOT DETERMINISTIC
    CONTAINS SQL
    SQL SECURITY DEFINER
BEGIN
    SELECT 
        `products`.`name` AS 'Product',
        `groups`.`name` AS 'Group',
        `vendor_code`,
        `price`,
        `availability`
    FROM `products`
    JOIN `groups` ON `products`.`group_id` = `groups`.`id`
    WHERE `products`.`group_id` = `group_id`;
END//
DELIMITER ;
CALL `get_all_products_by_group_id`(1);

-- Процедура, выдающая по названию товара, список его продаж с указанием ФИО торгпреда (в формате Фамилия И.О.) за последние 7 дней (по умолчанию) / 14 дней / 30 дней.
DROP PROCEDURE IF EXISTS `get_all_sales_by_product`;

DELIMITER //
CREATE PROCEDURE `get_all_sales_by_product`(IN `product_name` VARCHAR(255), IN `days` INT)
    LANGUAGE SQL
    NOT DETERMINISTIC
    CONTAINS SQL
    SQL SECURITY DEFINER
BEGIN
    SET `days` = IFNULL(`days`, 7);
    SELECT 
        `products`.`name` AS 'Product',
        `sales`.`date`,
        CONCAT(`salesmen`.`lastname`, ' ', LEFT(`salesmen`.`firstname`, 1), '.', LEFT(`salesmen`.`patronymic`, 1)) AS `Salesman`
    FROM `sales`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
    JOIN `salesmen` on `sales`.`salesman_id` = `salesmen`.`id`
    WHERE `products`.`name` = `product_name` AND `date` BETWEEN NOW() - INTERVAL `days` DAY AND NOW();
END//
DELIMITER ;

CALL `get_all_sales_by_product`('Xiaomi Mi Robot Vacuum', 45);

-- Процедура, выводящая сведения о несоответствии цены в журнале продаж заявленной цене самого товара с учетом времени последнего изменения цены (если изменение цены произошло позднее даты продажи, такие данные не учитывать). Если таких случаев не обнаружено, процедура должна выводить сообщение об этом.
DROP PROCEDURE IF EXISTS `get_wrong_price`;

DELIMITER //
CREATE PROCEDURE `get_wrong_price`()
    LANGUAGE SQL
    NOT DETERMINISTIC
    CONTAINS SQL
    SQL SECURITY DEFINER
BEGIN
    IF (
        SELECT 
            COUNT(`sales`.`id`)
        FROM `sales`
        JOIN `products` ON `sales`.`product_id` = `products`.`id`
        WHERE `sales`.`price` != `products`.`price` AND `sales`.`date` < `products`.`edit_date`
    ) THEN
        SELECT 
            `products`.`name` AS 'Name',
            `products`.`price` AS 'Original_price',
            `sales`.`price` AS 'Sale_price'
        FROM `sales`
        JOIN `products` ON `sales`.`product_id` = `products`.`id`
        WHERE `sales`.`price` != `products`.`price` AND `sales`.`date` < `products`.`edit_date`;
    ELSE
        SELECT 'No such cases.' AS 'Result';
    END IF;
END//
DELIMITER ;

CALL `get_wrong_price`();