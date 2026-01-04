import { db } from "../_db.js";

export default async function handler(req, res) {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({ ok: false, msg: "Method not allowed" });
    }

    const { userId } = req.body;
    if (!userId) return res.status(400).json({ ok: false, msg: "userId is required" });

    // إذا المستخدم عنده تذكرة waiting مسبقاً ما نعمل واحدة جديدة
    const [existing] = await db.query(
      `SELECT id, turn_number, status
       FROM customers
       WHERE user_id=? AND status='waiting'
       ORDER BY turn_number DESC LIMIT 1`,
      [userId]
    );

    const [[qs]] = await db.query("SELECT last_issued FROM queue_state WHERE id=1 LIMIT 1");
    if (!qs) return res.status(404).json({ ok: false, msg: "queue_state not found" });

    if (existing.length) {
      return res.json({
        ok: true,
        msg: "You already have a waiting ticket",
        ticket: existing[0],
        lastIssued: qs.last_issued,
      });
    }

    // Transaction لضمان ما يصير رقمين نفس الشي
    await db.query("START TRANSACTION");

    // زيد last_issued
    await db.query("UPDATE queue_state SET last_issued = last_issued + 1 WHERE id=1");

    const [[qs2]] = await db.query("SELECT last_issued FROM queue_state WHERE id=1 LIMIT 1");
    const newTurn = qs2.last_issued;

    const [ins] = await db.query(
      "INSERT INTO customers (user_id, turn_number, status) VALUES (?, ?, 'waiting')",
      [userId, newTurn]
    );

    await db.query("COMMIT");

    return res.status(201).json({
      ok: true,
      msg: "Ticket created",
      ticket: { id: ins.insertId, user_id: userId, turn_number: newTurn, status: "waiting" },
    });
  } catch (e) {
    try { await db.query("ROLLBACK"); } catch (_) {}
    return res.status(500).json({ ok: false, msg: "Server error", error: String(e) });
  }
}