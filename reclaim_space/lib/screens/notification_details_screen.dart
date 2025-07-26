import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailsScreen({Key? key, required this.notification}) : super(key: key);

  Future<Map<String, dynamic>?> _fetchMatchedItems() async {
    // Try to get matched item info if available
    final String? foundItemId = notification['foundItemId'];
    final String? lostItemId = notification['lostItemId'];
    final String? type = notification['type'];
    
    if (type == 'match') {
      Map<String, dynamic> result = {};
      
      // Fetch found item if available
      if (foundItemId != null) {
        try {
          final foundDoc = await FirebaseFirestore.instance.collection('found_items').doc(foundItemId).get();
          if (foundDoc.exists) {
            result['foundItem'] = foundDoc.data();
          }
        } catch (e) {
          print('Error fetching found item: $e');
        }
      }
      
      // Fetch lost item if available
      if (lostItemId != null) {
        try {
          final lostDoc = await FirebaseFirestore.instance.collection('lost_items').doc(lostItemId).get();
          if (lostDoc.exists) {
            result['lostItem'] = lostDoc.data();
          }
        } catch (e) {
          print('Error fetching lost item: $e');
        }
      }
      
      return result.isNotEmpty ? result : null;
    }
    return null;
  }

  Widget _buildItemCard(String title, Map<String, dynamic> item, Color cardColor) {
    final imageUrl = item['imageUrl'] as String?;
    final details = item['details'] ?? {};
    final type = item['type'] ?? '';
    final subType = item['subType'] ?? '';
    final institution = item['institution'] ?? '';
    
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[700],
                        child: const Icon(Icons.image_not_supported, color: Colors.white70, size: 50),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _buildDetailRow('Type', type),
            if (subType.isNotEmpty) _buildDetailRow('Sub Type', subType),
            if (institution.isNotEmpty) _buildDetailRow('Institution', institution),
            ...details.entries.map((entry) => _buildDetailRow(entry.key, entry.value.toString())),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = notification['timestamp'] as Timestamp?;
    final date = timestamp != null ? timestamp.toDate() : null;
    final matchScore = notification['matchScore'] as double?;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification header
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification['message'] ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    if (date != null)
                      Text(
                        'Matched on: ${date.toLocal()}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    if (matchScore != null)
                      Text(
                        'Match Score: ${(matchScore * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Matched items
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchMatchedItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Card(
                    color: Colors.grey,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No match details available',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
                
                final items = snapshot.data!;
                final foundItem = items['foundItem'] as Map<String, dynamic>?;
                final lostItem = items['lostItem'] as Map<String, dynamic>?;
                
                return Column(
                  children: [
                    if (foundItem != null)
                      _buildItemCard('Found Item', foundItem, Colors.green[900]!),
                    if (lostItem != null)
                      _buildItemCard('Lost Item', lostItem, Colors.orange[900]!),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 