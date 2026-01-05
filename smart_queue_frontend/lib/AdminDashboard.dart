import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDashboard extends StatefulWidget {
  final int userId;
  final String username;

  const AdminDashboard({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // 🔁 حط رابط Vercel تبعك
  static const String baseUrl = "https://smart-queue-omega.vercel.app";

  // بالبداية خليها ثابتة
  final int queueId = 1;

  final TextEditingController nameCtrl = TextEditingController();

  bool loading = true;
  bool adding = false;
  bool nexting = false;
  String error = "";

  int currentTurn = 0;
  List<Map<String, dynamic>> tickets = [];

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> loadAll() async {
    setState(() {
      loading = true;
      error = "";
    });

    try {
      // list
      final listUri = Uri.parse("$baseUrl/api/queue_list?queueId=$queueId");
      final listRes = await http.get(listUri);

      if (listRes.statusCode != 200) {
        throw Exception("List failed: ${listRes.body}");
      }

      final listData = jsonDecode(listRes.body);
      final List<dynamic> t = listData["tickets"] ?? [];

      final parsed = t.map((e) => Map<String, dynamic>.from(e)).toList();

      // current = أول waiting
      int cur = 0;
      for (final item in parsed) {
        if ((item["status"] ?? "") == "waiting") {
          cur = item["ticket_number"] ?? 0;
          break;
        }
      }

      setState(() {
        tickets = parsed;
        currentTurn = cur;
      });
    } catch (e) {
      setState(() => error = "Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> addCustomer() async {
    final name = nameCtrl.text.trim();
    setState(() {
      adding = true;
      error = "";
    });

    try {
      final uri = Uri.parse("$baseUrl/api/queue_add");
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueId": queueId,
          "customerName": name.isEmpty ? null : name,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception(res.body);
      }

      nameCtrl.clear();
      await loadAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Customer added ✅"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => error = "Add failed: $e");
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  Future<void> nextTurn() async {
    setState(() {
      nexting = true;
      error = "";
    });

    try {
      final uri = Uri.parse("$baseUrl/api/queue_next");
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"queueId": queueId}),
      );

      if (res.statusCode != 200) throw Exception(res.body);

      await loadAll();
    } catch (e) {
      setState(() => error = "Next failed: $e");
    } finally {
      if (mounted) setState(() => nexting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4F7FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0FA3B1),
        foregroundColor: Colors.white,
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            onPressed: loading ? null : loadAll,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top cards
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: "Current Turn",
                          value: currentTurn == 0 ? "-" : "$currentTurn",
                          icon: Icons.confirmation_number_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: "Total Tickets",
                          value: "${tickets.length}",
                          icon: Icons.list_alt,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Add customer
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
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              labelText: "Customer name (optional)",
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
                          child: ElevatedButton.icon(
                            onPressed: adding ? null : addCustomer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0FA3B1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: adding
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: const Text("Add"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ErrorBox(error: error),
                  ],

                  const SizedBox(height: 14),

                  // Next
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: nexting ? null : nextTurn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4965),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: nexting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              "Call Next",
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // List
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: tickets.isEmpty
                          ? const Center(child: Text("No tickets yet"))
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: tickets.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 14,
                                color: Colors.black.withOpacity(0.06),
                              ),
                              itemBuilder: (context, i) {
                                final t = tickets[i];
                                final num = t["ticket_number"];
                                final name = t["customer_name"] ?? "";
                                final status = (t["status"] ?? "").toString();

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: statusColor(status).withOpacity(0.15),
                                    child: Text(
                                      "$num",
                                      style: TextStyle(
                                        color: statusColor(status),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name.toString().isEmpty ? "Customer #$num" : name.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Text("Status: $status"),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
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
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0FA3B1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0FA3B1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.black.withOpacity(0.6))),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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