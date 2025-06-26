import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> expenses = [];
  String activeTab = "Dashboard";
  bool isSidebarExpanded = true;

  Future<double> fetchTotalExpenses() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    double totalExpenses = 0.0;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    for (var doc in snapshot.docs) {
      totalExpenses += (doc['amount'] ?? 0).toDouble();
    }
    return totalExpenses;
  }

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('expenses')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        expenses = snapshot.docs.map((doc) => doc.data()).toList();
      });
    }
  }

  Map<String, double> getCategoryData() {
    Map<String, double> data = {};
    for (var expense in expenses) {
      String category = expense['category'] ?? 'Others';
      double amount = (expense['amount'] ?? 0).toDouble();
      data[category] = (data[category] ?? 0) + amount;
    }
    return data;
  }

  Future<double> fetchTotalIncome() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    double totalIncome = 0.0;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('income')
        .get();

    for (var doc in snapshot.docs) {
      totalIncome += (doc['amount'] ?? 0).toDouble();
    }
    return totalIncome;
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = getCategoryData();
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    if (isMobile && isSidebarExpanded) {
      isSidebarExpanded = false; // Default to collapsed on small screen
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Row(
        children: [
          // Sidebar (collapsible for mobile)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSidebarExpanded ? 220 : 70,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade900.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    isSidebarExpanded ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isSidebarExpanded = !isSidebarExpanded;
                    });
                  },
                ),
                const SizedBox(height: 20),
                sidebarItem(Icons.dashboard, "Dashboard", isMobile),
                sidebarItem(Icons.add, "Add Expense", isMobile, onTap: () => Navigator.pushNamed(context, '/add-expense')),
                sidebarItem(Icons.attach_money, "Add Income", isMobile, onTap: () => Navigator.pushNamed(context, '/add-income')),
                sidebarItem(Icons.analytics, "AI Analysis", isMobile, onTap: () => Navigator.pushNamed(context, '/ai-result')),
                const Spacer(),
                sidebarItem(Icons.logout, "Logout", isMobile, onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                }),
              ],
            ),
          ),

          // Right Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.email ?? 'User'}!',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 10),

                  FutureBuilder<List<double>>(
                    future: Future.wait([fetchTotalIncome(), fetchTotalExpenses()]),
                    builder: (context, AsyncSnapshot<List<double>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      double income = snapshot.data?[0] ?? 0;
                      double expenses = snapshot.data?[1] ?? 0;
                      double savings = income - expenses;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Income: ₹$income", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                          Text("Total Expenses: ₹$expenses", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                          Text("Savings: ₹$savings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: savings >= 0 ? Colors.blue : Colors.red)),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: income > 0 ? (expenses / income).clamp(0, 1) : 0,
                            backgroundColor: Colors.green.shade200,
                            color: Colors.red,
                            minHeight: 10,
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),

                  const Text('Recent Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  expenses.isEmpty
  ? const Center(child: Text('No expenses added yet.', style: TextStyle(color: Colors.grey)))
  : SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final exp = expenses[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 180,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${exp['title']} - ₹${exp['amount']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${exp['category']} - ${exp['date']?.toDate().toString().split(' ')[0] ?? ''}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    ),


                  const SizedBox(height: 20),
                  const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                    ),
                    child: buildPieChart(categoryData),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sidebarItem(IconData icon, String text, bool isMobile, {VoidCallback? onTap}) {
    bool isActive = activeTab == text;
    return MouseRegion(
      onEnter: (_) => setState(() => activeTab = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.shade900 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: isSidebarExpanded ? Text(text, style: const TextStyle(color: Colors.white)) : null,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget buildPieChart(Map<String, double> data) {
    final sections = data.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: entry.key,
        radius: 60,
        color: Colors.primaries[data.keys.toList().indexOf(entry.key) % Colors.primaries.length],
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 35,
        sectionsSpace: 3,
        pieTouchData: PieTouchData(enabled: true),
      ),
    );
  }
}
