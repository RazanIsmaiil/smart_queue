import { getPool } from "./_db.js";

export default async function handler(req, res) {
  // CORS (اختياري)
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();

  if (req.method !== "POST") {
    return res.status(405).json({ ok: false, msg: "Method not allowed" });
  }

  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({ ok: false, msg: "Email and password are required" });
    }

    const db = getPool();

    // ✅ login بسيط (بدون hash)
    const [rows] = await db.query(
      "SELECT id, full_name, email, role FROM users WHERE email=? AND password=? LIMIT 1",
      [email, password]
    );

    if (!rows || rows.length === 0) {
      return res.status(401).json({ ok: false, msg: "Invalid email or password" });
    }

    const user = rows[0];
    return res.status(200).json({ ok: true, user });
  } catch (e) {
    console.error("LOGIN_ERROR:", e);
    return res.status(500).json({ ok: false, msg: "Server error" });
  }
}