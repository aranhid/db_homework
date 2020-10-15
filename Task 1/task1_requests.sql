-- 1. Создайте сводку по товарам:
-- 1) кол-во товаров каждой категории
SELECT 
    COUNT(`products`.`name`) AS 'Count',
    `groups`.name AS 'Group'
FROM `products`
    JOIN `groups` ON `products`.`group_id` = `groups`.`id`
GROUP BY `products`.`group_id`;

-- 2) среднюю цену товара каждой категории
SELECT 
    AVG(`products`.`price`) AS 'AVGPrice',
    `groups`.name AS 'Group'
FROM `products`
    JOIN `groups` ON `products`.`group_id` = `groups`.`id`
GROUP BY `products`.`group_id`;

-- 3) общее количество единиц каждого товара проданного за все время
SELECT 
    SUM(`sales`.`count`) AS 'Count',
    `products`.`name` AS 'Product'
FROM `sales`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
GROUP BY `sales`.`product_id`;

-- 4) среднемесячное продаваемое количество единиц каждого товара
SELECT 
    AVG(`Count`) as 'Average_count',
    `Product`
FROM (
        SELECT 
            SUM(`sales`.`count`) AS 'Count',
            `products`.`name` AS 'Product'
        FROM `sales`
            JOIN `products` ON `sales`.`product_id` = `products`.`id`
        GROUP BY `sales`.`product_id`, MONTH(`sales`.`date`)
    ) `sales`
GROUP BY `Product`;

CREATE VIEW `month_sum` AS
SELECT 
    SUM(`sales`.`count`) AS 'Count',
    `products`.`name` AS 'Product',
    MONTHNAME(`sales`.`date`) AS 'Month'
FROM `sales`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
GROUP BY `sales`.`product_id`, MONTH(`sales`.`date`);

SELECT 
    AVG(`Count`) as 'Average_count',
    `Product`
FROM month_sum
GROUP BY `Product`;

-- 5) отчет по продажам на каждый день каждого товара с указанием количества и выручки
SELECT
    `products`.`name` AS 'Product',
    SUM(`sales`.`count`) AS 'Count',
    SUM(`sales`.`count`) * `products`.`price` AS 'Proceeds',
    `sales`.`date` AS 'Date'
FROM `sales`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
GROUP BY `sales`.`product_id`, `sales`.`date` LIMIT 10;

-- 6) отчет по продажам на каждый день каждой товарной группы с указанием количества и выручки
CREATE VIEW `proceeds_by_product_and_date` AS
SELECT
    `products`.`name` AS 'Product',
    SUM(`sales`.`count`) AS 'Count',
    SUM(`sales`.`count`) * `products`.`price` AS 'Proceeds',
    `groups`.`name` AS 'Group',
    `sales`.`date` AS 'Date'
FROM `sales`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
    JOIN `groups` ON `products`.`group_id` = `groups`.`id`
GROUP BY `sales`.`product_id`, `sales`.`date`;

SELECT
    `Group`,
    SUM(`Count`) AS 'Count',
    SUM(`Proceeds`) AS 'Proceeds',
    `Date`
FROM proceeds_by_product_and_date
GROUP BY `Group`, `Date` LIMIT 10;

-- 2. Создайте сводку по торговым представителям:
-- 1) кол-во товаров продаваемых каждым представителем в месяц
SELECT
    CONCAT_WS(' ', `salesmen`.`firstname`, `salesmen`.`lastname`) AS 'Salesman',
    SUM(`sales`.`count`) AS `Count`,
    MONTHNAME(`sales`.`date`) AS 'Month'
FROM `sales`
    JOIN `salesmen` ON `sales`.`salesman_id` = `salesmen`.`id`
GROUP BY `sales`.`salesman_id`, MONTH(`sales`.`date`);

-- 2) среднемесячный оборот по каждому представителю
CREATE VIEW `salesmen_proceeds` AS
SELECT
    CONCAT_WS(' ', `salesmen`.`firstname`, `salesmen`.`lastname`) AS 'Salesman',
    SUM(`sales`.`count`) AS `Count`,
    MONTHNAME(`sales`.`date`) AS 'Month'
