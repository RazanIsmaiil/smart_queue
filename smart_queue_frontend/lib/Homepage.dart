import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl = "https://smart-queue-omega.vercel.app";

  bool loading = true;
  String error = "";

  int currentTurn = 0;
  int lastIssued = 0;

  int? myTurn;     // turn_number (إذا عندو تذكرة)
  int? beforeMe;   // كم واحد قبله

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadAll(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) setState(() => loading = true);

    try {
      // 1) queue status
      final statusRes = await http
          .get(Uri.parse("$baseUrl/api/queue/status"))
          .timeout(const Duration(seconds: 10));
      final statusData = jsonDecode(statusRes.body);

      if (statusRes.statusCode != 200 || statusData["ok"] != true) {
        throw Exception(statusData["msg"] ?? "Failed to load queue status");
      }

      final q = statusData["queue"] ?? {};
      final int ct = (q["current_turn"] ?? 0) is int
          ? (q["current_turn"] ?? 0)
          : int.tryParse((q["current_turn"] ?? "0").toString()) ?? 0;

      final int li = (q["last_issued"] ?? 0) is int
          ? (q["last_issued"] ?? 0)
          : int.tryParse((q["last_issued"] ?? "0").toString()) ?? 0;

      // 2) my ticket
      final meRes = await http
          .get(Uri.parse("$baseUrl/api/queue/me?userId=${widget.userId}"))
          .timeout(const Duration(seconds: 10));
      final meData = jsonDecode(meRes.body);

      if (meRes.statusCode != 200 || meData["ok"] != true) {
        throw Exception(meData["msg"] ?? "Failed to load my ticket");
      }

      final ticket = meData["myTicket"]; // ممكن null
      final int? turn = ticket == null
          ? null
          : ((ticket["turn_number"] is int)
              ? ticket["turn_number"]
              : int.tryParse((ticket["turn_number"] ?? "").toString()));

      final int? bm = (meData["beforeMe"] is int)
          ? meData["beforeMe"]
          : int.tryParse((meData["beforeMe"] ?? "").toString());

      if (!mounted) return;
      setState(() {
        currentTurn = ct;
        lastIssued = li;
        myTurn = turn;
        beforeMe = bm;
        error = "";
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Error: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextTurn = currentTurn + 1;

    final isNow = myTurn != null && myTurn == currentTurn;
    final isNext = myTurn != null && myTurn == currentTurn + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Queue", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: () => _loadAll(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Logout",
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Logout?"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );

              if (ok == true && mounted) {
                // لازم تكون عامل route اسمه /login
                Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.yellow.shade50, Colors.white, Colors.yellow.shade100],
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (error.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(error, style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // HERO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [Colors.yellow.shade700, Colors.yellow.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.confirmation_number, size: 30, color: Colors.black),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Track your turn in real-time.\nUser ID: ${widget.userId}",
                              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.25),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _bigCard(
                      title: "Current Turn",
                      value: "$currentTurn",
                      icon: Icons.play_circle_fill,
                    ),

                    const SizedBox(height: 12),

                    _bigCard(
                      title: "Next Turn",
                      value: "$nextTurn",
                      icon: Icons.next_plan,
                    ),

                    const SizedBox(height: 12),

                    _smallRow(
                      leftTitle: "Last Issued",
                      leftValue: "$lastIssued",
                      rightTitle: "Your Turn",
                      rightValue: myTurn == null ? "-" : "$myTurn",
                    ),

                    const SizedBox(height: 16),

                    // YOUR TICKET CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Your Ticket", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),

                          if (myTurn == null) ...[
                            const Text(
                              "You don't have an active ticket yet.\nAsk the shop owner to add you to the queue.",
                              style: TextStyle(color: Colors.black54, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                _snack("Waiting for the shop to add you...", ok: true);
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text("Info"),
                            ),
                          ] else ...[
                            Text(
                              "Your number: $myTurn",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "People before you: ${beforeMe ?? 0}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),

                            if (isNow)
                              _notice(
                                title: "It's your turn الآن ✅",
                                msg: "Please go to the counter.",
                                icon: Icons.check_circle,
                                color: Colors.green,
                              )
                            else if (isNext)
                              _notice(
                                title: "You are NEXT ⏳",
                                msg: "Get ready, your turn is coming.",
                                icon: Icons.schedule,
                                color: Colors.orange,
                              )
                            else
                              _notice(
                                title: "Please wait",
                                msg: "Keep this page open to see live updates.",
                                icon: Icons.hourglass_bottom,
                                color: Colors.blueGrey,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _notice({
    required String title,
    required String msg,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(msg, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigCard({required String title, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.yellow.shade700, Colors.yellow.shade400]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 30, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallRow({
    required String leftTitle,
    required String leftValue,
    required String rightTitle,
    required String rightValue,
  }) {
    return Row(
      children: [
        Expanded(child: _miniCard(leftTitle, leftValue)),
        const SizedBox(width: 12),
        Expanded(child: _miniCard(rightTitle, rightValue)),
      ],
    );
  }

  Widget _miniCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}