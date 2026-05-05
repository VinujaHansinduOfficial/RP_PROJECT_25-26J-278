from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, EmailStr
from datetime import datetime
import hashlib

router = APIRouter()


# ----------------------------
# Schemas
# ----------------------------

class RegisterRequest(BaseModel):
    username: str
    password: str
    gender: str
    mobileno: str
    mail: EmailStr
    dob: str


class LoginRequest(BaseModel):
    uname: EmailStr
    pwd: str


# ----------------------------
# SHA256 Hash Function
# ----------------------------

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()


# ----------------------------
# Registration
# ----------------------------

@router.post("/register")
def register_user(payload: RegisterRequest, request: Request):

    col = request.app.state.col_users

    if col.find_one({"email": payload.mail}):
        raise HTTPException(status_code=400, detail="User already exists")

    hashed_pwd = hash_password(payload.password)

    user_doc = {
        "username": payload.username,
        "email": payload.mail,
        "password": hashed_pwd,
        "gender": payload.gender,
        "mobileno": payload.mobileno,
        "dob": payload.dob,
        "created_at": datetime.utcnow()
    }

    inserted = col.insert_one(user_doc)
    user_doc["_id"] = str(inserted.inserted_id)

    del user_doc["password"]

    return {
        "message": "Registration successful",
        "user": user_doc
    }


# ----------------------------
# Login
# ----------------------------

@router.post("/login")
def login_user(payload: LoginRequest, request: Request):

    col = request.app.state.col_users

    hashed_pwd = hash_password(payload.pwd)

    user = col.find_one({
        "email": payload.uname,
        "password": hashed_pwd
    })

    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    user["_id"] = str(user["_id"])
    del user["password"]

    return {
        "message": "Login successful",
        "user": user
    }
