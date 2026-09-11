import 'package:flutter/material.dart';
import 'legal_data.dart';
import 'legal_detail_screen.dart';

class LegalGuideScreen extends StatefulWidget {
  const LegalGuideScreen({super.key});

  @override
  State<LegalGuideScreen> createState() => _LegalGuideScreenState();
}

class _LegalGuideScreenState extends State<LegalGuideScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredList = legalGuidelines.where((item) {
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.actSection.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Legal Guide'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'වැරැද්දක් සොයන්න (Search offense)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.gavel, color: Colors.white),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.actSection, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LegalDetailScreen(guideline: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
