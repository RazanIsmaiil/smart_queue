import mysql from "mysql2/promise";

export default async function handler(req, res) {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "GET") return res.status(405).json({ message: "Method not allowed" });

  try {
    const queueId = Number(req.query.queueId);
    const ticketNumber = Number(req.query.ticketNumber);

    if (!queueId || !ticketNumber) {
      return res.status(400).json({ message: "queueId and ticketNumber are required" });
    }

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

    // 1) current = أول waiting
    const [curRows] = await pool.query(
      "SELECT ticket_number FROM tickets WHERE queue_id=? AND status='waiting' ORDER BY ticket_number ASC LIMIT 1",
      [queueId]
    );
    const current = curRows.length ? curRows[0].ticket_number : 0;

    // 2) my ticket status
    const [myRows] = await pool.query(
      "SELECT id, ticket_number, status, customer_name FROM tickets WHERE queue_id=? AND ticket_number=? LIMIT 1",
      [queueId, ticketNumber]
    );

    if (myRows.length === 0) {
      return res.status(404).json({ message: "Ticket not found" });
    }

    const my = myRows[0];

    // 3) before me = عدد المنتظرين اللي رقمهم أقل من رقمي
    const [beforeRows] = await pool.query(
      "SELECT COUNT(*) AS c FROM tickets WHERE queue_id=? AND status='waiting' AND ticket_number < ?",
      [queueId, ticketNumber]
    );
    const beforeMe = beforeRows[0]?.c ?? 0;

    return res.status(200).json({
      success: true,
      currentTurn: current,
      myTicket: {
        ticketNumber: my.ticket_number,
        status: my.status,
        name: my.customer_name,
      },
      beforeMe,
    });
  } catch (e) {
    console.error("user_status", e);
    return res.status(500).json({ message: "Server error", details: String(e.message || e) });
  }
}