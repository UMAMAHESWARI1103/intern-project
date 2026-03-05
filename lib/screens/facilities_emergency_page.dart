import 'package:flutter/material.dart';

class FacilitiesEmergencyPage extends StatelessWidget {
  const FacilitiesEmergencyPage({super.key});

  void _makePhoneCall(BuildContext context, String phoneNumber) {
    // Show a dialog with the phone number instead of launching dialer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call'),
        content: Text('Calling $phoneNumber'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFFF9933)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Facilities & Emergency'),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Contacts Section
          _buildSectionHeader('Emergency Contacts'),
          const SizedBox(height: 12),
          _buildEmergencyCard(
            context,
            'Temple Security',
            '📞 +91-9876543210',
            Icons.security,
            '+919876543210',
          ),
          _buildEmergencyCard(
            context,
            'Medical Emergency',
            '📞 +91-9876543211',
            Icons.local_hospital,
            '+919876543211',
          ),
          _buildEmergencyCard(
            context,
            'Police Helpline',
            '📞 100',
            Icons.local_police,
            '100',
          ),
          _buildEmergencyCard(
            context,
            'Ambulance',
            '📞 108',
            Icons.airport_shuttle,
            '108',
          ),

          const SizedBox(height: 24),

          // Temple Facilities Section
          _buildSectionHeader('Temple Facilities'),
          const SizedBox(height: 12),
          _buildFacilityCard(
            'Drinking Water',
            'Free drinking water available at multiple locations',
            Icons.water_drop,
          ),
          _buildFacilityCard(
            'Restrooms',
            'Clean washroom facilities available',
            Icons.wc,
          ),
          _buildFacilityCard(
            'Shoe Stand',
            'Free and paid shoe storage available',
            Icons.checkroom,
          ),
          _buildFacilityCard(
            'Wheelchair Access',
            'Wheelchair accessible entrances and ramps',
            Icons.accessible,
          ),
          _buildFacilityCard(
            'Parking',
            'Two-wheeler and four-wheeler parking available',
            Icons.local_parking,
          ),
          _buildFacilityCard(
            'ATM',
            'ATM available near temple entrance',
            Icons.atm,
          ),

          const SizedBox(height: 24),

          // Medical Facilities Section
          _buildSectionHeader('Medical Facilities'),
          const SizedBox(height: 12),
          _buildMedicalCard(
            'First Aid Center',
            'Near main entrance',
            'Open: 6 AM - 9 PM',
            Icons.medical_services,
          ),
          _buildMedicalCard(
            'Pharmacy',
            'Inside temple complex',
            'Open: 7 AM - 8 PM',
            Icons.local_pharmacy,
          ),

          const SizedBox(height: 24),

          // Other Services Section
          _buildSectionHeader('Other Services'),
          const SizedBox(height: 12),
          _buildServiceCard(
            'Prasadam Counter',
            'Fresh prasadam available daily',
            Icons.restaurant,
          ),
          _buildServiceCard(
            'Donation Counter',
            'Multiple payment options accepted',
            Icons.volunteer_activism,
          ),
          _buildServiceCard(
            'Information Desk',
            'Multilingual assistance available',
            Icons.info,
          ),
          _buildServiceCard(
            'Lost & Found',
            'Report or claim lost items',
            Icons.search,
          ),

          const SizedBox(height: 24),

          // Safety Guidelines
          _buildSectionHeader('Safety Guidelines'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9933)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSafetyPoint('Keep valuables safe and secure'),
                _buildSafetyPoint('Follow temple dress code'),
                _buildSafetyPoint('Do not leave children unattended'),
                _buildSafetyPoint('In case of emergency, contact temple security'),
                _buildSafetyPoint('Follow COVID-19 guidelines if applicable'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildEmergencyCard(
    BuildContext context,
    String title,
    String contact,
    IconData icon,
    String phoneNumber,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9933).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF9933), size: 28),
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
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(context, phoneNumber),
            icon: const Icon(Icons.phone),
            color: const Color(0xFFFF9933),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9933).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF9933), size: 28),
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
                    color: Colors.black,
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
        ],
      ),
    );
  }

  Widget _buildMedicalCard(
    String title,
    String location,
    String timing,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9933).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF9933), size: 28),
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
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📍 $location',
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  '🕐 $timing',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: const Color(0xFFFF9933)),
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
                    color: Colors.black,
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
        ],
      ),
    );
  }

  Widget _buildSafetyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, color: Color(0xFFFF9933))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
