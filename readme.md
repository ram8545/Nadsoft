# Nadsoft Student Management System

A full-stack web application for managing student records with CRUD operations, built with React frontend, Node.js backend, and MySQL database.

## 🏗️ Architecture

- **Frontend**: React.js application served on port 3000
- **Backend**: Node.js/Express API server on port 3001
- **Database**: MySQL 8.0 on port 3306
- **Containerization**: Docker & Docker Compose

## 📋 Prerequisites

Before running this application, make sure you have installed:

- [Docker](https://www.docker.com/get-started) (version 20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0+)

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <your-repository-url>
cd nadsoft-student-management
```

### 2. Build Docker Images
```bash
# Build frontend image
docker build -t nadsoft-frontend ./frontend

# Build backend image
docker build -t nadsoft-backend ./backend
```

### 3. Start the Application
```bash
# Start all services
docker-compose up -d

# View logs (optional)
docker-compose logs -f
```

### 4. Access the Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001
- **Database**: localhost:3306

## 📁 Project Structure

```
nadsoft-student-management/
├── frontend/                 # React frontend application
│   ├── src/
│   ├── public/
│   ├── package.json
│   └── Dockerfile
├── backend/                  # Node.js backend API
│   ├── controllers/
│   ├── routes/
│   ├── db.js
│   ├── package.json
│   └── Dockerfile
├── docker-compose.yml        # Docker Compose configuration
├── .env                      # Environment variables
├── init.sql                  # Database initialization script
└── README.md
```

## ⚙️ Configuration

### Environment Variables

The application uses the following environment variables (defined in `.env`):

```env
# Database Configuration
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=student_db
MYSQL_USER=nadsoft_user
MYSQL_PASSWORD=nadsoft_password

# Backend Configuration
DB_HOST=mysql
DB_PORT=3306
DB_USER=nadsoft_user
DB_PASSWORD=nadsoft_password
DB_NAME=student_db
NODE_ENV=production

# Port Configuration
FRONTEND_PORT=3000
BACKEND_PORT=3001
MYSQL_PORT=3306
```

### Database Schema

The application creates the following tables:

#### Students Table
```sql
CREATE TABLE students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  dob DATE,
  gender ENUM('Male', 'Female', 'Other'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### Subjects Table
```sql
CREATE TABLE subjects (
  subject_id INT AUTO_INCREMENT PRIMARY KEY,
  subject_name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Marks Table
```sql
CREATE TABLE marks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT,
  subject_id INT,
  marks_obtained INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
);
```

## 🔧 Docker Commands

### Basic Operations
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f backend

# Restart a specific service
docker-compose restart backend

# Check service status
docker-compose ps
```

### Development Commands
```bash
# Rebuild images and start
docker-compose up --build -d

# Start services without detached mode (see logs in terminal)
docker-compose up

# Scale a service (if needed)
docker-compose up -d --scale backend=2
```

### Data Management
```bash
# Stop and remove all data (including database)
docker-compose down -v

# Backup database
docker exec nadsoft-mysql mysqldump -u nadsoft_user -p nadsoft_password student_db > backup.sql

# Restore database
docker exec -i nadsoft-mysql mysql -u nadsoft_user -p nadsoft_password student_db < backup.sql
```

## 🌐 API Endpoints

### Students
- `GET /api/students` - Get all students (with pagination)
- `GET /api/students/:id` - Get student by ID (with marks)
- `POST /api/students` - Create new student
- `PUT /api/students/:id` - Update student
- `DELETE /api/students/:id` - Delete student

### Query Parameters for GET /api/students
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 10)

### Request Body Example (POST/PUT)
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "dob": "2000-01-15",
  "gender": "Male"
}
```

## 🔍 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Check what's using the port
   lsof -i :3000
   lsof -i :3001
   lsof -i :3306

   # Kill the process or change ports in docker-compose.yml
   ```

2. **Database connection failed**
   ```bash
   # Check MySQL container logs
   docker-compose logs mysql

   # Restart MySQL service
   docker-compose restart mysql
   ```

3. **Backend can't connect to database**
   ```bash
   # Check if services are on the same network
   docker network ls
   docker network inspect nadsoft-student-management_nadsoft-network
   ```

4. **Frontend can't reach backend**
   - Ensure backend URL in frontend code points to `http://localhost:3001`
   - Check if backend service is running: `docker-compose ps`

### Debugging Commands
```bash
# Enter MySQL container
docker exec -it nadsoft-mysql mysql -u nadsoft_user -p

# Enter backend container
docker exec -it nadsoft-backend sh

# Enter frontend container
docker exec -it nadsoft-frontend sh

# Check container resource usage
docker stats
```

## 🧪 Testing

### Manual Testing
1. Access frontend at http://localhost:3000
2. Test CRUD operations through the UI
3. Verify API endpoints using tools like Postman or curl

### API Testing with curl
```bash
# Get all students
curl http://localhost:3001/api/students

# Create a student
curl -X POST http://localhost:3001/api/students \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Jane","last_name":"Smith","email":"jane@example.com","dob":"1999-05-20","gender":"Female"}'

# Get student by ID
curl http://localhost:3001/api/students/1
```

## 📊 Monitoring

### Health Checks
The MySQL service includes health checks. You can monitor service health:
```bash
# Check service health
docker-compose ps

# View health check logs
docker inspect nadsoft-mysql | grep -A 10 Health
```

### Logs
```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f --tail=50

# Logs for specific service
docker-compose logs -f backend
```

## 🔄 Updates and Maintenance

### Updating the Application
1. Pull latest changes from repository
2. Rebuild images:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

### Database Migrations
For schema changes, update the `init.sql` file and:
1. Backup existing data
2. Update the database schema
3. Restart the services

### Cleaning Up
```bash
# Remove unused images and containers
docker system prune -a

# Remove only this project's resources
docker-compose down -v --rmi all
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

