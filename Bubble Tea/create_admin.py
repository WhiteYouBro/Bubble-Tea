"""
Script to create admin user
Run: python create_admin.py
"""

import psycopg2
import os
from werkzeug.security import generate_password_hash
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection from .env
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'your_password')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'bibabobabebe')

def create_admin():
    """Create admin user in database"""
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT
    )
    cur = conn.cursor()
    
    # Admin credentials
    username = 'admin'
    email = 'admin@bibabobabebe.com'
    password = 'admin123'
    full_name = 'Administrator'
    password_hash = generate_password_hash(password)
    
    try:
        # Check if admin exists
        cur.execute("SELECT user_id FROM users WHERE username = %s", (username,))
        if cur.fetchone():
            print(f"[!] User '{username}' already exists!")
        else:
            # Insert admin
            cur.execute("""
                INSERT INTO users (username, email, password_hash, full_name, role, is_active)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (username, email, password_hash, full_name, 'admin', True))
            
            conn.commit()
            print("[OK] Admin user created successfully!")
            print(f"  Username: {username}")
            print(f"  Password: {password}")
            print(f"  Email: {email}")
    except Exception as e:
        print(f"[ERROR] Error: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    create_admin()

