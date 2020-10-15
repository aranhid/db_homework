<?php

header('Content-Type: text/plain; charset=utf-8');

/**
 * Функция для получения случайного элемента из массива
 */
function get_random($array)
{
    return $array[rand(0, count($array) - 1)];
}

// список ID торговых представителей - настройте свои значения
$salesmen = [1, 2, 3, 4, 5];

// список ID товаров, здесь задан интервал с 1 по 50 - настройте свои значения
$products = range(1, 33);

// дата начала журнала
$start_date = strtotime('2020-06-01');

// дата конца журнала
$end_date = strtotime('2020-09-18');


/**
 * Подготовка данных
 */

$date = $start_date;

while ($date < $end_date)
{
  $need_count = rand(40, 80); // кол-во продаж за дату (от 40 до 80), настройте свое значение

  $sales = [];

  while(--$need_count)
  {
    // проверьте соответствие ключей массива именам ваших колонок
    $sales[] = [
      'date'        => date('Y-m-d', $date),
      'salesman_id' => get_random($salesmen),
      'product_id'  => get_random($products),
      'count'       => rand(1, 20), // случайное количество проданного товара
    ];
  }

  $rows = [];

  foreach ($sales as $row)
  {
    $rows[] = '("' . implode('", "', array_values($row)) . '")';
  }

  echo 'INSERT INTO `sales` (`' . implode('`, `', array_keys($sales[0])) . '`) VALUES '; 
  echo "\n  " . implode(",\n  ", $rows) . ";\n\n";

  $date = strtotime('+1 day', $date);
}