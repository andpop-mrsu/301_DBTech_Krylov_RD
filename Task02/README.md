# Task02. ETL: подготовка скриптов для создания таблиц и добавления данных

## Описание

Утилита `make_db_init.py` генерирует SQL-скрипт `db_init.sql` для автоматического создания таблиц в базе `movies_rating.db` и загрузки в них данных из исходных текстовых файлов.

## Требования к окружению

Для корректной работы скрипта `db_init.bat` на компьютере должны быть установлены:

1. **Python версии 3.6 или выше**
   Скачать: https://www.python.org/downloads/
   При установке на Windows отметить галочку «Add Python to PATH».

2. **SQLite (утилита командной строки sqlite3)**
   Скачать: https://www.sqlite.org/download.html
   Раздел «Precompiled Binaries for Windows» -> sqlite-tools-win32-x86-*.zip.
   Распаковать sqlite3.exe в папку (например, C:\sqlite) и добавить её в PATH.

3. **Git Bash** (для запуска db_init.bat на Windows, поскольку файл содержит bash-шебанг)
   Устанавливается вместе с Git for Windows: https://git-scm.com/download/win

## Структура файлов

- movies.csv - информация о фильмах (movieId, title, genres)
- ratings.csv - оценки пользователей (userId, movieId, rating, timestamp)
- tags.csv - теги пользователей (userId, movieId, tag, timestamp)
- users.txt - пользователи (id|name|email|gender|register_date|occupation)
- make_db_init.py - утилита генерации SQL-скрипта
- db_init.sql - сгенерированный SQL-скрипт
- db_init.bat - shell-скрипт запуска утилиты и загрузки в БД
- movies_rating.db - база данных SQLite (создаётся автоматически)

## Схема базы данных

### Таблица movies
- id INTEGER PRIMARY KEY - идентификатор фильма
- title TEXT - название фильма
- year INTEGER - год выпуска (извлекается из title)
- genres TEXT - жанры через |

### Таблица ratings
- id INTEGER PRIMARY KEY AUTOINCREMENT - идентификатор записи
- user_id INTEGER - идентификатор пользователя
- movie_id INTEGER - идентификатор фильма
- rating REAL - оценка
- timestamp INTEGER - временная метка

### Таблица tags
- id INTEGER PRIMARY KEY AUTOINCREMENT - идентификатор записи
- user_id INTEGER - идентификатор пользователя
- movie_id INTEGER - идентификатор фильма
- tag TEXT - тег
- timestamp INTEGER - временная метка

### Таблица users
- id INTEGER PRIMARY KEY - идентификатор пользователя
- name TEXT - имя
- email TEXT - email
- gender TEXT - пол
- register_date TEXT - дата регистрации
- occupation TEXT - профессия

## Запуск

Linux / macOS / Git Bash на Windows:
    bash db_init.bat

Windows PowerShell (вручную):
    python make_db_init.py
    sqlite3 movies_rating.db ".read db_init.sql"

## Проверка результата

    sqlite3 movies_rating.db "SELECT COUNT(*) FROM movies;"
    sqlite3 movies_rating.db "SELECT COUNT(*) FROM ratings;"
    sqlite3 movies_rating.db "SELECT COUNT(*) FROM tags;"
    sqlite3 movies_rating.db "SELECT COUNT(*) FROM users;"

Ожидаемые результаты:
- movies: 9742
- ratings: 18773
- tags: 3683
- users: 943

## Автор
Крылов Р.Д.
