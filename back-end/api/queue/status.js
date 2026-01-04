import { db } from "../_db.js";

export default async function handler(req, res) {
  try {
    if (req.method !== "GET") return res.status(405).json({ ok: false, msg: "Method not allowed" });

    const [[row]] = await db.query(
      "SELECT current_turn, last_issued, updated_at FROM queue_state WHERE id=1 LIMIT 1"
    );

    return res.json({ ok: true, queue: row });
  } catch (e) {
    return res.status(500).json({ ok: false, msg: "Server error", error: String(e) });
  }
}