# GeneX Project - Backend (Django)

## Project Overview
GeneX is a medical AI platform designed to predict autoimmune diseases and simulate patient-specific digital twins for drug interactions. It allows healthcare providers to analyze patient gene expression data while providing patients with tools to track their health journey. 

The backend is built using **Django 5.2** and **Django REST Framework (DRF)**, utilizing **JWT** for secure, stateless authentication.

## Features
* **Authentication & Roles:** Secure signup and signin with support for Patient, Doctor, and Admin roles.
* **Medicine Tracking:** CRUD operations for patients to maintain a digital history of their medications.
* **Symptom Reporting:** Log symptoms with severity scales (0-10), frequency tracking, and descriptive notes.
* **Profile Management:** View and update patient biometrics including height, weight, and age.
* **AI Digital Twin (Core):** Predict autoimmune diseases and simulate drug-gene interactions based on expression data.

## Tech Stack
* **Backend:** Django, Django REST Framework
* **Auth:** Simple JWT (JSON Web Tokens)
* **Database:** SQLite (Development) / PostgreSQL (Production)
* **Frontend Integration:** Flutter with Riverpod (State Management) and Dio (HTTP Client)

---

## Setup Instructions

### 1. Clone the repository
```bash
git clone [https://github.com/Hatemmhossam/GeneX.git]
cd genex_Backend
```

### 2. Create a virtual environment
```bash

python -m venv venv
```

# Windows
```bash
venv\Scripts\activate
```

# macOS/Linux
```bash
source venv/bin/activate
```
### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Apply migrations
```bash

python manage.py makemigrations
python manage.py migrate
```
This will create all necessary database tables, including users, medicines, and symptoms.

### 5. Create a superuser (Optional)
```bash

python manage.py createsuperuser
```
### 6. Run the development server
```bash

python manage.py runserver 127.0.0.1:8000
```
The API will be available at http://127.0.0.1:8000/api/.


## API Endpoints

### Authentication

| Endpoint     | Method | Description                         | Auth Required |
|--------------|--------|-------------------------------------|---------------|
| /api/signup/ | POST   | Signup a new user and receive token | No            |
| /api/signin/ | POST   | Login and receive JWT token         | No            |

### Patient Data

| Endpoint           | Method    | Description                                | Auth Required |
| :----------------- | :-------- | :----------------------------------------- | :------------ |
| /api/profile/      | GET/PATCH | View or update authenticated user profile  | Yes           |
| /api/medicines/    | GET/POST  | List patient medicines or add a new one    | Yes           |
| /api/medicines/<id>/| DELETE    | Remove a medicine from history             | Yes           |
| /api/symptoms/     | GET/POST  | List or report new symptom logs            | Yes           |

## Important Notes
- Database: Each team member should run migrations locally. Do not commit db.sqlite3.
- JWT Authentication: Tokens must be included in the header of protected requests:
  Authorization: Bearer <your_token>
- Mobile Integration: If testing on a physical device, ensure the Flutter app 
  points to your computer's Local IP address instead of 127.0.0.1.
- Symptom Scale: Severity is stored as an integer from 0 to 10.


## GitHub Best Practices
- .gitignore includes venv/, __pycache__/, and db.sqlite3.
- License: MIT.

## Conributing
1. Fork the repository
2. Create a new branch (git checkout -b feature-name)
3. Make changes and commit
4. Push to your branch
5. Open a pull request

