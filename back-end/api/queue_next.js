import mysql from "mysql2/promise";

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ message: "Method not allowed" });

  try {
    const { queueId } = req.body || {};
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

    // أول waiting
    const [rows] = await pool.query(
      "SELECT id, ticket_number FROM tickets WHERE queue_id=? AND status='waiting' ORDER BY ticket_number ASC LIMIT 1",
      [queueId]
    );

    if (rows.length === 0) {
      return res.status(200).json({ success: true, message: "No waiting tickets" });
    }

    const ticketId = rows[0].id;

    await pool.query(
      "UPDATE tickets SET status='called' WHERE id=?",
      [ticketId]
    );

    return res.status(200).json({
      success: true,
      called: { id: ticketId, ticketNumber: rows[0].ticket_number },
    });
  } catch (e) {
    console.error("queue_next", e);
    return res.status(500).json({ message: "Server error", details: String(e.message || e) });
  }
}