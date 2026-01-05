import mysql from "mysql2/promise";

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "GET") return res.status(405).json({ message: "Method not allowed" });

  try {
    const queueId = req.query.queueId;
    if (!queueId) return res.status(400).json({ message: "queueId is required" });

    const pool = mysql.createPool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD || process.env.DB_PASS,
      database: process.env.DB_NAME,
      waitForConnections: true,
      connectionLimit: 5,
      ssl: { rejectUnauthorized: false },
    });

    const [rows] = await pool.query(
      "SELECT id, customer_name, ticket_number, status, created_at FROM tickets WHERE queue_id=? ORDER BY ticket_number ASC",
      [queueId]
    );

    return res.status(200).json({ success: true, tickets: rows });
  } catch (e) {
    console.error("queue_list", e);
    return res.status(500).json({ message: "Server error", details: String(e.message || e) });
  }
}