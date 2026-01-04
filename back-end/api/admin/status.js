import mysql from "mysql2/promise";

let pool;
function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
      waitForConnections: true,
      connectionLimit: 2,
      connectTimeout: 10000,
    });
  }
  return pool;
}

export default async function handler(req, res) {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();

  if (req.method !== "GET") {
    return res.status(405).json({ ok: false, msg: "Method not allowed" });
  }

  try {
    const db = getPool();

    const [[state]] = await db.query(`SELECT current_turn, last_issued FROM queue_state WHERE id=1`);

    const [waitingRows] = await db.query(
      `SELECT turn_number FROM customers WHERE status='waiting' ORDER BY turn_number ASC`
    );

    const nextTurn = waitingRows.length ? waitingRows[0].turn_number : state.current_turn;

    return res.status(200).json({
      ok: true,
      currentTurn: state.current_turn,
      lastIssued: state.last_issued,
      nextTurn,
      waitingCount: waitingRows.length,
      waitingList: waitingRows.map((r) => r.turn_number),
    });
  } catch (err) {
    console.error("ADMIN STATUS ERROR:", err);
    return res.status(500).json({ ok: false, error: err.message });
  }
}