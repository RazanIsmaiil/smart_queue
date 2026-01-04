import db from "./_db.js";

export default async function handler(req, res) {
  // CORS (اختياري إذا عم تجرب من web)
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ ok: false, msg: "Method not allowed" });

  try {
    const { full_name, email, password } = req.body || {};

    if (!full_name || !email || !password) {
      return res.status(400).json({ ok: false, msg: "Please fill all fields" });
    }

    if (String(password).length < 4) {
      return res.status(400).json({ ok: false, msg: "Password too short" });
    }

    // تأكد إن الإيميل مش موجود
    const [exists] = await db.query("SELECT id FROM users WHERE email = ? LIMIT 1", [email]);
    if (exists.length > 0) {
      return res.status(409).json({ ok: false, msg: "Email already exists" });
    }

    // role افتراضي user (من DB أصلاً)
    const [result] = await db.query(
      "INSERT INTO users (full_name, email, password) VALUES (?, ?, ?)",
      [full_name, email, password]
    );

    const userId = result.insertId;

    // رجّع user
    const [rows] = await db.query(
      "SELECT id, full_name, email, role FROM users WHERE id = ? LIMIT 1",
      [userId]
    );

    return res.status(201).json({
      ok: true,
      msg: "Account created",
      user: rows[0],
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ ok: false, msg: "Server error" });
  }
}