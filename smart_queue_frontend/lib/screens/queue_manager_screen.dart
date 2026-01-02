import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QueueManagerScreen extends StatefulWidget {
  const QueueManagerScreen({super.key});

  @override
  State<QueueManagerScreen> createState() => _QueueManagerScreenState();
}

class _QueueManagerScreenState extends State<QueueManagerScreen> {
  List queue = [];
  String currentStatus = "No customer being served";

  @override
  void initState() {
    super.initState();
    refreshQueue();
  }

  Future<void> refreshQueue() async {
    final data = await ApiService.getQueue();
    setState(() => queue = data);
  }

  Future<void> callNextCustomer() async {
    final result = await ApiService.nextCustomer();
    setState(() {
      currentStatus = result['customer'] != null
          ? "Now Serving: ${result['customer']['customer_name']}"
          : "Queue is empty";
    });
    refreshQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Management Panel")),
      body: Column(
        children: [
          // Current Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              children: [
                const Text("SERVICE STATUS", style: TextStyle(letterSpacing: 1.2, color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  currentStatus, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: callNextCustomer,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text("SERVE NEXT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
          ),
          // Waiting List Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Waiting List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.list),
              ],
            ),
          ),
          // List of customers from online database [cite: 10]
          Expanded(
            child: ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Text(
                        "${queue[index]['ticket_number']}",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    title: Text("${queue[index]['customer_name']}"),
                    trailing: const Text("Waiting", style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}