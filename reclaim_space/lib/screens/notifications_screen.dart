import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isSelectionMode = false;
  Set<String> _selectedNotifications = {};

  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when screen opens
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Get all unread notifications
      final unreadNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .where('seen', isEqualTo: false)
          .get();

      // Mark each as read
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'seen': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc(notificationId)
          .update({'seen': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteSelectedNotifications() async {
    if (_selectedNotifications.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final notificationId in _selectedNotifications) {
        final docRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .doc(notificationId);
        batch.delete(docRef);
      }
      await batch.commit();
      
      setState(() {
        _selectedNotifications.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedNotifications.length} notification${_selectedNotifications.length == 1 ? '' : 's'} deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSingleNotification(String notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc(notificationId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNotifications.clear();
      }
    });
  }

  void _toggleNotificationSelection(String notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
      } else {
        _selectedNotifications.add(notificationId);
      }
    });
  }

  void _selectAllNotifications(List<QueryDocumentSnapshot> docs) {
    setState(() {
      if (_selectedNotifications.length == docs.length) {
        _selectedNotifications.clear();
      } else {
        _selectedNotifications = docs.map((doc) => doc.id).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Select Notifications' : 'Notifications'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (!_isSelectionMode) ...[
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.yellowAccent),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select notifications',
            ),
          ] else ...[
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(uid)
                  .collection('items')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final allSelected = _selectedNotifications.length == docs.length && docs.isNotEmpty;
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _selectAllNotifications(docs),
                      child: Text(
                        allSelected ? 'Deselect all' : 'Select all',
                        style: const TextStyle(color: Colors.yellowAccent),
                      ),
                    ),
                    if (_selectedNotifications.isNotEmpty)
                      TextButton(
                        onPressed: _deleteSelectedNotifications,
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _toggleSelectionMode,
                      tooltip: 'Cancel selection',
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No notifications yet.', style: TextStyle(color: Colors.white70)),
            );
          }

          // Check if all notifications are selected
          final allSelected = _selectedNotifications.length == docs.length && docs.isNotEmpty;

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['seen'] == true;
              final isSelected = _selectedNotifications.contains(doc.id);
              
              return ListTile(
                leading: _isSelectionMode
                    ? Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleNotificationSelection(doc.id),
                        activeColor: Colors.yellowAccent,
                      )
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isRead ? Colors.transparent : Colors.yellowAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                title: Text(
                  data['title'], 
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message'], 
                      style: TextStyle(
                        color: isRead ? Colors.white70 : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(data['timestamp']),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleNotificationSelection(doc.id);
                  } else if (!isRead) {
                    _markAsRead(doc.id);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _toggleSelectionMode();
                    _toggleNotificationSelection(doc.id);
                  }
                },
                tileColor: isSelected 
                    ? Colors.yellowAccent.withAlpha((255 * 0.2).toInt())
                    : (isRead ? null : Colors.grey[900]),
                trailing: _isSelectionMode
                    ? null
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white70),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteSingleNotification(doc.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
              );
            }).toList(),
          );
        },
      ),
      backgroundColor: Colors.black,
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
