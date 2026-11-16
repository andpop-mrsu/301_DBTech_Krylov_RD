#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм (первые 100 записей)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT u1.name AS user1, u2.name AS user2, m.title AS movie FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON u1.id = r1.user_id JOIN users u2 ON u2.id = r2.user_id JOIN movies m ON m.id = r1.movie_id ORDER BY r1.movie_id, r1.user_id, r2.user_id LIMIT 100;"
echo " "

echo "2. Найти 10 самых старых оценок от разных пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT m.title AS movie, u.name AS user, r.rating, strftime('%Y-%m-%d', r.timestamp, 'unixepoch') AS date FROM ratings r JOIN movies m ON m.id = r.movie_id JOIN users u ON u.id = r.user_id WHERE r.timestamp IN (SELECT MIN(timestamp) FROM ratings GROUP BY user_id) ORDER BY r.timestamp ASC LIMIT 10;"
echo " "

echo "3. Фильмы с максимальным и минимальным средним рейтингом, колонка Рекомендуем."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH avg_ratings AS (SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating FROM movies m JOIN ratings r ON r.movie_id = m.id GROUP BY m.id, m.title, m.year), extremes AS (SELECT MAX(avg_rating) AS max_avg, MIN(avg_rating) AS min_avg FROM avg_ratings) SELECT a.title, a.year, a.avg_rating, CASE WHEN a.avg_rating = e.max_avg THEN 'Да' ELSE 'Нет' END AS \"Рекомендуем\" FROM avg_ratings a CROSS JOIN extremes e WHERE a.avg_rating = e.max_avg OR a.avg_rating = e.min_avg ORDER BY a.year, a.title;"
echo " "

echo "4. Количество оценок и средняя оценка от мужчин за 2011-2014 годы."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT COUNT(*) AS ratings_count, AVG(r.rating) AS avg_rating FROM ratings r JOIN users u ON u.id = r.user_id WHERE u.gender = 'male' AND strftime('%Y', r.timestamp, 'unixepoch') BETWEEN '2011' AND '2014';"
echo " "

echo "5. Список фильмов: средняя оценка и количество пользователей (первые 20)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, AVG(r.rating) AS avg_rating, COUNT(DISTINCT r.user_id) AS users_count FROM movies m JOIN ratings r ON r.movie_id = m.id GROUP BY m.id, m.title, m.year ORDER BY m.year, m.title LIMIT 20;"
echo " "

echo "6. Самый распространенный жанр и количество фильмов в нем."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies UNION ALL SELECT movie_id, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, 1, instr(rest, '|') - 1) ELSE rest END, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, instr(rest, '|') + 1) ELSE '' END FROM split WHERE rest <> ''), genres_flat AS (SELECT movie_id, genre FROM split WHERE genre <> '') SELECT genre, COUNT(*) AS movies_count FROM genres_flat GROUP BY genre ORDER BY movies_count DESC LIMIT 1;"
echo " "

echo "7. 10 последних зарегистрированных пользователей в формате Фамилия Имя|Дата."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS \"Фамилия Имя|Дата регистрации\" FROM users ORDER BY register_date DESC LIMIT 10;"
echo " "

echo "8. Рекурсивный CTE: дни недели дня рождения по годам."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE birthday(y) AS (SELECT 2000 UNION ALL SELECT y + 1 FROM birthday WHERE y < 2025) SELECT y AS year, strftime('%Y-%m-%d', printf('%04d-03-23', y)) AS date, CASE strftime('%w', printf('%04d-03-23', y)) WHEN '0' THEN 'Воскресенье' WHEN '1' THEN 'Понедельник' WHEN '2' THEN 'Вторник' WHEN '3' THEN 'Среда' WHEN '4' THEN 'Четверг' WHEN '5' THEN 'Пятница' WHEN '6' THEN 'Суббота' END AS weekday FROM birthday ORDER BY y;"
echo " "