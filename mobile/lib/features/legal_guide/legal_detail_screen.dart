import 'package:flutter/material.dart';
import 'legal_data.dart';

class LegalDetailScreen extends StatelessWidget {
  final LegalGuideline guideline;

  const LegalDetailScreen({super.key, required this.guideline});

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('නීතිමය උපදෙස් (Legal Steps)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guideline.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guideline.actSection,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              guideline.description,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const Divider(height: 32, thickness: 1),

            _buildSectionTitle('මූලික පියවර (Initial Steps)', Icons.looks_one),
            _buildList(guideline.initialSteps),

            _buildSectionTitle('නඩු පැවරීම (Legal Actions)', Icons.gavel),
            _buildList(guideline.legalActionSteps),

            _buildSectionTitle('අවශ්‍ය සාක්ෂි (Evidence Required)', Icons.camera_alt),
            _buildList(guideline.evidenceRequired),
          ],
        ),
      ),
    );
  }
}
