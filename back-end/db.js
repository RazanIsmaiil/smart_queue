const mysql = require("mysql2");
require("dotenv").config();

// Using a Pool for better stability and reconnection handling
const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Testing the pool connection
db.getConnection((err, connection) => {
  if (err) {
    console.error("Database connection failed:", err.message);
  } else {
    console.log("Connected to MySQL Pool ✅");
    connection.release(); // Release back to pool
  }
});

module.exports = db;



