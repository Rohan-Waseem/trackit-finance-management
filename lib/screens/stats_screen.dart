import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  double totalSent = 0;
  double totalReceived = 0;
  bool isLoading = true;
  List<FlSpot> sentSpots = [];
  List<FlSpot> receivedSpots = [];

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final transactions = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .orderBy('time')
          .get();

      double sent = 0;
      double received = 0;
      List<FlSpot> sentData = [];
      List<FlSpot> receivedData = [];

      int index = 0;
      for (var doc in transactions.docs) {
        final data = doc.data();
        final type = data['type'];
        final amount = data['amount'];

        if (amount != null && (type == 'sent' || type == 'received')) {
          final amt = (amount is int) ? amount.toDouble() : amount;
          if (type == 'sent') {
            sent += amt;
            sentData.add(FlSpot(index.toDouble(), amt));
          } else {
            received += amt;
            receivedData.add(FlSpot(index.toDouble(), amt));
          }
          index++;
        }
      }

      setState(() {
        totalSent = sent;
        totalReceived = received;
        sentSpots = sentData;
        receivedSpots = receivedData;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching transactions: $e");
      setState(() => isLoading = false);
    }
  }

  Widget sectionHeader(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.cyanAccent, Colors.deepPurpleAccent],
            ).createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLineChart(List<FlSpot> spots, Color color) {
    final extendedSpots = List<FlSpot>.from(spots);

    if (spots.length == 1) {
      extendedSpots.insert(0, FlSpot(spots[0].x - 1, 0));
      extendedSpots.add(FlSpot(spots[0].x + 1, 0));
    } else if (spots.isEmpty) {
      extendedSpots.addAll([FlSpot(0, 0), FlSpot(1, 0)]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                spots: extendedSpots,
                barWidth: 3.5,
                color: color,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141416),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "TrackIt: Finance Dashboard",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader("Summary", Icons.analytics_outlined),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.black26],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(2, 6)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Expense", style: GoogleFonts.poppins(color: Colors.white60)),
                      const SizedBox(height: 5),
                      Text("Rs. ${totalSent.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Total Income", style: GoogleFonts.poppins(color: Colors.white60)),
                      const SizedBox(height: 5),
                      Text("Rs. ${totalReceived.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    ],
                  ),
                ],
              ),
            ),

            sectionHeader("Spending vs Income", Icons.pie_chart_rounded),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 60,
                    sectionsSpace: 4,
                    sections: (totalSent == 0 && totalReceived == 0)
                        ? [
                      PieChartSectionData(
                        value: 1,
                        color: Colors.grey,
                        title: 'No Data',
                        titleStyle: GoogleFonts.poppins(color: Colors.white),
                        radius: 70,
                      ),
                    ]
                        : [
                      PieChartSectionData(
                        value: totalSent,
                        color: Colors.deepPurpleAccent,
                        title: 'Expense\nRs.${totalSent.toStringAsFixed(0)}',
                        titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                        radius: 70,
                      ),
                      PieChartSectionData(
                        value: totalReceived,
                        color: Colors.greenAccent,
                        title: 'Income\nRs.${totalReceived.toStringAsFixed(0)}',
                        titleStyle: GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                        radius: 70,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            sectionHeader("Expense Trend", Icons.trending_down),
            const SizedBox(height: 10),
            buildLineChart(sentSpots, Colors.deepPurpleAccent),

            sectionHeader("Income Trend", Icons.trending_up),
            const SizedBox(height: 10),
            buildLineChart(receivedSpots, Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}
