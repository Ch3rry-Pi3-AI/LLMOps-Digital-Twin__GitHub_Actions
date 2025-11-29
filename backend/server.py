"""
AI Digital Twin Backend API (AWS Bedrock Version)

This module implements the FastAPI backend for the llmops-digital-twin project.
It enables:

1. Health checks
2. Basic service metadata
3. Chat interactions using AWS Bedrock models
4. Persistent conversation memory (local or S3)

Key Features
------------
- Bedrock runtime integration using boto3
- CORS support for the frontend
- Session-based conversation history
- Pluggable memory storage (local JSON or S3)
- System prompt injection from `context.prompt()`

Each conversation session is tracked by a session_id and stored as structured JSON.
"""

# ============================================================
# Imports
# ============================================================

# FastAPI core
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

# Pydantic models
from pydantic import BaseModel

# Environment management
from dotenv import load_dotenv
import os

# Typing + utilities
from typing import Optional, List, Dict
import json
import uuid
from datetime import datetime

# AWS / Bedrock
import boto3
from botocore.exceptions import ClientError

# System prompt
from context import prompt


# ============================================================
# Environment Variables
# ============================================================

# Load .env variables
load_dotenv()


# ============================================================
# FastAPI Application
# ============================================================

# Create app instance
app = FastAPI()


# ============================================================
# CORS Configuration
# ============================================================

# Allowed origins (defaults to local Next.js dev)
origins = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")

# Enable CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


# ============================================================
# AWS Bedrock Client
# ============================================================

# Initialise Bedrock runtime client
bedrock_client = boto3.client(
    service_name="bedrock-runtime",
    region_name=os.getenv("DEFAULT_AWS_REGION", "us-east-1")
)

# Select Bedrock model
BEDROCK_MODEL_ID = os.getenv("BEDROCK_MODEL_ID", "amazon.nova-lite-v1:0")


# ============================================================
# Memory Storage Configuration
# ============================================================

# Toggle local vs S3 storage
USE_S3 = os.getenv("USE_S3", "false").lower() == "true"

# S3 bucket name
S3_BUCKET = os.getenv("S3_BUCKET", "")

# Local directory path
MEMORY_DIR = os.getenv("MEMORY_DIR", "../memory")

# Create S3 client only if needed
if USE_S3:
    s3_client = boto3.client("s3")


# ============================================================
# Request and Response Models
# ============================================================

class ChatRequest(BaseModel):
    """Request payload for chat interactions with the backend."""
    message: str
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    """Response payload containing the AI output and session ID."""
    response: str
    session_id: str


class Message(BaseModel):
    """Internal model representing a single message in the conversation."""
    role: str
    content: str
    timestamp: str


# ============================================================
# Memory Management
# ============================================================

def get_memory_path(session_id: str) -> str:
    """Return the storage filename/key for a given session."""
    return f"{session_id}.json"


def load_conversation(session_id: str) -> List[Dict]:
    """
    Load the conversation history for a given session.

    Returns a list of message dictionaries, or an empty list
    if no previous conversation exists.
    """
    if USE_S3:
        try:
            # Load from S3
            response = s3_client.get_object(
                Bucket=S3_BUCKET,
                Key=get_memory_path(session_id)
            )
            return json.loads(response["Body"].read().decode("utf-8"))

        except ClientError as e:
            if e.response["Error"]["Code"] == "NoSuchKey":
                return []
            raise

    # Load from local disk
    file_path = os.path.join(MEMORY_DIR, get_memory_path(session_id))
    if os.path.exists(file_path):
        with open(file_path, "r") as f:
            return json.load(f)

    return []


def save_conversation(session_id: str, messages: List[Dict]):
    """
    Save the conversation history for a given session.

    Writes to either S3 or local filesystem depending on USE_S3.
    """
    if USE_S3:
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=get_memory_path(session_id),
            Body=json.dumps(messages, indent=2),
            ContentType="application/json"
        )
    else:
        os.makedirs(MEMORY_DIR, exist_ok=True)
        file_path = os.path.join(MEMORY_DIR, get_memory_path(session_id))
        with open(file_path, "w") as f:
            json.dump(messages, f, indent=2)


# ============================================================
# Bedrock Call Function
# ============================================================

def call_bedrock(conversation: List[Dict], user_message: str) -> str:
    """
    Send conversation history + current message to AWS Bedrock.

    Bedrock requires messages formatted as:
    [
        {"role": "...", "content": [{"text": "..."}]},
        ...
    ]

    Returns the assistant's text response.
    """

    # Build messages list
    messages = []

    # Add system prompt (as user-role per Bedrock convention)
    messages.append({
        "role": "user",
        "content": [{"text": f"System: {prompt()}"}]
    })

    # Add last 20 messages from history
    for msg in conversation[-20:]:
        messages.append({
            "role": msg["role"],
            "content": [{"text": msg["content"]}]
        })

    # Add current user message
    messages.append({
        "role": "user",
        "content": [{"text": user_message}]
    })

    try:
        # Call Bedrock
        response = bedrock_client.converse(
            modelId=BEDROCK_MODEL_ID,
            messages=messages,
            inferenceConfig={
                "maxTokens": 2000,
                "temperature": 0.7,
                "topP": 0.9
            }
        )

        # Extract response text
        return response["output"]["message"]["content"][0]["text"]

    except ClientError as e:
        code = e.response["Error"]["Code"]

        if code == "ValidationException":
            raise HTTPException(400, "Invalid message format for Bedrock")

        if code == "AccessDeniedException":
            raise HTTPException(403, "Access denied to Bedrock model")

        raise HTTPException(500, f"Bedrock error: {str(e)}")


# ============================================================
# API Routes
# ============================================================

@app.get("/")
async def root():
    """Basic status endpoint for initial service verification."""
    return {
        "message": "AI Digital Twin API (Powered by AWS Bedrock)",
        "memory_enabled": True,
        "storage": "S3" if USE_S3 else "local",
        "ai_model": BEDROCK_MODEL_ID
    }


@app.get("/health")
async def health_check():
    """Health endpoint for monitoring."""
    return {"status": "healthy", "use_s3": USE_S3, "bedrock_model": BEDROCK_MODEL_ID}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Main chat endpoint for interacting with the Digital Twin.

    Steps:
    1. Create or reuse session_id
    2. Load conversation history
    3. Call AWS Bedrock with context
    4. Append new messages
    5. Save updated memory
    """
    try:
        session_id = request.session_id or str(uuid.uuid4())

        # Load history
        conversation = load_conversation(session_id)

        # Query Bedrock
        assistant_response = call_bedrock(conversation, request.message)

        # Append user message
        conversation.append({
            "role": "user",
            "content": request.message,
            "timestamp": datetime.now().isoformat(),
        })

        # Append assistant message
        conversation.append({
            "role": "assistant",
            "content": assistant_response,
            "timestamp": datetime.now().isoformat(),
        })

        # Save
        save_conversation(session_id, conversation)

        return ChatResponse(response=assistant_response, session_id=session_id)

    except HTTPException:
        raise

    except Exception as e:
        print(f"Chat endpoint error: {str(e)}")
        raise HTTPException(500, str(e))


@app.get("/conversation/{session_id}")
async def get_conversation(session_id: str):
    """Retrieve the full conversation history for a given session."""
    try:
        history = load_conversation(session_id)
        return {"session_id": session_id, "messages": history}
    except Exception as e:
        raise HTTPException(500, str(e))


# ============================================================
# Local Development Server
# ============================================================

if __name__ == "__main__":
    import uvicorn

    # Run development server
    uvicorn.run(app, host="0.0.0.0", port=8000)
