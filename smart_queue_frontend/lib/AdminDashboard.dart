import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Admindashboard extends StatefulWidget {
  const Admindashboard({super.key});

  @override
  State<Admindashboard> createState() => _AdmindashboardState();
}

class _AdmindashboardState extends State<Admindashboard> {
  // ✅ Your Vercel host
  final String baseHost = "smart-queue-omega.vercel.app";

  bool loading = true;
  bool actionLoading = false;
  String errorMsg = "";

  int currentTurn = 0;
  int nextTurn = 0;
  int lastIssued = 0;
  int waitingCount = 0;
  List<int> waitingList = [];

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    setState(() {
      loading = true;
      errorMsg = "";
    });

    try {
      final uri = Uri.https(baseHost, "/api/admin/status");
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        setState(() {
          currentTurn = (data["currentTurn"] ?? 0) is int
              ? data["currentTurn"]
              : int.tryParse(data["currentTurn"].toString()) ?? 0;

          nextTurn = (data["nextTurn"] ?? 0) is int
              ? data["nextTurn"]
              : int.tryParse(data["nextTurn"].toString()) ?? 0;

          lastIssued = (data["lastIssued"] ?? 0) is int
              ? data["lastIssued"]
              : int.tryParse(data["lastIssued"].toString()) ?? 0;

          waitingCount = (data["waitingCount"] ?? 0) is int
              ? data["waitingCount"]
              : int.tryParse(data["waitingCount"].toString()) ?? 0;

          waitingList = ((data["waitingList"] ?? []) as List)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((x) => x > 0)
              .toList();

          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = data["msg"]?.toString() ?? "Failed to load status";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network/Server error: $e";
      });
    }
  }

  Future<void> addCustomer() async {
    setState(() => actionLoading = true);
    try {
      final uri = Uri.https( "https://smart-queue-omega.vercel.app/api/admin/addCustomer");
      final res = await http.post(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if ((res.statusCode == 201 || res.statusCode == 200) && data["ok"] == true) {
        final turn = int.tryParse((data["turnNumber"] ?? "").toString()) ?? 0;
        _snack(turn > 0 ? "Customer added ✅ Turn: $turn" : "Customer added ✅");
        await fetchStatus();
      } else {
        _snack(data["msg"]?.toString() ?? "Failed to add customer", ok: false);
      }
    } catch (e) {
      _snack("Server error: $e", ok: false);
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> nextTurnAction() async {
    setState(() => actionLoading = true);
    try {
      final uri = Uri.https(baseHost, "/api/admin/next");
      final res = await http.post(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        final msg = (data["msg"] ?? "Done").toString();
        _snack(msg, ok: true);
        await fetchStatus();
      } else {
        _snack(data["msg"]?.toString() ?? "Failed to move next", ok: false);
      }
    } catch (e) {
      _snack("Server error: $e", ok: false);
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> resetQueue() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset queue?"),
        content: const Text("This will delete all waiting customers and reset turns to 0."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Reset"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => actionLoading = true);
    try {
      final uri = Uri.https(baseHost, "/api/admin/reset");
      final res = await http.post(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        _snack("Queue reset ✅");
        await fetchStatus();
      } else {
        _snack(data["msg"]?.toString() ?? "Reset failed", ok: false);
      }
    } catch (e) {
      _snack("Server error: $e", ok: false);
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: actionLoading ? null : fetchStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ✅ Hero summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [Colors.yellow.shade700, Colors.yellow.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.confirmation_number, color: Colors.black, size: 30),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Queue Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text("Waiting: $waitingCount • Last Issued: $lastIssued",
                                      style: const TextStyle(color: Colors.black87)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ✅ Big numbers
                      Row(
                        children: [
                          Expanded(child: _statCard("Current", "$currentTurn", Icons.play_circle_fill)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard("Next", "$nextTurn", Icons.skip_next)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ✅ Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: actionLoading ? null : addCustomer,
                              icon: actionLoading
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.person_add),
                              label: const Text("Add Customer"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow.shade700,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: actionLoading ? null : nextTurnAction,
                              icon: const Icon(Icons.skip_next),
                              label: const Text("Next"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black54),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: actionLoading ? null : resetQueue,
                              icon: const Icon(Icons.restart_alt),
                              label: const Text("Reset"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ✅ Waiting list
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Waiting List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            if (waitingList.isEmpty)
                              const Text("No waiting customers 👌", style: TextStyle(color: Colors.black54))
                            else
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: waitingList
                                    .take(40)
                                    .map((t) => _chip(t == nextTurn ? "Next: $t" : "$t",
                                        highlight: t == nextTurn))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? Colors.yellow.shade700 : Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}