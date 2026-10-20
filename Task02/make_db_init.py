#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import csv
import re
import os
import sys

# ---------- Настройки ----------
OUTPUT_SQL = "db_init.sql"
BATCH_SIZE = 500  # сколько строк в одном INSERT

# ---------- Утилиты ----------
def sql_escape(value: str) -> str:
    """Экранирование строки для SQL (одинарные кавычки)."""
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"

def extract_year(title: str):
    """Извлекает год из строки вида 'Toy Story (1995)'."""
    m = re.search(r'\((\d{4})\)\s*$', title)
    return int(m.group(1)) if m else None

# ---------- Генерация SQL ----------
def generate_sql():
    sql = []
    sql.append("-- Автоматически сгенерированный скрипт инициализации БД movies_rating.db")
    sql.append("PRAGMA foreign_keys = OFF;")
    sql.append("BEGIN TRANSACTION;")
    sql.append("")

    # ---------- DROP TABLE ----------
    sql.append("-- Удаление существующих таблиц")
    sql.append("DROP TABLE IF EXISTS tags;")
    sql.append("DROP TABLE IF EXISTS ratings;")
    sql.append("DROP TABLE IF EXISTS movies;")
    sql.append("DROP TABLE IF EXISTS users;")
    sql.append("")

    # ---------- CREATE TABLE ----------
    sql.append("-- Создание таблиц")
    sql.append("""
CREATE TABLE movies (
    id      INTEGER PRIMARY KEY,
    title   TEXT    NOT NULL,
    year    INTEGER,
    genres  TEXT
);
""".strip())
    sql.append("""
CREATE TABLE ratings (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id   INTEGER NOT NULL,
    movie_id  INTEGER NOT NULL,
    rating    REAL    NOT NULL,
    timestamp INTEGER NOT NULL
);
""".strip())
    sql.append("""
CREATE TABLE tags (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id   INTEGER NOT NULL,
    movie_id  INTEGER NOT NULL,
    tag       TEXT    NOT NULL,
    timestamp INTEGER NOT NULL
);
""".strip())
    sql.append("""
CREATE TABLE users (
    id            INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL,
    email         TEXT,
    gender        TEXT,
    register_date TEXT,
    occupation    TEXT
);
""".strip())
    sql.append("")

    # ---------- INSERT movies ----------
    sql.append("-- Загрузка данных в movies")
    with open("movies.csv", "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = []
        for row in reader:
            movie_id = int(row["movieId"])
            title = row["title"]
            year = extract_year(title)
            genres = row["genres"]
            rows.append(f"({movie_id},{sql_escape(title)},{year if year is not None else 'NULL'},{sql_escape(genres)})")
        for i in range(0, len(rows), BATCH_SIZE):
            batch = rows[i:i+BATCH_SIZE]
            sql.append("INSERT INTO movies (id, title, year, genres) VALUES\n" + ",\n".join(batch) + ";")
    sql.append("")

    # ---------- INSERT ratings ----------
    sql.append("-- Загрузка данных в ratings")
    with open("ratings.csv", "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = []
        for row in reader:
            user_id = int(row["userId"])
            movie_id = int(row["movieId"])
            rating = float(row["rating"])
            timestamp = int(row["timestamp"])
            rows.append(f"({user_id},{movie_id},{rating},{timestamp})")
        for i in range(0, len(rows), BATCH_SIZE):
            batch = rows[i:i+BATCH_SIZE]
            sql.append("INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES\n" + ",\n".join(batch) + ";")
    sql.append("")

    # ---------- INSERT tags ----------
    sql.append("-- Загрузка данных в tags")
    with open("tags.csv", "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = []
        for row in reader:
            user_id = int(row["userId"])
            movie_id = int(row["movieId"])
            tag = row["tag"]
            timestamp = int(row["timestamp"])
            rows.append(f"({user_id},{movie_id},{sql_escape(tag)},{timestamp})")
        for i in range(0, len(rows), BATCH_SIZE):
            batch = rows[i:i+BATCH_SIZE]
            sql.append("INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES\n" + ",\n".join(batch) + ";")
    sql.append("")

    # ---------- INSERT users ----------
    sql.append("-- Загрузка данных в users")
    with open("users.txt", "r", encoding="utf-8", newline="") as f:
        rows = []
        for line in f:
            line = line.rstrip("\n").rstrip("\r")
            if not line:
                continue
            parts = line.split("|")
            if len(parts) < 6:
                continue
            user_id = int(parts[0])
            name = parts[1]
            email = parts[2]
            gender = parts[3]
            register_date = parts[4]
            occupation = parts[5]
            rows.append(f"({user_id},{sql_escape(name)},{sql_escape(email)},{sql_escape(gender)},{sql_escape(register_date)},{sql_escape(occupation)})")
        for i in range(0, len(rows), BATCH_SIZE):
            batch = rows[i:i+BATCH_SIZE]
            sql.append("INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES\n" + ",\n".join(batch) + ";")
    sql.append("")

    sql.append("COMMIT;")
    sql.append("PRAGMA foreign_keys = ON;")

    with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
        f.write("\n".join(sql))

    print(f"SQL-скрипт {OUTPUT_SQL} успешно создан.")

if __name__ == "__main__":
    generate_sql()