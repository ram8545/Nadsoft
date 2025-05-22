import React, { useState } from "react";
import StudentForm from "./StudentForm";
import StudentList from "./StudentList";
import Modal from "./Modal";
import "./Dashboard.css";

const Dashboard = () => {
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [refresh, setRefresh] = useState(0);
  const [formModalOpen, setFormModalOpen] = useState(false);

  const handleSave = () => {
    setSelectedStudent(null);
    setFormModalOpen(false);
    setRefresh((prev) => prev + 1);
  };

  const openAddForm = () => {
    setSelectedStudent(null);
    setFormModalOpen(true);
  };

  return (
    <div className="dashboard-container">
      <div className="header-wrapper">
        <h2>All Students</h2>
        <div className="add-student-wrapper">
          <button className="add-student-btn" onClick={openAddForm}>
            ✚ Add Student
          </button>
        </div>
      </div>

      <Modal isOpen={formModalOpen} onClose={() => setFormModalOpen(false)}>
        <StudentForm selectedStudent={selectedStudent} onSave={handleSave} />
      </Modal>

      <hr />
      <StudentList
        onSelectStudent={(s) => {
          setSelectedStudent(s);
          setFormModalOpen(true);
        }}
        refresh={refresh}
      />
    </div>
  );
};

export default Dashboard;