FROM `sales`
    JOIN `salesmen` ON `sales`.`salesman_id` = `salesmen`.`id`
GROUP BY `sales`.`salesman_id`, MONTH(`sales`.`date`);

SELECT
    `Salesman`,
    AVG(`Count`) AS 'Average_count'
FROM salesmen_proceeds
GROUP BY `Salesman`;

-- 3. Определите зарплату каждого представителя по каждому месяцу, исходя из его оборота и ставки,и посчитайте налог НДФЛ по ставке 13%, подлежащий уплате.
SELECT
    CONCAT_WS(' ', `salesmen`.`firstname`, `salesmen`.`lastname`) AS 'Salesman',
    SUM(`products`.`price`) AS `Proceed`,
    TRUNCATE(SUM(`products`.`price`) * `salesmen`.`rate` - SUM(`products`.`price`) * `salesmen`.`rate` * 0.13, 2) AS `Salary`,
    TRUNCATE(SUM(`products`.`price`) * `salesmen`.`rate` * 0.13, 2) AS `Tax`,
    MONTHNAME(`sales`.`date`) AS 'Month'
FROM `sales`
    JOIN `salesmen` ON `sales`.`salesman_id` = `salesmen`.`id`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
GROUP BY `sales`.`salesman_id`, MONTH(`sales`.`date`);

-- 4. Составьте рейтинги по данным за все время:
-- 1) самых продаваемых товаров
CREATE VIEW `count_of_sold_items` AS
SELECT
    SUM(`sales`.`count`) AS 'Count',
    `products`.`name` AS `Product`
FROM `sales`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
GROUP BY `sales`.`product_id`;

SELECT
    `Count`,
    `Product`
FROM count_of_sold_items
ORDER BY `Count` DESC LIMIT 1;

-- 2) самых доходных групп товаров
SELECT
    `Group`,
    SUM(`Proceeds`) AS 'Proceeds'
FROM proceeds_by_product_and_date
GROUP BY `Group` ORDER BY `Proceeds` DESC LIMIT 1;

-- 3) успешных торговых представителей исходя из количества проданных товаров
SELECT
    CONCAT_WS(' ', `salesmen`.`firstname`, `salesmen`.`lastname`) AS 'Salesman',
    SUM(`sales`.`count`) AS `Count`
FROM `sales`
    JOIN `salesmen` ON `sales`.`salesman_id` = `salesmen`.`id`
GROUP BY `sales`.`salesman_id` ORDER BY `Count` DESC LIMIT 1;

-- 4) успешных торговых представителей исходя из принесенного дохода
SELECT
    CONCAT_WS(' ', `salesmen`.`firstname`, `salesmen`.`lastname`) AS 'Salesman',
    SUM(`sales`.`count` * `products`.`price`) AS `Proceed`
FROM `sales`
    JOIN `salesmen` ON `sales`.`salesman_id` = `salesmen`.`id`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
GROUP BY `sales`.`salesman_id` ORDER BY `Count` DESC LIMIT 1;

-- 5) успешных торговых представителей исходя из заработка
CREATE VIEW `salesmen_salary` AS
SELECT
    CONCAT_WS(' ', `salesmen`.`firstname`, `salesmen`.`lastname`) AS 'Salesman',
    SUM(`products`.`price`) AS `Proceed`,
    TRUNCATE(SUM(`products`.`price`) * `salesmen`.`rate` - SUM(`products`.`price`) * `salesmen`.`rate` * 0.13, 2) AS `Salary`,
    TRUNCATE(SUM(`products`.`price`) * `salesmen`.`rate` * 0.13, 2) AS `Tax`,
    MONTHNAME(`sales`.`date`) AS 'Month'
FROM `sales`
    JOIN `salesmen` ON `sales`.`salesman_id` = `salesmen`.`id`
    JOIN `products` ON `sales`.`product_id` = `products`.`id`
GROUP BY `sales`.`salesman_id`, MONTH(`sales`.`date`);

SELECT
    `Salesman`,
    SUM(`Salary`) AS 'Sum_of_salary'
FROM `salesmen_salary`
GROUP BY `Salesman` ORDER BY `Sum_of_salary` DESC LIMIT 1;