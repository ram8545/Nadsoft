const mysql = require('mysql2');

// Create connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'mysql',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'student_db',
  connectionLimit: 10,
  queueLimit: 0
});

// Create wrapper object with SQLite-like methods
const db = {
  // SQLite's db.run equivalent - for INSERT, UPDATE, DELETE
  run: (sql, params, callback) => {
    pool.execute(sql, params, (err, results) => {
      if (err) return callback(err);

      // Create SQLite-like context object
      const context = {
        lastID: results.insertId,
        changes: results.affectedRows
      };

      callback.call(context, null);
    });
  },

  // SQLite's db.get equivalent - for single row SELECT
  get: (sql, params, callback) => {
    pool.execute(sql, params, (err, results) => {
      if (err) return callback(err);
      callback(null, results[0] || null);
    });
  },

  // SQLite's db.all equivalent - for multiple rows SELECT
  all: (sql, params, callback) => {
    pool.execute(sql, params, (err, results) => {
      if (err) return callback(err);
      callback(null, results);
    });
  }
};

// Initialize tables
const initializeDatabase = () => {
  const connection = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'student_db'
  });

  connection.connect((err) => {
    if (err) {
      console.error('Error connecting to MySQL:', err);
      return;
    }

    // Create students table
    connection.query(`
      CREATE TABLE IF NOT EXISTS students (
        id INT AUTO_INCREMENT PRIMARY KEY,
        first_name VARCHAR(255) NOT NULL,
        last_name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        dob DATE,
        gender ENUM('Male', 'Female', 'Other'),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `, (err) => {
      if (err) console.error('Error creating students table:', err);
      else console.log('Students table ready');
    });

    // Create subjects table
    connection.query(`
      CREATE TABLE IF NOT EXISTS subjects (
        subject_id INT AUTO_INCREMENT PRIMARY KEY,
        subject_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `, (err) => {
      if (err) console.error('Error creating subjects table:', err);
      else console.log('Subjects table ready');
    });

    // Create marks table
    connection.query(`
      CREATE TABLE IF NOT EXISTS marks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        student_id INT,
        subject_id INT,
        marks_obtained INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
      )
    `, (err) => {
      if (err) console.error('Error creating marks table:', err);
      else console.log('Marks table ready');
      connection.end();
    });
  });
};

// Initialize database on startup
initializeDatabase();

module.exports = db;