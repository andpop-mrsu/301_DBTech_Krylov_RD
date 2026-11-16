#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма: название, год, средний рейтинг и ранг по убыванию среднего (топ-10)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH movie_avg AS (SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating FROM movies m JOIN ratings r ON r.movie_id = m.id GROUP BY m.id, m.title, m.year) SELECT title, year, avg_rating, RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating FROM movie_avg ORDER BY rank_by_avg_rating LIMIT 10;"
echo " "

echo "2. Рекурсивный CTE: все жанры, средний рейтинг и ранг жанра по убыванию среднего."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies UNION ALL SELECT movie_id, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, 1, instr(rest, '|') - 1) ELSE rest END, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, instr(rest, '|') + 1) ELSE '' END FROM split WHERE rest <> ''), genres_flat AS (SELECT movie_id, genre FROM split WHERE genre <> ''), genre_avg AS (SELECT g.genre, AVG(r.rating) AS avg_rating FROM genres_flat g JOIN ratings r ON r.movie_id = g.movie_id GROUP BY g.genre) SELECT genre, avg_rating, RANK() OVER (ORDER BY avg_rating DESC) AS rank FROM genre_avg ORDER BY rank;"
echo " "

echo "3. Количество фильмов в каждом жанре (по убыванию)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies UNION ALL SELECT movie_id, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, 1, instr(rest, '|') - 1) ELSE rest END, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, instr(rest, '|') + 1) ELSE '' END FROM split WHERE rest <> '') SELECT genre, COUNT(*) AS movie_count FROM split WHERE genre <> '' GROUP BY genre ORDER BY movie_count DESC;"
echo " "

echo "4. Жанры с наибольшим числом тегов: genre, tag_count, tag_share (%)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies UNION ALL SELECT movie_id, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, 1, instr(rest, '|') - 1) ELSE rest END, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, instr(rest, '|') + 1) ELSE '' END FROM split WHERE rest <> ''), genres_flat AS (SELECT movie_id, genre FROM split WHERE genre <> ''), genre_tags AS (SELECT g.genre, COUNT(t.id) AS tag_count FROM genres_flat g JOIN tags t ON t.movie_id = g.movie_id GROUP BY g.genre), total AS (SELECT COUNT(*) AS total_tags FROM tags) SELECT gt.genre, gt.tag_count, ROUND(gt.tag_count * 100.0 / t.total_tags, 2) AS tag_share FROM genre_tags gt CROSS JOIN total t ORDER BY gt.tag_count DESC;"
echo " "

echo "5. Статистика по пользователям: число оценок, средний рейтинг, первая и последняя даты (топ-10)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT user_id, COUNT(*) AS rating_count, AVG(rating) AS avg_rating, strftime('%Y-%m-%d', MIN(timestamp), 'unixepoch') AS first_rating_date, strftime('%Y-%m-%d', MAX(timestamp), 'unixepoch') AS last_rating_date FROM ratings GROUP BY user_id ORDER BY rating_count DESC LIMIT 10;"
echo " "

echo "6. Сегментация пользователей: user_id, число оценок, число тегов, категория (CASE)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH user_stats AS (SELECT u.id AS user_id, COALESCE(r.rating_count, 0) AS rating_count, COALESCE(t.tag_count, 0) AS tag_count FROM users u LEFT JOIN (SELECT user_id, COUNT(*) AS rating_count FROM ratings GROUP BY user_id) r ON r.user_id = u.id LEFT JOIN (SELECT user_id, COUNT(*) AS tag_count FROM tags GROUP BY user_id) t ON t.user_id = u.id) SELECT user_id, rating_count, tag_count, CASE WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные' WHEN rating_count < 5 AND tag_count < 5 THEN 'Пассивные' WHEN tag_count > rating_count THEN 'Комментаторы' WHEN rating_count > tag_count THEN 'Оценщики' ELSE 'Прочие' END AS category FROM user_stats ORDER BY user_id;"
echo " "

echo "7. Для каждого пользователя: имя и последний оцененный фильм (LEFT JOIN, NULL если не оценивал)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH last_rating AS (SELECT r.user_id, r.movie_id, r.timestamp, ROW_NUMBER() OVER (PARTITION BY r.user_id ORDER BY r.timestamp DESC) AS rn FROM ratings r) SELECT u.id AS user_id, u.name, m.title AS last_rated_movie_title, lr.timestamp AS last_rating_timestamp FROM users u LEFT JOIN last_rating lr ON lr.user_id = u.id AND lr.rn = 1 LEFT JOIN movies m ON m.id = lr.movie_id ORDER BY u.id;"
echo " "