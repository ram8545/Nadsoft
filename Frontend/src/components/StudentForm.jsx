import React, { useState, useEffect } from "react";
import API from "../api";
import "./StudentForm.css";

const StudentForm = ({ selectedStudent, onSave }) => {
  const [formData, setFormData] = useState({
    first_name: "",
    last_name: "",
    email: "",
    dob: "",
    gender: "Male",
  });

  useEffect(() => {
    if (selectedStudent) {
      setFormData(selectedStudent);
    }
  }, [selectedStudent]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      if (formData.id) {
        await API.put(`/${formData.id}`, formData);
      } else {
        await API.post("/", formData);
      }
      setFormData({
        first_name: "",
        last_name: "",
        email: "",
        dob: "",
        gender: "Male",
      });
      onSave();
    } catch (err) {
      console.error("Submit failed:", err);
    }
  };

  const hasValue = (val) => val && val.trim() !== "";

  return (
    <form onSubmit={handleSubmit}>
      <h2>{formData.id ? "Edit Student" : "Create Student"}</h2>

      <div className="input-group">
        <input
          type="text"
          name="first_name"
          value={formData.first_name}
          onChange={handleChange}
          required
          className={formData.first_name ? "has-value" : ""}
        />
        <label>First Name</label>
      </div>

      <div className="input-group">
        <input
          type="text"
          name="last_name"
          value={formData.last_name}
          onChange={handleChange}
          className={formData.last_name ? "has-value" : ""}
        />
        <label>Last Name</label>
      </div>

      <div className="input-group">
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          required
          className={formData.email ? "has-value" : ""}
        />
        <label>Email</label>
      </div>

      <div className="input-group">
        <input
          type="date"
          name="dob"
          value={formData.dob}
          onChange={handleChange}
          required
          className={formData.dob ? "has-value" : ""}
        />
        <label>DOB</label>
      </div>

      <div className="input-group">
        <select
          name="gender"
          value={formData.gender}
          onChange={handleChange}
          className="has-value"
        >
          <option value="Male">Male</option>
          <option value="Female">Female</option>
        </select>
        <label>Gender</label>
      </div>

      <input type="submit" value={formData.id ? "Update" : "Create"} />
    </form>
  );
};

export default StudentForm;
