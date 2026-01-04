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

// read body for vercel (حتى لو ما بدنا body)
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
    await readBody(req); // مش ضروري بس خليها ready

    const db = getPool();

    // 1) جِب last_issued
    const [[state]] = await db.query(`SELECT last_issued FROM queue_state WHERE id=1`);
    const newTurn = Number(state.last_issued) + 1;

    // 2) حدّث last_issued
    await db.query(`UPDATE queue_state SET last_issued=? WHERE id=1`, [newTurn]);

    // 3) أضف customer جديد
    await db.query(`INSERT INTO customers (turn_number, status) VALUES (?, 'waiting')`, [newTurn]);

    return res.status(201).json({ ok: true, turnNumber: newTurn, msg: "Customer added" });
  } catch (err) {
    console.error("ADD CUSTOMER ERROR:", err);
    return res.status(500).json({ ok: false, error: err.message });
  }
}