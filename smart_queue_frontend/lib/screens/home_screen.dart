import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'queue_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  // Method to add customer via the backend service [cite: 3, 10]
  Future<void> addCustomer() async {
    if (_nameController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.addCustomer(_nameController.text);
      _showTicketDialog(result['ticket_number'].toString());
      _nameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: Check Backend URL")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showTicketDialog(String ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Registration Successful"),
        content: Text("Your ticket number is: $ticket"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Queue System"),
        centerTitle: true,
        actions: [
          // Navigation to the second activity 
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QueueManagerScreen()),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_num_outlined, size: 100, color: Colors.indigo),
            const SizedBox(height: 30),
            const Text(
              "Welcome to our Service",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Please enter your name to get a ticket"),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : addCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("GET TICKET", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}