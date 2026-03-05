import 'package:flutter/material.dart';
import '../models/prayer.dart';
import '../services/api_service.dart';

class PrayersPage extends StatefulWidget {
  const PrayersPage({super.key});

  @override
  State<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage> {
  List<Prayer> _allPrayers = [];
  List<Prayer> _filtered   = [];
  bool         _isLoading  = true;
  String?      _error;
  String       _selectedCategory = 'All';

  static const List<String> _categories = ['All', 'Morning', 'Evening', 'Mantra'];

  @override
  void initState() {
    super.initState();
    _loadPrayers();
  }

  Future<void> _loadPrayers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ApiService.getAllPrayers();
      // Backend now always returns seed+DB merged
      final prayers = raw
          .map((e) => Prayer.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
        _allPrayers = prayers;
        _filtered   = prayers;
        _isLoading  = false;
      });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  void _filterByCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _filtered = cat == 'All'
          ? _allPrayers
          : _allPrayers.where((p) => p.category == cat).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayers & Mantras'),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPrayers),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selected,
                    selectedColor: const Color(0xFFFF9933),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => _filterByCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9933)));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPrayers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9933),
                foregroundColor: Colors.white),
          ),
        ]),
      );
    }
    if (_filtered.isEmpty) {
      return const Center(
          child: Text('No prayers found', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      color: const Color(0xFFFF9933),
      onRefresh: _loadPrayers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _buildPrayerCard(_filtered[i]),
      ),
    );
  }

  Widget _buildPrayerCard(Prayer prayer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9933)),
        color: Colors.white,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF9933).withValues(alpha: 0.15),
          ),
          child: const Center(child: Text('🙏', style: TextStyle(fontSize: 24))),
        ),
        title: Text(prayer.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Row(children: [
            _chip(prayer.category, const Color(0xFFFF9933)),
            const SizedBox(width: 6),
            _chip(prayer.language, Colors.blue),
            const SizedBox(width: 6),
            _chip('${prayer.durationMinutes} min', Colors.green),
          ]),
          if (prayer.deity.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Deity: ${prayer.deity}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ]),
        children: [
          if (prayer.lyrics.isNotEmpty) ...[
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Lyrics / Mantra',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9933).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(prayer.lyrics,
                  style: const TextStyle(
                      fontSize: 14, fontStyle: FontStyle.italic, height: 1.7)),
            ),
          ],
          if (prayer.meaning.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Meaning',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            Text(prayer.meaning,
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.6)),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
  );
}