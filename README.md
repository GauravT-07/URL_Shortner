# URL Shortener

A lightweight URL shortener that was first built as a monolithic full-stack application and later adapted into a cloud-based microservices-style deployment. The project includes a React frontend, a FastAPI backend, and AWS-friendly serverless logic using API Gateway, Lambda, and DynamoDB. It can run locally for development and can also be deployed on EC2 or in a cloud-native architecture with Netlify and AWS services.

## Live Demo

- Frontend: https://urlshortner26.netlify.app/
- Custom domain used for backend requests: https://gauravtotla.in

## Overview

This project lets users:

- shorten long URLs into compact short links
- redirect short links back to the original destination
- view stored URLs
- delete old or unused links
- deploy the frontend and backend in different environments

The repository contains two major approaches:

1. Monolithic app setup
   - React frontend + FastAPI backend + SQLite database
   - Suitable for local development and single-server deployment

2. Microservices / serverless architecture
   - Frontend hosted on Netlify
   - API exposed through AWS API Gateway
   - Backend logic handled by AWS Lambda
   - Data stored in DynamoDB

This makes it a good example of evolving a traditional monolith into smaller, independently deployable services.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Frontend | React, Vite, JavaScript |
| Backend (local) | FastAPI, Pydantic, SQLAlchemy |
| Local database | SQLite |
| Cloud API layer | AWS API Gateway |
| Serverless compute | AWS Lambda |
| Cloud database | Amazon DynamoDB |
| Frontend hosting | Netlify |
| Node tooling | npm |
| Server deployment | EC2 + Nginx + systemd |

## Project Structure

```text
.
├── URL_backend/
│   ├── main.py
│   ├── requirements.txt
│   └── urls.db
├── URL_frontend/
│   ├── src/
│   ├── public/
│   ├── package.json
│   ├── vite.config.js
│   └── README.md
├── aws_setup/
│   ├── Lambda_function.py
│   ├── backend_setup.sh
│   ├── deploy_frontend.sh
│   ├── ec2_setup.sh
│   └── frontend_setup.sh
├── requirements.txt
├── README.md
└── .gitignore
```

## Architecture

### 1. Monolithic version

```text
Browser
  │
  ├── React frontend
  │
  └── FastAPI backend
        │
        └── SQLite database
```

This version is implemented in [URL_backend/main.py](URL_backend/main.py). It exposes endpoints like:

- POST /shorten
- GET /all
- GET /{short_code}
- DELETE /delete/{short_code}

The app stores URL mappings directly in SQLite and redirects users to the original URL when a short code is visited.

### 2. AWS microservices-style version

```text
Browser / Netlify Frontend
        │
        ▼
AWS API Gateway
        │
        ▼
AWS Lambda
        │
        ▼
DynamoDB (urls table)
```

The serverless backend logic is implemented in [aws_setup/Lambda_function.py](aws_setup/Lambda_function.py). It includes:

- POST /shorten
- GET /all
- GET /{short_code}
- DELETE /delete/{short_code}

The Lambda function uses DynamoDB to store original URL and short code pairs, while API Gateway exposes the REST endpoints for the frontend.

This is the microservices-style evolution of the original monolith:

- frontend separated from backend
- API exposed via gateway instead of direct Python server calls
- database moved from SQLite to a managed cloud database
- backend logic moved into Lambda functions
- frontend deployed via Netlify as a static app

## Cost-Effective Architecture Highlights

This project was designed with cost efficiency in mind, especially for a learning and small-scale production setup:

- AWS Lambda is used instead of always-on EC2 compute for request handling.
- DynamoDB is a low-cost NoSQL option for storing short-link mappings instead of maintaining a heavy relational database.
- API Gateway adds managed API exposure without needing a dedicated backend server for each route.
- Netlify is used for the frontend so static content can be hosted cheaply and scaled automatically.
- The custom domain https://gauravtotla.in is used as the public-facing API domain, helping keep the short links clean and readable while routing backend requests through AWS-managed services.
- The app can still run on a single EC2 instance for monolithic deployment when a lower-cloud-complexity setup is preferred.

This gives a practical balance between feature availability, deployment simplicity, and lower monthly infrastructure cost.

## Features

