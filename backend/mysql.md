Here’s a **README.md** you can use for MySQL with Docker — including setup steps and basic SQL commands 👇

---

````markdown
# MySQL with Docker – Quick Guide

## 🚀 Running MySQL in Docker

Start a MySQL container with a root password:

```bash
docker run --name my-mysql \
  -e MYSQL_ROOT_PASSWORD=my-secret-pw \
  -p 3306:3306 \
  -d mysql:latest
````

* `--name my-mysql` → container name
* `-e MYSQL_ROOT_PASSWORD=my-secret-pw` → sets the root password
* `-p 3306:3306` → expose MySQL to your host machine
* `-d` → run in background

Check logs:

```bash
docker logs my-mysql
```

Connect inside container:

```bash
docker exec -it my-mysql mysql -u root -p
```

Stop and remove container:

```bash
docker stop my-mysql
docker rm my-mysql
```

---

## 🗄️ Basic MySQL Commands

### Database

```sql
SHOW DATABASES;             -- List all databases
CREATE DATABASE student_db; -- Create a database
DROP DATABASE student_db;   -- Delete a database
USE student_db;             -- Switch to a database
```

### Tables

```sql
SHOW TABLES;  -- List all tables
CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    age INT
);
DROP TABLE students;  -- Delete a table
```

### Data Operations (CRUD)

```sql
INSERT INTO students (name, age) VALUES ('Alice', 22); -- Insert data
SELECT * FROM students;                                -- Read data
UPDATE students SET age = 23 WHERE name = 'Alice';     -- Update data
DELETE FROM students WHERE name = 'Alice';             -- Delete data
```

### User Management

```sql
CREATE USER 'devuser'@'%' IDENTIFIED BY 'devpass';
GRANT ALL PRIVILEGES ON student_db.* TO 'devuser'@'%';
FLUSH PRIVILEGES;
```

---

## 🔧 Useful Docker + MySQL Commands

* List running containers:

```bash
docker ps
```

* Enter MySQL container shell:

```bash
docker exec -it my-mysql bash
```

* Remove all stopped containers:

```bash
docker container prune
```

* Remove unused images:

```bash
docker image prune -a
```

---

## 📌 Notes

* Always set a secure password in production.
* Use **named volumes** for persistent storage:

  ```bash
  docker run --name my-mysql \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -v mysql_data:/var/lib/mysql \
    -p 3306:3306 \
    -d mysql:latest
  ```

```

---

👉 Do you want me to also add **sample queries for student_db** (like inserting multiple students and running SELECT with filters) into this README for practice?
```
