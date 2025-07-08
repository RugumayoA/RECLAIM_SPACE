import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/post_lost_firebase.dart';

class PostLostScreen extends StatefulWidget {
  const PostLostScreen({super.key});

  @override
  State<PostLostScreen> createState() => _PostLostScreenState();
}

class _PostLostScreenState extends State<PostLostScreen> {
  String selectedCategory = 'ID'; // or 'Person'
  String? selectedIDType;
  String? institution;
  String? name;
  String? age;
  String? location;

  File? imageFile;
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
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  Future<String> uploadImage(File file) async {
    final fileName = 'lost_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('lost_images/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> submit() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach an image')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await uploadImage(imageFile!);

      await PostLostService.uploadLostPost(
        type: selectedCategory,
        subType: selectedIDType,
        institution: institution,
        details: {
          'name': name ?? '',
          'age': age ?? '',
          'location': location ?? '',
        },
        imageUrl: imageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lost item posted successfully!')),
      );

      Navigator.pop(context); // back to home or profile
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Lost Item'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What type of item is lost?', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedCategory,
              items: const [
                DropdownMenuItem(value: 'ID', child: Text('ID')),
                DropdownMenuItem(value: 'Person', child: Text('Person')),
              ],
              dropdownColor: Colors.black,
              onChanged: (val) => setState(() => selectedCategory = val!),
            ),
            const SizedBox(height: 20),

            if (selectedCategory == 'ID') ...[
              const Text('Select ID Type', style: TextStyle(color: Colors.white70)),
              DropdownButton<String>(
                value: selectedIDType,
                hint: const Text('Which type of ID?', style: TextStyle(color: Colors.white38)),
                dropdownColor: Colors.black,
                items: idTypes.map((id) {
                  return DropdownMenuItem(value: id, child: Text(id));
                }).toList(),
                onChanged: (val) => setState(() => selectedIDType = val),
              ),
              const SizedBox(height: 10),
              if (selectedIDType == 'School ID' || selectedIDType == 'Employee ID') ...[
                TextField(
                  onChanged: (val) => institution = val,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: selectedIDType == 'School ID'
                        ? 'Name of School/University'
                        : 'Employment Organisation',
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ] else ...[
              TextField(
                onChanged: (val) => name = val,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (val) => age = val,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Age',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (val) => location = val,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Where (Optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Attach Photo'),
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
                  : const Text('Post Lost'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellowAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