- Generate six-character short URLs
- Prevent duplicate long URLs from creating duplicate entries
- Redirect short links to their original destination
- List saved short URLs
- Search and filter URL records in the UI
- Delete stored entries
- Works in local development and production environments
- Supports both monolith and cloud deployments
- Built with a cost-conscious cloud architecture

## Local Development

### Prerequisites

- Python 3.10+
- Node.js 18+
- npm

### 1. Start the backend

```bash
cd URL_backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The FastAPI app runs at:

- http://127.0.0.1:8000
- Swagger docs: http://127.0.0.1:8000/docs

### 2. Start the frontend

```bash
cd URL_frontend
npm install
npm run dev
```

The React app usually runs at:

- http://localhost:5173

### 3. Example API usage

Create a short URL:

```bash
curl -X POST http://127.0.0.1:8000/shorten \
  -H "Content-Type: application/json" \
  -d '{"original_url":"https://www.example.com/long-path"}'
```

List all URLs:

```bash
curl http://127.0.0.1:8000/all
```

Follow redirect:

```bash
curl -I http://127.0.0.1:8000/ABC123
```

Delete URL:

```bash
curl -X DELETE http://127.0.0.1:8000/delete/ABC123
```

## AWS Deployment Flow

### API Gateway + Lambda + DynamoDB

The AWS serverless design is represented by [aws_setup/Lambda_function.py](aws_setup/Lambda_function.py). The flow is:

1. Frontend sends requests to the API Gateway endpoint
2. API Gateway forwards the request to a Lambda function
3. Lambda validates the payload and talks to DynamoDB
4. DynamoDB stores and fetches URL data
5. Redirect requests return 302 to the original URL

### DynamoDB table design

The Lambda implementation expects a DynamoDB table named `urls` with `short_code` as the key.

Example item:

```json
{
  "short_code": "ABC123",
  "original_url": "https://www.example.com/some-long-link"
}
```

### API Gateway configuration

The API should expose endpoints like:

- POST /shorten
- GET /all
- GET /{short_code}
- DELETE /delete/{short_code}

These routes can be mapped to the Lambda function in API Gateway and then connected to the frontend domain.

The deployed setup uses the custom domain https://gauravtotla.in as the public-facing endpoint for backend traffic, while the frontend is served from https://urlshortner112.netlify.app.

This means the frontend requests are proxied through a domain-friendly API layer instead of exposing raw AWS API Gateway URLs directly to users.

## Netlify Deployment

The frontend is designed to be deployed to Netlify, allowing it to work as a separate static application. The app calls an API base URL, which is configured through environment variables.

Example:

```bash
VITE_API_URL=https://your-api-gateway-url.amazonaws.com
```

This lets the frontend remain decoupled from the backend and makes it easy to serve the UI independently from the API.

## EC2 and Nginx Deployment

The repo also includes shell scripts for running the app on an Ubuntu EC2 instance with Nginx.

Files in [aws_setup](aws_setup):

- [aws_setup/ec2_setup.sh](aws_setup/ec2_setup.sh) — prepares the instance and clones the repository
- [aws_setup/backend_setup.sh](aws_setup/backend_setup.sh) — creates the Python environment and runs FastAPI as a systemd service
- [aws_setup/frontend_setup.sh](aws_setup/frontend_setup.sh) — installs Nginx, builds the React app, and serves it on port 80
- [aws_setup/deploy_frontend.sh](aws_setup/deploy_frontend.sh) — rebuilds and deploys the frontend

This is a traditional deployment option when the monolithic version is needed without serverless components.

## Why this is a monolith-to-microservices example

This project demonstrates the common transition from a single application to a distributed cloud architecture:

- Started as one full-stack app with frontend, API, and database in one codebase
- Later split into separate concerns:
  - frontend on Netlify
  - API on API Gateway / Lambda
  - database on DynamoDB
- The codebase keeps both approaches so the project can be used for learning, testing, and deployment experimentation

## Important Notes

- The local monolithic version uses SQLite, which is great for development but not ideal for large-scale production traffic.
- The Lambda version is designed for a cloud-native setup and uses DynamoDB for persistence.
- API security, rate limiting, validation, and HTTPS should be handled in production.
- For public deployment, use a proper custom domain and set the short URL base to the deployed API domain.

