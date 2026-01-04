import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_queue_frontend/loginpage.dart';
 // أو Navigator.pop()

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool obscure1 = true;
  bool obscure2 = true;

  final String baseUrl = "https://smart-queue-omega.vercel.app"; // غيّرها إذا لازم

  void showSnack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  bool validate() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final pass = passController.text.trim();
    final conf = confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || conf.isEmpty) {
      showSnack("Please fill all fields");
      return false;
    }
    if (!email.contains("@")) {
      showSnack("Please enter a valid email");
      return false;
    }
    if (pass.length < 4) {
      showSnack("Password must be at least 4 characters");
      return false;
    }
    if (pass != conf) {
      showSnack("Passwords do not match");
      return false;
    }
    return true;
  }

  Future<void> signup() async {
    FocusScope.of(context).unfocus();
    if (!validate()) return;

    setState(() => isLoading = true);

    final uri = Uri.parse("$baseUrl/api/signup");

    final body = {
      "full_name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passController.text.trim(),
    };

    try {
      final res = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if ((res.statusCode == 201 || res.statusCode == 200) && data["ok"] == true) {
        showSnack("Account created successfully ✅", ok: true);

        // رجّع على login بعد ثواني صغيرة
        await Future.delayed(const Duration(milliseconds: 600));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        showSnack(data["msg"]?.toString() ?? "Signup failed");
      }
    } catch (e) {
      showSnack("Server/Network error. Try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade700, Colors.yellow.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_taxi, size: 70, color: Colors.black),
                  const SizedBox(height: 10),
                  const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      hintText: "Full Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      hintText: "Email",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: passController,
                    obscureText: obscure1,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      hintText: "Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      suffixIcon: IconButton(
                        icon: Icon(obscure1 ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => obscure1 = !obscure1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: confirmController,
                    obscureText: obscure2,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: "Confirm Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      suffixIcon: IconButton(
                        icon: Icon(obscure2 ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => obscure2 = !obscure2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Already have an account? Login"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}