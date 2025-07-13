import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class PostStoryScreen extends StatefulWidget {
  final String postId;
  final String collection; // 'lost_items' or 'found_items'
  final String postType; // 'Lost' or 'Found'

  const PostStoryScreen({
    super.key,
    required this.postId,
    required this.collection,
    required this.postType,
  });

  @override
  State<PostStoryScreen> createState() => _PostStoryScreenState();
}

class _PostStoryScreenState extends State<PostStoryScreen> {
  bool _showInfo = true;
  bool _isLoading = true;
  Map<String, dynamic>? _postData;
  String? _userName;
  Timer? _autoDismissTimer;
  double _progress = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPostData();
    _hideInfoAfterDelay();
    _startAutoDismissTimer();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPostData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(widget.postId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (!mounted) return;
        setState(() {
          _postData = data;
          _isLoading = false;
        });

        // Load user name if available
        if (data['uid'] != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['uid'])
              .get();
          if (userDoc.exists) {
            if (!mounted) return;
            setState(() {
              _userName = userDoc.data()?['displayName'] ?? 'Unknown User';
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _hideInfoAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showInfo = false;
        });
      }
    });
  }

  void _startAutoDismissTimer() {
    _progress = 1.0;
    const totalDuration = Duration(seconds: 10);
    const updateInterval = Duration(milliseconds: 100);
    int totalSteps = totalDuration.inMilliseconds ~/ updateInterval.inMilliseconds;
    int currentStep = 0;

    _autoDismissTimer = Timer.periodic(updateInterval, (timer) {
      if (mounted) {
        currentStep++;
        setState(() {
          _progress = 1.0 - (currentStep / totalSteps);
        });

        if (currentStep >= totalSteps) {
          timer.cancel();
          Navigator.of(context).pop();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _resetAutoDismissTimer() {
    _autoDismissTimer?.cancel();
    _startAutoDismissTimer();
  }

  void _toggleInfo() {
    setState(() {
      _showInfo = !_showInfo;
    });
    if (_showInfo) {
      _hideInfoAfterDelay();
    }
    // Reset the auto-dismiss timer when user interacts
    _resetAutoDismissTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_postData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Post not found',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final imageUrl = _postData!['imageUrl'];
    final type = _postData!['type'] ?? '';
    final subType = _postData!['subType'] ?? '';
    final institution = _postData!['institution'] ?? '';
    final details = _postData!['details'] ?? {};
    final location = _postData!['location'] ?? '';
    final foundDate = _postData!['foundDate'] ?? '';
    final matched = _postData!['matched'] ?? false;
    final createdAt = _postData!['createdAt'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleInfo,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: imageUrl != null && imageUrl.toString().startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
            ),

            // Progress Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                ),
              ),
            ),

            // Top Info Bar
            if (_showInfo)
              Positioned(
                top: 3,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 47, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(204),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[800],
                        child: Icon(
                          widget.postType == 'Lost' ? Icons.search : Icons.find_in_page,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName ?? 'Unknown User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.postType,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (matched)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Matched',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Info Panel
            if (_showInfo)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(204),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type and SubType
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.yellowAccent.withAlpha(51),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.yellowAccent),
                            ),
                            child: Text(
                              type,
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (subType.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(51),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Text(
                                subType,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Institution
                      if (institution.isNotEmpty) ...[
                        _buildInfoRow('Institution', institution),
                        const SizedBox(height: 8),
                      ],

                      // Name (for Person type)
                      if (type == 'Person' && details['name'] != null) ...[
                        _buildInfoRow('Name', details['name']),
                        const SizedBox(height: 8),
                      ],

                      // Age (for Person type)
                      if (type == 'Person' && details['age'] != null) ...[
                        _buildInfoRow('Age', details['age']),
                        const SizedBox(height: 8),
                      ],

                      // Location
                      if (location.isNotEmpty) ...[
                        _buildInfoRow('Location', location),
                        const SizedBox(height: 8),
                      ],

                      // Found Date (for Found items)
                      if (widget.postType == 'Found' && foundDate.isNotEmpty) ...[
                        _buildInfoRow('Found Date', foundDate),
                        const SizedBox(height: 8),
                      ],

                      // Description
                      if (details['description'] != null && details['description'].isNotEmpty) ...[
                        _buildInfoRow('Description', details['description']),
                        const SizedBox(height: 8),
                      ],

                      // Created Date
                      if (createdAt != null) ...[
                        _buildInfoRow('Posted', _formatTimestamp(createdAt)),
                      ],
                    ],
                  ),
                ),
              ),


          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 