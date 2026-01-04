
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

async function readBody(req) {
  return new Promise((resolve) => {
    let data = "";
    req.on("data", (chunk) => (data += chunk));
    req.on("end", () => {
      try {
        resolve(JSON.parse(data || "{}"));
      } catch {
        resolve({});
      }
    });
  });
}

export default async function handler(req, res) {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();

  if (req.method !== "POST") {
    return res.status(405).json({ ok: false, msg: "Method not allowed" });
  }

  try {
    await readBody(req);

    const db = getPool();

    // جيب أول waiting
    const [rows] = await db.query(
      `SELECT id, turn_number FROM customers WHERE status='waiting' ORDER BY turn_number ASC LIMIT 1`
    );

    if (rows.length === 0) {
      return res.status(200).json({ ok: true, msg: "No waiting customers" });
    }

    const customer = rows[0];

    // خليه served + حدّث current_turn
    await db.query(`UPDATE customers SET status='served' WHERE id=?`, [customer.id]);
    await db.query(`UPDATE queue_state SET current_turn=? WHERE id=1`, [customer.turn_number]);

    return res.status(200).json({
      ok: true,
      currentTurn: customer.turn_number,
      msg: "Moved to next",
    });
  } catch (err) {
    console.error("NEXT ERROR:", err);
    return res.status(500).json({ ok: false, error: err.message });
  }
}