import mysql from "mysql2/promise";

export default async function handler(req, res) {

  // ================= CORS =================
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ message: "Method not allowed" });
  }
  // ========================================

  try {
    const { username, password } = req.body || {};

    if (!username || !password) {
      return res.status(400).json({
        message: "username and password are required",
      });
    }
const pass = process.env.DB_PASS;
if (!pass || pass.trim() === "") {
  return res.status(500).json({
    message: "DB_PASS is missing inside Vercel function",
    has_DB_PASS: !!process.env.DB_PASS,
    DB_PASS_length: process.env.DB_PASS ? process.env.DB_PASS.length : 0,
  });
}
    // ============ DB CONNECTION ============
    const pool = await mysql.createPool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
      waitForConnections: true,
      connectionLimit: 5,
      queueLimit: 0,
      ssl: { rejectUnauthorized: false }, // مهم لـ Railway
    });
    // ======================================

    const [rows] = await pool.query(
      "SELECT id, username, role FROM users WHERE username=? AND password=?",
      [username.trim(), password.trim()]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        message: "Invalid username or password",
      });
    }

    return res.status(200).json({
      success: true,
      user: rows[0],
    });

  } catch (error) {
    console.error("LOGIN ERROR:", error);
    return res.status(500).json({
      message: "Server error",
      error: String(error.message || error),
    });
  }
}