import { db } from "../_db.js";

export default async function handler(req, res) {
  try {
    if (req.method !== "GET") return res.status(405).json({ ok: false, msg: "Method not allowed" });

    const userId = Number(req.query.userId);
    if (!userId) return res.status(400).json({ ok: false, msg: "userId is required" });

    const [[qs]] = await db.query(
      "SELECT current_turn, last_issued FROM queue_state WHERE id=1 LIMIT 1"
    );
    if (!qs) return res.status(404).json({ ok: false, msg: "queue_state not found" });

    const [mineRows] = await db.query(
      `SELECT id, user_id, turn_number, status, created_at
       FROM customers
       WHERE user_id = ? AND status = 'waiting'
       ORDER BY turn_number DESC
       LIMIT 1`,
      [userId]
    );

    if (!mineRows.length) {
      return res.json({
        ok: true,
        queue: qs,
        myTicket: null,
        beforeMe: null,
        nextTurn: qs.current_turn + 1,
      });
    }

    const myTicket = mineRows[0];

    const [[cnt]] = await db.query(
      `SELECT COUNT(*) AS c
       FROM customers
       WHERE status='waiting'
         AND turn_number > ?
         AND turn_number < ?`,
      [qs.current_turn, myTicket.turn_number]
    );

    return res.json({
      ok: true,
      queue: qs,
      myTicket,
      beforeMe: cnt?.c ?? 0,
      nextTurn: qs.current_turn + 1,
    });
  } catch (e) {
    return res.status(500).json({ ok: false, msg: "Server error", error: String(e) });
  }
}