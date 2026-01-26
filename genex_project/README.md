# Genex Project - Backend (Django)

## Project Overview
Genex is a medical AI platform designed to predict autoimmune diseases and simulate patient-specific digital twins for drug interactions. It allows doctors to analyze patient gene expression data and make informed therapeutic decisions. The backend is built using Django 5.2, Django REST Framework, and SQLite for development purposes. JWT authentication is implemented using Simple JWT.

## Features
- Predict autoimmune diseases based on gene expression.  
- View patient digital twins and simulate drug-gene/drug-drug interactions.  
- Supports different user roles: Patient, Doctor, Admin.  
- REST API for seamless frontend integration.  

## Tech Stack
- **Backend:** Django, Django REST Framework, Simple JWT  
- **Database:** SQLite (development)  
- **Frontend:** Flutter (separate repo)  
- **State Management:** Riverpod (Flutter)  
- **API Requests:** Dio (Flutter)  

## Setup Instructions

### 1. Clone the repository
git clone <https://github.com/MayaElmosalamy/genex_project.git>
cd genex_Backend

### 2. Create a virtual environment
python -m venv venv
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

### 3. Install dependencies
pip install -r requirements.txt

### 4. Apply migrations
python manage.py makemigrations
python manage.py migrate

This will create all necessary database tables, including api_user.

### 5. Create a superuser (optional)
python manage.py createsuperuser
Follow prompts to set username, email, and password for admin access.

### 6. Run the development server
python manage.py runserver 127.0.0.1:8000

The API will be available at http://127.0.0.1:8000/api/. You can now log in with users created via the admin panel or API.


## Important Notes

- **Database:** Each team member should run migrations locally. Do not commit `db.sqlite3`.  
- **Migrations:** When adding new models, run `makemigrations` and `migrate` to update the database.  
- **Admin Access:** Use the superuser account to create doctors and manage users.  
- **JWT Authentication:** Tokens are generated for API login and signup.  

## GitHub Best Practices

- `.gitignore` includes `venv/`, `__pycache__/`, and `db.sqlite3`.  
- License: MIT.  

## API Endpoints (Examples)

- `POST /api/signup/` – Signup a new user  
- `POST /api/signin/` – Login and receive JWT token  

_For full API documentation, refer to the `api/views.py` file._

## Contributing

1. Fork the repository  
2. Create a new branch (`git checkout -b feature-name`)  
3. Make changes  
4. Push to your branch  
5. Open a pull request
