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
      return res.status(400).json({ message: "username and password are required" });
    }

    const cleanUsername = String(username).trim();
    const cleanPassword = String(password).trim();

    if (cleanUsername.length < 3) {
      return res.status(400).json({ message: "Username must be at least 3 characters" });
    }
    if (cleanPassword.length < 4) {
      return res.status(400).json({ message: "Password must be at least 4 characters" });
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
      ssl: { rejectUnauthorized: false },
    });
    // ======================================

    // username exists?
    const [exists] = await pool.query(
      "SELECT id FROM users WHERE username=? LIMIT 1",
      [cleanUsername]
    );

    if (exists.length > 0) {
      return res.status(409).json({ message: "Username already exists" });
    }

    // always create normal user
    const role = "user";

    const [r] = await pool.query(
      "INSERT INTO users (username, password, role) VALUES (?, ?, ?)",
      [cleanUsername, cleanPassword, role]
    );

    return res.status(201).json({
      success: true,
      user: {
        id: r.insertId,
        username: cleanUsername,
        role: role,
      },
    });

  } catch (error) {
    console.error("SIGNUP ERROR:", error);
    return res.status(500).json({
      message: "Server error",
      error: String(error.message || error),
    });
  }
}