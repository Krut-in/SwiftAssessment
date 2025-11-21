"""
Luna venue discovery backend API.

This is the main FastAPI application entry point.
Endpoints will be added in Phase 1B.
"""

from fastapi import FastAPI

# Initialize FastAPI app
app = FastAPI(
    title="Luna Venue Discovery API",
    description="Backend API for venue discovery and social interest tracking",
    version="1.0.0"
)


@app.get("/")
def root():
    """Health check endpoint."""
    return {
        "message": "Luna Venue Discovery API",
        "status": "running",
        "version": "1.0.0"
    }
