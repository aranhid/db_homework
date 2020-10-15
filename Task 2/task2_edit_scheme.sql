-- Модифицируйте БД учета продаж торговых представителей:
-- 1. Торговым представителям добавьте поля:
-- 1) имя (после фамилии)
ALTER TABLE `salesmen` MODIFY `firstname` VARCHAR(255) NOT NULL AFTER `lastname`;

-- 2) отчество (после имени)
ALTER TABLE `salesmen` ADD `patronymic` VARCHAR(255) NOT NULL AFTER `firstname`;

-- 3) дата рождения (после отчества)
ALTER TABLE `salesmen` ADD `birth_date` DATE NOT NULL AFTER `patronymic`;

-- 4) ИНН (после даты рождения)
ALTER TABLE `salesmen` ADD `itn` BIGINT NOT NULL AFTER `birth_date`;

-- 5) сумма оклада (после ставки)
ALTER TABLE `salesmen` ADD `salary` DECIMAL(10, 2) AFTER `rate`;

-- 2. Товарам:
-- 1) закупочная цена (перед ценой)
ALTER TABLE `products` ADD `purchase_price` DECIMAL(10, 2) AFTER `group_id`;
-- 1. 1) заполнить по всем товарам закупочную цену с коэффициентом 0.5
UPDATE `products` SET `purchase_price` = 0.5 * `price`;

-- 2) артикул (после названия)
ALTER TABLE `products` ADD `vendor_code` VARCHAR(255) AFTER `name`;

-- 3) флаг наличия на складе
ALTER TABLE `products` ADD `availability` TINYINT(1);
UPDATE `products` SET `availability` = 1;

-- 4) дата изменения цены
ALTER TABLE `products` ADD `edit_date` DATE;
UPDATE `products` SET `edit_date` = NOW();

-- 3. В журнал продаж:
-- 1) цену (перед количеством)
ALTER TABLE `sales` ADD `price` DECIMAL(10, 2) AFTER `product_id`;
-- 1.1) заполнить цену по данным из таблицы товаров
UPDATE `sales`, `products` SET `sales`.`price` = `products`.`price` WHERE `sales`.`product_id` = `products`.`id`;

-- 2) доход компании (после количества)
ALTER TABLE `sales` ADD `company_income` DECIMAL(10, 2) AFTER `count`;
-- 2.1) заполнить все проданные по данным из таблицы товаров (кол-во * цену)
UPDATE `sales` SET `company_income` = `count` * `price`;

-- 3) доход торгпреда (после дохода компании)
ALTER TABLE `sales` ADD `salesman_income` DECIMAL(10, 2) AFTER `company_income`;
-- 3.1) заполнить все проданные по данным из таблицы товаров и с учетом ставки соответствующего торгпреда
UPDATE `sales`, `salesmen` SET `sales`.`salesman_income` = `sales`.`company_income` * `salesmen`.`rate` WHERE `sales`.`salesman_id` = `salesmen`.`id`;