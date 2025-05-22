import React, { useState, useEffect } from "react";
import "./StudentList.css";
import API from "../api";
import Modal from "./Modal";

const PAGE_SIZE = 10;

const StudentList = ({ onSelectStudent, refresh }) => {
  const [students, setStudents] = useState([]);
  const [metadata, setMetadata] = useState({ total: 0 });
  const [currentPage, setCurrentPage] = useState(1);

  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [studentToDelete, setStudentToDelete] = useState(null);

  const fetchStudents = async (page = 1) => {
    try {
      const res = await API.get(`/?page=${page}`);

      setStudents(res.data.data);
      setMetadata(res.data.metadata || { total: 0 });
      setCurrentPage(page);
    } catch (error) {
      console.error("Failed to fetch students:", error);
      setStudents([]);
      setMetadata({ total: 0 });
    }
  };

  useEffect(() => {
    fetchStudents(currentPage);
  }, [refresh]);

  const confirmDelete = (student) => {
    setStudentToDelete(student);
    setShowDeleteModal(true);
  };

  const deleteStudent = async () => {
    try {
      await API.delete(`/${studentToDelete.id}`);
      setShowDeleteModal(false);

      if (students.length === 1 && currentPage > 1) {
        fetchStudents(currentPage - 1);
      } else {
        fetchStudents(currentPage);
      }
    } catch (error) {
      console.error("Failed to delete student:", error);
      setShowDeleteModal(false);
    }
  };

  const totalPages = Math.ceil((metadata.total || 0) / PAGE_SIZE) || 1;

  const goToPage = (page) => {
    if (page < 1 || page > totalPages) return;
    fetchStudents(page);
  };

  return (
    <div className="student-list-container">
      <table className="student-table" border="1" cellPadding="5">
        <thead>
          <tr>
            <th>First</th>
            <th>Last</th>
            <th>Email</th>
            <th>DOB</th>
            <th>Gender</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {students.map((s) => (
            <tr key={s.id}>
              <td>{s.first_name}</td>
              <td>{s.last_name}</td>
              <td>{s.email}</td>
              <td>{s.dob}</td>
              <td>{s.gender}</td>
              <td>
                <button onClick={() => onSelectStudent(s)}>Edit</button>
                <button onClick={() => confirmDelete(s)}>Delete</button>
              </td>
            </tr>
          ))}
          {students.length === 0 && (
            <tr>
              <td colSpan="6" style={{ textAlign: "center" }}>
                No students found.
              </td>
            </tr>
          )}
        </tbody>
      </table>

      <div className="pagination">
        <button
          onClick={() => goToPage(currentPage - 1)}
          disabled={currentPage === 1}
        >
          Previous
        </button>

        <span>
          Page {currentPage} of {totalPages}
        </span>

        <button
          onClick={() => goToPage(currentPage + 1)}
          disabled={currentPage === totalPages}
        >
          Next
        </button>
      </div>

      <Modal isOpen={showDeleteModal} onClose={() => setShowDeleteModal(false)}>
        <div>
          <h3> Are you sure?</h3>
          <p>This action cannot be undone.</p>
          <button
            onClick={deleteStudent}
            style={{
              backgroundColor: "red",
              color: "white",
              marginRight: "10px",
            }}
          >
            Yes, delete it!
          </button>
          <button onClick={() => setShowDeleteModal(false)}>Cancel</button>
        </div>
      </Modal>
    </div>
  );
};

export default StudentList;
