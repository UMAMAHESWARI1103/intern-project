import 'package:flutter/material.dart';

class DosAndDontsPage extends StatelessWidget {
  const DosAndDontsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Do's and Don'ts"),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9933).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9933)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFF9933), size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please follow these guidelines for a peaceful temple visit',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DO's Section
          const Text(
            "✅ DO's",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),

          _buildDoCard(
            'Dress Code',
            'Wear traditional and modest clothing',
            Icons.checkroom,
          ),
          _buildDoCard(
            'Remove Footwear',
            'Remove shoes before entering the temple premises',
            Icons.loyalty,
          ),
          _buildDoCard(
            'Maintain Silence',
            'Keep your voice low and maintain peaceful environment',
            Icons.volume_off,
          ),
          _buildDoCard(
            'Personal Hygiene',
            'Wash hands and feet before entering',
            Icons.wash,
          ),
          _buildDoCard(
            'Queue Discipline',
            'Stand in proper queue and wait for your turn',
            Icons.group,
          ),
          _buildDoCard(
            'Photography Rules',
            'Follow temple photography guidelines',
            Icons.camera_alt,
          ),
          _buildDoCard(
            'Respect Others',
            'Be respectful to all devotees and priests',
            Icons.people,
          ),
          _buildDoCard(
            'Switch Off Phones',
            'Keep mobile phones on silent or switch off',
            Icons.phone_disabled,
          ),

          const SizedBox(height: 32),

          // DON'Ts Section
          const Text(
            "❌ DON'Ts",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),

          _buildDontCard(
            'No Smoking/Alcohol',
            'Strictly prohibited inside temple premises',
            Icons.smoke_free,
          ),
          _buildDontCard(
            'No Leather Items',
            'Avoid carrying leather bags, belts, or items',
            Icons.work_off,
          ),
          _buildDontCard(
            'No Outside Food',
            'Do not bring outside food or beverages',
            Icons.no_food,
          ),
          _buildDontCard(
            'No Littering',
            'Keep the temple premises clean',
            Icons.delete_outline,
          ),
          _buildDontCard(
            'No Running',
            'Walk slowly and carefully inside temple',
            Icons.directions_walk,
          ),
          _buildDontCard(
            'No Loud Music',
            'Avoid playing music or creating noise',
            Icons.music_off,
          ),
          _buildDontCard(
            'No Touching Idols',
            'Do not touch or climb on temple structures',
            Icons.pan_tool,
          ),
          _buildDontCard(
            'No Pets',
            'Pets are not allowed inside temple',
            Icons.pets,
          ),

          const SizedBox(height: 32),

          // Dress Code Guidelines
          const Text(
            "👔 Dress Code Guidelines",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9933)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.man, size: 32, color: Color(0xFFFF9933)),
                    SizedBox(width: 12),
                    Text(
                      'For Men',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDressPoint('Traditional dhoti and shirt'),
                _buildDressPoint('Kurta pajama'),
                _buildDressPoint('Full pants and shirt'),
                _buildDressPoint('Avoid shorts and sleeveless shirts'),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.woman, size: 32, color: Color(0xFFFF9933)),
                    SizedBox(width: 12),
                    Text(
                      'For Women',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDressPoint('Saree or salwar kameez'),
                _buildDressPoint('Traditional churidar'),
                _buildDressPoint('Long skirts with dupatta'),
                _buildDressPoint('Avoid western wear and short dresses'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Special Days Info
          const Text(
            "🎉 Special Days & Festivals",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpecialDayPoint('Extra crowding expected on festival days'),
                _buildSpecialDayPoint('Special darshan timings may be applicable'),
                _buildSpecialDayPoint('Advanced booking recommended'),
                _buildSpecialDayPoint('Additional security measures in place'),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDoCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
        color: Colors.green.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  Widget _buildDontCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
        color: Colors.red.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.cancel, color: Colors.red, size: 24),
        ],
      ),
    );
  }

  Widget _buildDressPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Color(0xFFFF9933), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialDayPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
