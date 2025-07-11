import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/image_upload_service.dart';
import '../services/post_found_firebase.dart'; // Implement this service as needed
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class PostSuccessScreen extends StatelessWidget {
  final String message;
  const PostSuccessScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Return Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostFoundScreen extends StatefulWidget {
  const PostFoundScreen({super.key});

  @override
  State<PostFoundScreen> createState() => _PostFoundScreenState();
}

class _PostFoundScreenState extends State<PostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  String selectedCategory = 'ID';
  String? selectedIDType;
  String? institution;
  String? name;
  String? description;
  String? location;
  DateTime? foundDate;

  dynamic imageFile; // File (mobile) or Uint8List (web)
  bool _loading = false;

  final List<String> idTypes = [
    'School ID',
    'National ID',
    'Employee ID',
    'Insurance ID',
    'Passport',
    'Foreigner/Refugee ID'
  ];

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      if (kIsWeb) {
        imageFile = await picked.readAsBytes();
      } else {
        imageFile = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<String> uploadImage(dynamic file) async {
    return await ImageUploadService.uploadImage(file);
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach an image')),
      );
      return;
    }
    if (foundDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the date found')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final imageUrl = await uploadImage(imageFile);
      final user = FirebaseAuth.instance.currentUser;

      await PostFoundService.uploadFoundPost(
        type: selectedCategory,
        subType: selectedIDType,
        institution: institution,
        details: {
          'name': name ?? '',
          'description': description ?? '',
          'location': location ?? '',
        },
        imageUrl: imageUrl,
        location: location,
        foundDate: foundDate?.toIso8601String(),
      );

      setState(() => _loading = false);
      if (!mounted) return;
      /*
      // Fetch the latest found item for this user
      final user = FirebaseAuth.instance.currentUser;
      final foundQuery = await FirebaseFirestore.instance
          .collection('found_items')
          .where('uid', isEqualTo: user?.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (foundQuery.docs.isNotEmpty) {
        final foundDoc = foundQuery.docs.first;
        final foundData = foundDoc.data();
        if (foundData['matched'] == true && foundData['matchedWith'] != null) {
          // Fetch the matched lost item
          final lostDoc = await FirebaseFirestore.instance
              .collection('lost_items')
              .doc(foundData['matchedWith'])
              .get();
          final lostData = lostDoc.data();
          if (lostData != null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Match Found!'),
                content: Text('A lost item matches your found post!\n\nType: \\${lostData['type']}\nSubType: \\${lostData['subType'] ?? ''}\nInstitution: \\${lostData['institution'] ?? ''}\nName: \\${lostData['details']?['name'] ?? ''}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
      */
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PostSuccessScreen(
            message: 'Found item posted successfully! We will notify you if a match is found.',
          ),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Post Found Item'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          backgroundColor: Colors.black,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What type of item is found?', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: const [
                      DropdownMenuItem(value: 'ID', child: Text('ID', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Person', child: Text('Person', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Other', child: Text('Other', style: TextStyle(color: Colors.white))),
                    ],
                    dropdownColor: Colors.black,
                    onChanged: (val) => setState(() => selectedCategory = val!),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  if (selectedCategory == 'ID') ...[
                    const Text('Select ID Type', style: TextStyle(color: Colors.white)),
                    DropdownButtonFormField<String>(
                      value: selectedIDType,
                      hint: const Text('Which type of ID?', style: TextStyle(color: Colors.white)),
                      dropdownColor: Colors.black,
                      items: idTypes.map((id) {
                        return DropdownMenuItem(value: id, child: Text(id, style: const TextStyle(color: Colors.white)));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedIDType = val),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.isEmpty ? 'Please select ID type' : null,
                    ),
                    const SizedBox(height: 10),
                    if (selectedIDType == 'School ID' || selectedIDType == 'Employee ID') ...[
                      TextFormField(
                        onChanged: (val) => institution = val,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: selectedIDType == 'School ID'
                              ? 'Name of School/University'
                              : 'Employment Organisation',
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        validator: (val) => (val == null || val.isEmpty) ? 'This field is required' : null,
                      ),
                    ],
                    TextFormField(
                      onChanged: (val) => name = val,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name on ID (if visible)',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Please enter the name on ID (if visible)' : null,
                    ),
                  ] else if (selectedCategory == 'Person') ...[
                    TextFormField(
                      onChanged: (val) => name = val,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name (if known)',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Please enter the name (if known)' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      onChanged: (val) => description = val,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description/Distinguishing Features',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Please enter a description' : null,
                    ),
                  ] else ...[
                    TextFormField(
                      onChanged: (val) => description = val,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Item Description',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Please enter a description' : null,
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    onChanged: (val) => location = val,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Where was it found?',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'Please enter the location' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Date Found:', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 10),
                      Text(
                        foundDate == null ? 'Select Date' : foundDate!.toLocal().toString().split(' ')[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.yellowAccent),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => foundDate = picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellowAccent),
                      ),
                      const SizedBox(width: 10),
                      if (imageFile != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _loading ? null : submit,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('Post Found'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_loading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.yellowAccent),
            ),
          ),
      ],
    );
  }
} 