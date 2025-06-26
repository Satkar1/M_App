import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIResultPage extends StatefulWidget {
  const AIResultPage({super.key});

  @override
  State<AIResultPage> createState() => _AIResultPageState();
}

class _AIResultPageState extends State<AIResultPage> {
  List<Map<String, dynamic>> expenses = [];
  String aiSuggestion = '';
  bool isLoading = true;

  final String geminiApiKey = 'AIzaSyCf5z3JSIvlYvQNvRjRA3aB0Znbl9YEJTk';

  @override
  void initState() {
    super.initState();
    fetchExpensesAndGetSuggestion();
  }

  Future<void> fetchExpensesAndGetSuggestion() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .orderBy('timestamp', descending: true)
          .get();

      expenses = snapshot.docs.map((doc) {
        return {
          'amount': doc['amount'],
          'category': doc['category'],
          'timestamp': doc['timestamp'].toDate().toIso8601String(),
        };
      }).toList();

      if (expenses.isNotEmpty) {
        await getSuggestionFromGemini(expenses);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> getSuggestionFromGemini(List<Map<String, dynamic>> expenses) async {
    final promptBuffer = StringBuffer("Here are my recent expenses:\n");

    for (var e in expenses) {
      promptBuffer.writeln("- ${e['category']}: ₹${e['amount']}");
    }

    promptBuffer.writeln("\nGive me personalized, well-formatted tips to reduce spending and save money.");

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$geminiApiKey',
    );

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": promptBuffer.toString()}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          aiSuggestion = data['candidates'][0]['content']['parts'][0]['text'] ?? 'No suggestions received.';
        });
      } else {
        print("Gemini API failed: ${response.body}");
      }
    } catch (e) {
      print("Gemini error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Budget Insights"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recent Expenses",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final e = expenses[index];
                        return ListTile(
                          leading: const Icon(Icons.money),
                          title: Text('${e['category']} - ₹${e['amount']}'),
                          subtitle: Text(
                            DateTime.parse(e['timestamp']).toLocal().toString().split(' ')[0],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    "AI Suggestions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          aiSuggestion.isNotEmpty
                              ? aiSuggestion
                              : 'Smart Spending Tips:\n\n'
                                  '• Entertainment: Cut movie costs—switch to OTT or reduce visits. Save ₹500/month.\n'
                                  '• Shopping: Delay big buys like ₹2100 watch. Ask yourself if you need it.\n'
                                  '• Bills: Reduce electricity & water—saves ₹200–300/month.\n\n'
                                  '💡 You can save ₹1500–₹2000/month easily!',
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
