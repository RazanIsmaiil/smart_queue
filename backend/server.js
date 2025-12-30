const express = require("express");
const cors = require("cors");
require("dotenv").config();

const app = express();
const db = require("./db");
// Middleware
app.use(cors());
app.use(express.json());

// Test Route
app.get("/", (req, res) => {
  res.send("Smart Appointment Queue API is running 🚀");
});
app.post("/queue/add", (req, res) => {
  const { customer_name } = req.body;

  if (!customer_name) {
    return res.status(400).json({ message: "Customer name is required" });
  }

  const getLastNumber = "SELECT MAX(ticket_number) AS last FROM queue";

  db.query(getLastNumber, (err, result) => {
    if (err) return res.status(500).json(err);

    const nextNumber = (result[0].last || 0) + 1;

    const insertQuery =
      "INSERT INTO queue (customer_name, ticket_number) VALUES (?, ?)";

    db.query(insertQuery, [customer_name, nextNumber], (err) => {
      if (err) return res.status(500).json(err);

      res.json({
        message: "Customer added to queue",
        ticket_number: nextNumber
      });
    });
  });
});
app.get("/queue/list", (req, res) => {
  const query =
    "SELECT * FROM queue WHERE status='waiting' ORDER BY ticket_number ASC";

  db.query(query, (err, results) => {
    if (err) return res.status(500).json(err);
    res.json(results);
  });
});
app.post("/queue/next", (req, res) => {
  const getNext =
    "SELECT * FROM queue WHERE status='waiting' ORDER BY ticket_number ASC LIMIT 1";

  db.query(getNext, (err, result) => {
    if (err) return res.status(500).json(err);

    if (result.length === 0) {
      return res.json({ message: "No customers in queue" });
    }

    const customer = result[0];

    const updateQuery =
      "UPDATE queue SET status='served' WHERE id=?";

    db.query(updateQuery, [customer.id], (err) => {
      if (err) return res.status(500).json(err);

      res.json({
        message: "Next customer served",
        customer
      });
    });
  });
});


// Server Port
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
