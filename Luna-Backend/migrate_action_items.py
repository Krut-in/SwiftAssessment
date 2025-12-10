#!/usr/bin/env python3
"""
Migration script for Luna Action Items feature.

This script:
1. Creates a backup of the existing luna.db
2. Adds new columns to action_items table (expires_at, archived_at)
3. Migrates existing action item IDs to UUID4 format
4. Updates status values from 'pending' to 'active'
5. Creates new tables (confirmations, chats, participants, messages)

USAGE:
    python migrate_action_items.py

ROLLBACK:
    The script creates a timestamped backup before making changes.
    To rollback, restore from the backup file.
"""

import sqlite3
import uuid
import shutil
from datetime import datetime, timedelta
from pathlib import Path


def backup_database(db_path: str) -> str:
    """Create a timestamped backup of the database."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{db_path}.backup_{timestamp}"
    shutil.copy2(db_path, backup_path)
    print(f"✅ Created backup: {backup_path}")
    return backup_path


def migrate_action_items(db_path: str):
    """
    Migrate the action_items table and create new tables.
    """
    # Backup first
    backup_database(db_path)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("\n📦 Starting migration...")
        
        # ============================================================
        # Step 1: Add new columns to action_items if they don't exist
        # ============================================================
        print("\n1️⃣ Adding new columns to action_items table...")
        
        # Check existing columns
        cursor.execute("PRAGMA table_info(action_items)")
        existing_columns = {row[1] for row in cursor.fetchall()}
        
        if 'expires_at' not in existing_columns:
            cursor.execute("ALTER TABLE action_items ADD COLUMN expires_at DATETIME")
            print("   ✅ Added expires_at column")
        else:
            print("   ⏭️ expires_at column already exists")
        
        if 'archived_at' not in existing_columns:
            cursor.execute("ALTER TABLE action_items ADD COLUMN archived_at DATETIME")
            print("   ✅ Added archived_at column")
        else:
            print("   ⏭️ archived_at column already exists")
        
        # ============================================================
        # Step 2: Migrate existing IDs to UUID4 format
        # ============================================================
        print("\n2️⃣ Migrating action item IDs to UUID4 format...")
        
        cursor.execute("SELECT id, created_at FROM action_items")
        old_items = cursor.fetchall()
        
        migrated_count = 0
        for old_id, created_at_str in old_items:
            # Skip if already UUID format
            if len(old_id) == 36 and old_id.count('-') == 4:
                continue
            
            new_id = str(uuid.uuid4())
            
            # Calculate expires_at (90 days from creation)
            try:
                if created_at_str:
                    created_at = datetime.fromisoformat(created_at_str.replace('Z', '+00:00'))
                else:
                    created_at = datetime.now()
            except:
                created_at = datetime.now()
            
            expires_at = created_at + timedelta(days=90)
            
            cursor.execute("""
                UPDATE action_items 
                SET id = ?, expires_at = ?
                WHERE id = ?
            """, (new_id, expires_at.isoformat(), old_id))
            migrated_count += 1
        
        print(f"   ✅ Migrated {migrated_count} action items to UUID4")
        
        # ============================================================
        # Step 3: Update status values from 'pending' to 'active'
        # ============================================================
        print("\n3️⃣ Updating status values...")
        
        cursor.execute("""
            UPDATE action_items 
            SET status = 'active' 
            WHERE status = 'pending'
        """)
        updated_count = cursor.rowcount
        print(f"   ✅ Updated {updated_count} items from 'pending' to 'active'")
        
        # Set expires_at for items that don't have it
        cursor.execute("""
            UPDATE action_items 
            SET expires_at = datetime(created_at, '+90 days')
            WHERE expires_at IS NULL
        """)
        
        # ============================================================
        # Step 4: Create new tables
        # ============================================================
        print("\n4️⃣ Creating new tables...")
        
        # Action Item Confirmations
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS action_item_confirmations (
                id VARCHAR(100) PRIMARY KEY,
                action_item_id VARCHAR(100) NOT NULL,
                user_id VARCHAR(100) NOT NULL,
                initiator_id VARCHAR(100) NOT NULL,
                status VARCHAR(20) DEFAULT 'pending',
                responded_at DATETIME,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (action_item_id) REFERENCES action_items(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (initiator_id) REFERENCES users(id) ON DELETE CASCADE
            )
        """)
        print("   ✅ Created action_item_confirmations table")
        
        # Chats
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS chats (
                id VARCHAR(100) PRIMARY KEY,
                action_item_id VARCHAR(100),
                venue_id VARCHAR(100) NOT NULL,
                created_by VARCHAR(100) NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (action_item_id) REFERENCES action_items(id) ON DELETE SET NULL,
                FOREIGN KEY (venue_id) REFERENCES venues(id) ON DELETE CASCADE,
                FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
            )
        """)
        print("   ✅ Created chats table")
        
        # Chat Participants
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS chat_participants (
                chat_id VARCHAR(100) NOT NULL,
                user_id VARCHAR(100) NOT NULL,
                joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (chat_id, user_id),
                FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
        """)
        print("   ✅ Created chat_participants table")
        
        # Chat Messages
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS chat_messages (
                id VARCHAR(100) PRIMARY KEY,
                chat_id VARCHAR(100) NOT NULL,
                sender_id VARCHAR(100) NOT NULL,
                content TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
                FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
            )
        """)
        print("   ✅ Created chat_messages table")
        
        # ============================================================
        # Step 5: Create indexes for new tables
        # ============================================================
        print("\n5️⃣ Creating indexes...")
        
        indexes = [
            ("idx_confirmation_action_item", "action_item_confirmations", "action_item_id"),
            ("idx_confirmation_user", "action_item_confirmations", "user_id"),
            ("idx_confirmation_status", "action_item_confirmations", "status"),
            ("idx_chat_action_item", "chats", "action_item_id"),
            ("idx_chat_venue", "chats", "venue_id"),
            ("idx_chat_created_by", "chats", "created_by"),
            ("idx_participant_chat", "chat_participants", "chat_id"),
            ("idx_participant_user", "chat_participants", "user_id"),
            ("idx_message_chat", "chat_messages", "chat_id"),
            ("idx_message_sender", "chat_messages", "sender_id"),
            ("idx_message_created", "chat_messages", "created_at"),
            ("idx_action_item_expires", "action_items", "expires_at"),
        ]
        
        for idx_name, table, column in indexes:
            try:
                cursor.execute(f"CREATE INDEX IF NOT EXISTS {idx_name} ON {table}({column})")
            except sqlite3.OperationalError:
                pass  # Index may already exist
        
        print(f"   ✅ Created {len(indexes)} indexes")
        
        # Commit all changes
        conn.commit()
        print("\n✅ Migration completed successfully!")
        
        # Print summary
        print("\n📊 Summary:")
        cursor.execute("SELECT COUNT(*) FROM action_items")
        print(f"   - Action items: {cursor.fetchone()[0]}")
        cursor.execute("SELECT COUNT(*) FROM action_item_confirmations")
        print(f"   - Confirmations: {cursor.fetchone()[0]}")
        cursor.execute("SELECT COUNT(*) FROM chats")
        print(f"   - Chats: {cursor.fetchone()[0]}")
        
    except Exception as e:
        conn.rollback()
        print(f"\n❌ Migration failed: {str(e)}")
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    import os
    
    # Find the database file
    db_path = Path(__file__).parent / "luna.db"
    
    if not db_path.exists():
        print(f"❌ Database not found: {db_path}")
        print("   Make sure you're running this from the Luna-Backend directory")
        exit(1)
    
    print(f"🗄️ Database: {db_path}")
    migrate_action_items(str(db_path))
