import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final int userId;
  final String username;

  const HomePage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl = "https://smart-queue-omega.vercel.app";

  final int queueId = 1; // مؤقتاً ثابت
  final TextEditingController ticketCtrl = TextEditingController();

  bool tracking = false;
  bool loading = false;
  String error = "";

  int currentTurn = 0;
  int myTicket = 0;
  int beforeMe = 0;
  String myStatus = "waiting";

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    ticketCtrl.dispose();
    super.dispose();
  }

  Color statusColor(String s) {
    switch (s) {
      case "waiting":
        return const Color(0xFF0FA3B1);
      case "called":
        return const Color(0xFF1B4965);
      case "done":
        return Colors.green;
      case "skipped":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchStatus({bool silent = false}) async {
    if (!tracking) return;

    final t = int.tryParse(ticketCtrl.text.trim());
    if (t == null || t <= 0) return;

    if (!silent) {
      setState(() {
        loading = true;
        error = "";
      });
    }

    try {
      final uri = Uri.parse("$baseUrl/api/user_status?queueId=$queueId&ticketNumber=$t");
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          currentTurn = data["currentTurn"] ?? 0;
          beforeMe = data["beforeMe"] ?? 0;
          myTicket = data["myTicket"]?["ticketNumber"] ?? t;
          myStatus = (data["myTicket"]?["status"] ?? "waiting").toString();
        });
      } else {
        String msg = "Failed";
        try {
          final data = jsonDecode(res.body);
          if (data["message"] != null) msg = data["message"];
        } catch (_) {}
        setState(() => error = msg);
      }
    } catch (e) {
      setState(() => error = "Network error: $e");
    } finally {
      if (!silent) setState(() => loading = false);
    }
  }

  void _startTracking() {
    final t = int.tryParse(ticketCtrl.text.trim());
    if (t == null || t <= 0) {
      setState(() => error = "Please enter a valid ticket number");
      return;
    }

    setState(() {
      tracking = true;
      error = "";
    });

    _timer?.cancel();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchStatus(silent: true));
  }

  void _stopTracking() {
    _timer?.cancel();
    setState(() {
      tracking = false;
      loading = false;
      error = "";
      currentTurn = 0;
      myTicket = 0;
      beforeMe = 0;
      myStatus = "waiting";
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4F7FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4965),
        foregroundColor: Colors.white,
        title: const Text("My Turn"),
        actions: [
          IconButton(
            onPressed: tracking ? _fetchStatus : null,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _WelcomeCard(username: widget.username),

            const SizedBox(height: 12),

            // Input + buttons
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    color: Colors.black.withOpacity(0.06),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ticketCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Your Ticket Number",
                        hintText: "ex: 5",
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: tracking ? _stopTracking : _startTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tracking
                            ? Colors.redAccent
                            : const Color(0xFF0FA3B1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        tracking ? "Stop" : "Track",
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ErrorBox(error: error),
            ],

            const SizedBox(height: 12),

            if (tracking) ...[
              if (loading) const LinearProgressIndicator(minHeight: 3),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: "Current Turn",
                      value: currentTurn == 0 ? "-" : "$currentTurn",
                      icon: Icons.confirmation_number_outlined,
                      accent: const Color(0xFF0FA3B1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: "My Ticket",
                      value: myTicket == 0 ? "-" : "$myTicket",
                      icon: Icons.person_outline,
                      accent: const Color(0xFF1B4965),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: "People before me",
                      value: "$beforeMe",
                      icon: Icons.groups_2_outlined,
                      accent: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: "Status",
                      value: myStatus,
                      icon: Icons.info_outline,
                      accent: statusColor(myStatus),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Hint card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor(myStatus).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor(myStatus).withOpacity(0.25)),
                ),
                child: Text(
                  myStatus == "called"
                      ? "It's your turn now ✅ Please go to the counter."
                      : myStatus == "waiting"
                          ? "Please wait... we update your status automatically."
                          : "Status: $myStatus",
                  style: TextStyle(
                    color: statusColor(myStatus),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      color: Colors.black.withOpacity(0.06),
                    )
                  ],
                ),
                child: const Text(
                  "Enter your ticket number and tap Track.\nYou will see current turn and how many people are before you.",
                  style: TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String username;
  const _WelcomeCard({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0FA3B1), Color(0xFF1B4965)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Hi $username 👋\nTrack your queue turn",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.black.withOpacity(0.6))),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB3B3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB00020)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFB00020),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}