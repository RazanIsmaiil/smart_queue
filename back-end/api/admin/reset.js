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

    await db.query(`UPDATE queue_state SET current_turn=0, last_issued=0 WHERE id=1`);
    await db.query(`DELETE FROM customers`); // أو بدلها UPDATE status='cancelled'

    return res.status(200).json({ ok: true, msg: "Queue reset" });
  } catch (err) {
    console.error("RESET ERROR:", err);
    return res.status(500).json({ ok: false, error: err.message });
  }
}