"""
Database configuration and session management for Luna backend.

This module provides SQLAlchemy async engine and session management for SQLite database.
Uses aiosqlite for async SQLite support with FastAPI.

CONFIGURATION:
    - Database: SQLite (luna.db)
    - Engine: SQLAlchemy async engine with aiosqlite
    - Session: Async session factory with context manager support

USAGE:
    async with get_db() as session:
        result = await session.execute(select(UserDB))
        users = result.scalars().all()

INITIALIZATION:
    - Database file created automatically on first run
    - Tables created via Base.metadata.create_all()
    - Connection pool configured for SQLite constraints
"""

from contextlib import asynccontextmanager
from typing import AsyncGenerator
import logging

from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
    AsyncEngine
)
from sqlalchemy.orm import declarative_base
from sqlalchemy.pool import StaticPool

# Configure logging
logger = logging.getLogger(__name__)

# Database URL for SQLite with aiosqlite driver
DATABASE_URL = "sqlite+aiosqlite:///./luna.db"

# Create declarative base for ORM models
Base = declarative_base()

# Global engine and session maker
_engine: AsyncEngine | None = None
_async_session_maker: async_sessionmaker[AsyncSession] | None = None


def get_engine() -> AsyncEngine:
    """
    Get or create the SQLAlchemy async engine.
    
    Returns:
        AsyncEngine configured for SQLite with aiosqlite
    """
    global _engine
    
    if _engine is None:
        _engine = create_async_engine(
            DATABASE_URL,
            echo=False,  # Set to True for SQL query logging
            connect_args={
                "check_same_thread": False,  # Allow multiple threads to use connection
            },
            poolclass=StaticPool,  # Use static pool for SQLite
        )
        logger.info(f"Database engine created: {DATABASE_URL}")
    
    return _engine


def get_session_maker() -> async_sessionmaker[AsyncSession]:
    """
    Get or create the async session maker.
    
    Returns:
        Async session maker for creating database sessions
    """
    global _async_session_maker
    
    if _async_session_maker is None:
        engine = get_engine()
        _async_session_maker = async_sessionmaker(
            engine,
            class_=AsyncSession,
            expire_on_commit=False,  # Don't expire objects after commit
            autocommit=False,
            autoflush=False,
        )
        logger.info("Session maker created")
    
    return _async_session_maker


@asynccontextmanager
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Async context manager for database sessions.
    
    Provides automatic session cleanup and error handling.
    Use with async with statement for proper resource management.
    
    Yields:
        AsyncSession for database operations
        
    Example:
        async with get_db() as session:
            result = await session.execute(select(UserDB))
            users = result.scalars().all()
            await session.commit()  # Explicit commit required
    """
    session_maker = get_session_maker()
    async with session_maker() as session:
        try:
            yield session
        except Exception as e:
            await session.rollback()
            logger.error(f"Database session error: {str(e)}", exc_info=True)
            raise
        finally:
            await session.close()


async def init_db() -> None:
    """
    Initialize database by creating all tables.
    
    Creates all tables defined in Base metadata.
    Safe to call multiple times - existing tables are not recreated.
    
    Raises:
        Exception: If database initialization fails
    """
    try:
        engine = get_engine()
        
        # Import all models to ensure they're registered with Base
        from models.db_models import (
            UserDB, VenueDB, InterestDB, UserInterestDB, 
            FriendshipDB, ActionItemDB, ActivityDB,
            ActionItemConfirmationDB, ChatDB, ChatParticipantDB, ChatMessageDB
        )
        
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")
        raise


async def close_db() -> None:
    """
    Close database connections and dispose of engine.
    
    Should be called during application shutdown.
    """
    global _engine, _async_session_maker
    
    if _engine:
        await _engine.dispose()
        _engine = None
        _async_session_maker = None
        logger.info("Database connections closed")
