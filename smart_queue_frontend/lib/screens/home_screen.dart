import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  List queue = [];
  String message = "";

  @override
  void initState() {
    super.initState();
    loadQueue();
  }

  Future<void> loadQueue() async {
    final data = await ApiService.getQueue();
    setState(() {
      queue = data;
    });
  }

  Future<void> addCustomer() async {
    final result =
        await ApiService.addCustomer(_nameController.text);
    setState(() {
      message = "Ticket Number: ${result['ticket_number']}";
      _nameController.clear();
    });
    loadQueue();
  }

  Future<void> serveNext() async {
    final result = await ApiService.nextCustomer();
    setState(() {
      message = result['customer'] != null
          ? "Now Serving: ${result['customer']['customer_name']}"
          : result['message'];
    });
    loadQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Appointment Queue")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: "Customer Name"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: addCustomer,
              child: const Text("Add to Queue"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: serveNext,
              child: const Text("Serve Next"),
            ),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(fontSize: 16)),
            const Divider(),
            const Text("Current Queue",
                style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                        "#${queue[index]['ticket_number']} - ${queue[index]['customer_name']}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
