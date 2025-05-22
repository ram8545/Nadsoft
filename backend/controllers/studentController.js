const db = require("../db");

exports.createStudent = (req, res) => {
  const { first_name, last_name, email, dob, gender } = req.body;
  const sql = `INSERT INTO students (first_name, last_name, email, dob, gender) VALUES (?, ?, ?, ?, ?)`;

  db.run(sql, [first_name, last_name, email, dob, gender], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.status(201).json({ id: this.lastID, ...req.body });
  });
};

exports.getAllStudents = (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const offset = (page - 1) * limit;

  const countQuery = "SELECT COUNT(*) AS total FROM Students";
  const dataQuery = `SELECT * FROM Students LIMIT ? OFFSET ?`;

  db.get(countQuery, [], (err, countResult) => {
    if (err) return res.status(500).json({ error: err });

    db.all(dataQuery, [limit, offset], (err, rows) => {
      if (err) return res.status(500).json({ error: err });

      res.json({
        metadata: {
          total: countResult.total,
          page: page,
          limit: limit,
          totalPages: Math.ceil(countResult.total / limit),
        },
        data: rows,
      });
    });
  });
};

exports.getStudentById = (req, res) => {
  const id = req.params.id;
  const studentQuery = `SELECT * FROM students WHERE id = ?`;
  const marksQuery = `
      SELECT m.subject_id, m.marks_obtained, s.subject_name
      FROM marks m
      JOIN subjects s ON s.subject_id = m.subject_id
      WHERE m.student_id = ?
    `;

  db.get(studentQuery, [id], (err, student) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!student) return res.status(404).json({ error: "Student not found" });

    db.all(marksQuery, [id], (err, marks) => {
      if (err) return res.status(500).json({ error: err.message });
      student.marks = marks;
      res.json(student);
    });
  });
};

exports.updateStudent = (req, res) => {
  const { first_name, last_name, email, dob, gender } = req.body;
  const id = req.params.id;

  const sql = `UPDATE students SET first_name=?, last_name=?, email=?, dob=?, gender=? WHERE id=?`;

  db.run(sql, [first_name, last_name, email, dob, gender, id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ updated: this.changes });
  });
};

exports.deleteStudent = (req, res) => {
  const id = req.params.id;
  db.run(`DELETE FROM students WHERE id=?`, [id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ deleted: this.changes });
  });
};
