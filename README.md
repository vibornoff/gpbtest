# TL;DR

```sh
cat sql/initdb.sql | mysql -h db -u mariadb -p mariadb
cat data/maillog | ./parse_maillog.pl
./app.pl daemon
```

# Замечания к постановке задачи

- Схема БД адаптирована под MariaDB
- Я отступил от требования *"В таблицу log записываются все остальные строки"* и записываю туда все, что успешно распарсилось;
    * во-первых, в таблице `log` есть индекс по `address`
    * во-вторых, теперь не требуется делать fullscan-выборку из таблицы `message`

# Замечания по парсеру

- Параллелить разбор лога нет смысла, всё равно упрёмся в БД
- Для снижения накладных расходов на общение с БД данные объединяются в батчи
- Можно было бы кешировать statement handle, но при больших размерах батча это не критично
- Для ускорения начальной загрузки можно было бы отложить создание индексов
- По хорошему, надо было бы продумать защиту от дублирования записей на случай падения/перезапуска парсера

# Замечания по веб-приложению

- Можно было бы добавить пагинатор для списка результатов поиска
- Для большего удобства можно было бы добавть FULLTEXT-ндекс для поиска по частичному совпадению, а также в функцию typeahead на страницу с формой, которая по частично введённому тексту предлагала бы несколько вариантов адреса
