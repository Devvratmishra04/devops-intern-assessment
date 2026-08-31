"""
Sample Flask backend application used for CI/CD SAST rule validation and testing.
Contains both secure and vulnerable endpoints to evaluate SAST detection and false positive rates.
"""

from flask import Flask, request, jsonify, render_template_string
import sqlite3
import os

app = Flask(__name__)

# Sample DB config
DB_PATH = os.environ.get("DATABASE_PATH", "app.db")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, role TEXT)")
    cursor.execute("INSERT OR IGNORE INTO users (id, username, role) VALUES (1, 'admin', 'administrator')")
    conn.commit()
    conn.close()

@app.route("/health", methods=["GET"])
def health_check():
    """Safe health check endpoint."""
    return jsonify({"status": "healthy", "service": "flask-backend"}), 200

@app.route("/user/safe", methods=["GET"])
def get_user_safe():
    """
    SECURE PATTERN: Uses parameterized query preventing SQL Injection.
    """
    username = request.args.get("username", "")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT id, username, role FROM users WHERE username = ?", (username,))
    row = cursor.fetchone()
    conn.close()
    if row:
        return jsonify({"id": row[0], "username": row[1], "role": row[2]}), 200
    return jsonify({"error": "User not found"}), 404

# --- Test Case for SAST High/Critical Alert ---
@app.route("/user/vulnerable", methods=["GET"])
def get_user_vulnerable():
    """
    VULNERABLE PATTERN (HIGH/CRITICAL): Direct string formatting in SQL query.
    Expected SAST Alert: SQL Injection / Unsanitized input in raw query.
    """
    username = request.args.get("username", "")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    query = f"SELECT id, username, role FROM users WHERE username = '{username}'"
    cursor.execute(query)
    row = cursor.fetchone()
    conn.close()
    if row:
        return jsonify({"id": row[0], "username": row[1], "role": row[2]}), 200
    return jsonify({"error": "User not found"}), 404

@app.route("/render/vulnerable", methods=["GET"])
def render_template_vulnerable():
    """
    VULNERABLE PATTERN (HIGH): Server-Side Template Injection (SSTI).
    """
    name = request.args.get("name", "Guest")
    template = f"<h1>Welcome, {name}!</h1>"
    return render_template_string(template)

if __name__ == "__main__":
    init_db()
    # In production, debug must be False (SAST checks this)
    app.run(host="0.0.0.0", port=5000, debug=False)
