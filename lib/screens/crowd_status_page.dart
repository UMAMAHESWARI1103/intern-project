import 'package:flutter/material.dart';
import 'dart:math';

class CrowdStatusPage extends StatefulWidget {
  const CrowdStatusPage({super.key});

  @override
  State<CrowdStatusPage> createState() => _CrowdStatusPageState();
}

class _CrowdStatusPageState extends State<CrowdStatusPage> {
  final List<Map<String, dynamic>> temples = [
    {
      'name': 'Sri Kapaleeshwarar Temple',
      'location': 'Mylapore',
      'icon': '🛕',
      'currentCrowd': 'High',
      'percentage': 85,
      'waitTime': '45 mins',
      'peakHours': '6 AM - 10 AM',
      'color': Colors.red,
    },
    {
      'name': 'Sri Parthasarathy Temple',
      'location': 'Triplicane',
      'icon': '🕉️',
      'currentCrowd': 'Medium',
      'percentage': 55,
      'waitTime': '20 mins',
      'peakHours': '7 AM - 9 AM',
      'color': Colors.orange,
    },
    {
      'name': 'Vadapalani Murugan Temple',
      'location': 'Vadapalani',
      'icon': '🔱',
      'currentCrowd': 'Low',
      'percentage': 25,
      'waitTime': '5 mins',
      'peakHours': '6 PM - 8 PM',
      'color': Colors.green,
    },
    {
      'name': 'Ashtalakshmi Temple',
      'location': 'Besant Nagar',
      'icon': '🪷',
      'currentCrowd': 'Medium',
      'percentage': 60,
      'waitTime': '25 mins',
      'peakHours': '8 AM - 11 AM',
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Crowd Status'),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Simulate refresh
                for (var temple in temples) {
                  final random = Random();
                  temple['percentage'] = random.nextInt(100);
                  if (temple['percentage'] > 70) {
                    temple['currentCrowd'] = 'High';
                    temple['color'] = Colors.red;
                    temple['waitTime'] = '${40 + random.nextInt(30)} mins';
                  } else if (temple['percentage'] > 40) {
                    temple['currentCrowd'] = 'Medium';
                    temple['color'] = Colors.orange;
                    temple['waitTime'] = '${15 + random.nextInt(20)} mins';
                  } else {
                    temple['currentCrowd'] = 'Low';
                    temple['color'] = Colors.green;
                    temple['waitTime'] = '${5 + random.nextInt(10)} mins';
                  }
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crowd status updated'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9933).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9933)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFF9933)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live crowd monitoring helps you plan your visit better',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Low', Colors.green),
              _buildLegendItem('Medium', Colors.orange),
              _buildLegendItem('High', Colors.red),
            ],
          ),

          const SizedBox(height: 20),

          // Temple List
          ...temples.map((temple) => _buildCrowdCard(temple)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCrowdCard(Map<String, dynamic> temple) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                temple['icon'],
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temple['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '📍 ${temple['location']}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: temple['color'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  temple['currentCrowd'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Crowd Level',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${temple['percentage']}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: temple['percentage'] / 100,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(temple['color']),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Wait Time & Peak Hours
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time,
                  'Wait Time',
                  temple['waitTime'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  Icons.trending_up,
                  'Peak Hours',
                  temple['peakHours'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9933).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFFFF9933)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
