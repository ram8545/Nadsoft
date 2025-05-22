const express = require("express");
const bodyParser = require("body-parser");
const studentRoutes = require("./routes/studentRoutes");
const cors = require("cors");

const app = express();
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);
app.use(bodyParser.json());

app.get("/", (req, res) => {
  res.json("Welcome to API World");
});

app.use("/api/students", studentRoutes);

app.listen(3001, () => console.log(" Server running on port 3001"));
