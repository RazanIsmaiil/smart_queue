import mysql from "mysql2/promise";

export default async function handler(req, res) {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ message: "Method not allowed" });

  try {
    const { queueId, customerName } = req.body || {};
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

    const [last] = await pool.query(
      "SELECT ticket_number FROM tickets WHERE queue_id=? ORDER BY ticket_number DESC LIMIT 1",
      [queueId]
    );
    const nextNumber = (last[0]?.ticket_number || 0) + 1;

    const [r] = await pool.query(
      "INSERT INTO tickets (queue_id, customer_name, ticket_number, status) VALUES (?, ?, ?, 'waiting')",
      [queueId, customerName || null, nextNumber]
    );

    return res.status(200).json({
      success: true,
      id: r.insertId,
      ticketNumber: nextNumber,
    });
  } catch (e) {
    console.error("queue_add", e);
    return res.status(500).json({ message: "Server error", details: String(e.message || e) });
  }
}