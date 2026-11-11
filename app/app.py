"""Petite API Flask servant de cible au lab DevSecOps.

Cette version est la version saine. Les failles de démonstration sont injectées
à la demande par scripts/demo.sh (voir docs/etapes/08-quality-gates.md).
"""
import os
import sqlite3

from flask import Flask, jsonify, request

DB_PATH = os.environ.get("DB_PATH", "/tmp/lab.db")


def get_db():
    con = sqlite3.connect(DB_PATH)
    con.row_factory = sqlite3.Row
    return con


def init_db():
    con = get_db()
    con.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT UNIQUE, role TEXT)")
    con.executemany(
        "INSERT OR IGNORE INTO users (name, role) VALUES (?, ?)",
        [("alice", "admin"), ("bob", "reader")],
    )
    con.commit()
    con.close()


def create_app():
    app = Flask(__name__)
    # Le jeton vient de l'environnement : jamais de secret dans le code.
    app.config["API_TOKEN"] = os.environ.get("API_TOKEN", "")
    init_db()

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    @app.get("/users")
    def users():
        name = request.args.get("name", "")
        con = get_db()
        # Requête paramétrée : l'entrée utilisateur n'est jamais concaténée au SQL.
        rows = con.execute("SELECT id, name, role FROM users WHERE name = ?", (name,)).fetchall()
        con.close()
        return jsonify(result=[dict(r) for r in rows])

    return app


app = create_app()
