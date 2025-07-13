import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../services/post_lost_firebase.dart';
import 'post_found_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PostLostScreen extends StatefulWidget {
  const PostLostScreen({super.key});

  @override
  State<PostLostScreen> createState() => _PostLostScreenState();
}

class _PostLostScreenState extends State<PostLostScreen> {
  final _formKey = GlobalKey<FormState>();
  String selectedCategory = 'ID'; // or 'Person'
  String? selectedIDType;
  String? institution;
  String? name;
  String? age;
  String? location;

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

  @override
  void initState() {
    super.initState();
    loadDraft();
  }

  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lost_selectedCategory', selectedCategory);
    await prefs.setString('lost_selectedIDType', selectedIDType ?? '');
    await prefs.setString('lost_institution', institution ?? '');
    await prefs.setString('lost_name', name ?? '');
    await prefs.setString('lost_age', age ?? '');
    await prefs.setString('lost_location', location ?? '');
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCategory = prefs.getString('lost_selectedCategory') ?? 'ID';
      if (selectedCategory == '') selectedCategory = 'ID';
      selectedIDType = prefs.getString('lost_selectedIDType');
      if (selectedIDType == '') selectedIDType = null;
      institution = prefs.getString('lost_institution');
      name = prefs.getString('lost_name');
      age = prefs.getString('lost_age');
      location = prefs.getString('lost_location');
    });
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lost_selectedCategory');
    await prefs.remove('lost_selectedIDType');
    await prefs.remove('lost_institution');
    await prefs.remove('lost_name');
    await prefs.remove('lost_age');
    await prefs.remove('lost_location');
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      if (kIsWeb) {
        imageFile = await picked.readAsBytes();
      } else {
        imageFile = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<Map<String, String>> uploadImageWithHash(dynamic file) async {
    return await ImageUploadService.uploadImageWithHash(file);
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach an image')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final imageResult = await uploadImageWithHash(imageFile);
      await PostLostService.uploadLostPost(
        type: selectedCategory,
        subType: selectedIDType,
        institution: institution,
        details: {
          'name': name ?? '',
          'age': age ?? '',
          'location': location ?? '',
        },
        imageUrl: imageResult['url']!,
        imageHash: imageResult['hash']!,
      );
      await clearDraft();
      setState(() => _loading = false);
      if (!mounted) return;
      /*
      // Fetch the latest lost item for this user
      final user = FirebaseAuth.instance.currentUser;
      final lostQuery = await FirebaseFirestore.instance
          .collection('lost_items')
          .where('uid', isEqualTo: user?.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (lostQuery.docs.isNotEmpty) {
        final lostDoc = lostQuery.docs.first;
        final lostData = lostDoc.data();
        if (lostData['matched'] == true && lostData['matchedWith'] != null) {
          // Fetch the matched found item
          final foundDoc = await FirebaseFirestore.instance
              .collection('found_items')
              .doc(lostData['matchedWith'])
              .get();
          final foundData = foundDoc.data();
          if (foundData != null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Match Found!'),
                content: Text('A found item matches your lost post!\n\nType: ${foundData['type']}\nSubType: ${foundData['subType'] ?? ''}\nInstitution: ${foundData['institution'] ?? ''}\nName: ${foundData['details']?['name'] ?? ''}'),
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
            message: 'Lost item posted successfully! We will notify you if a match is found.',
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
            title: const Text('Post Lost Item'),
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
                  const Text('What type of item is lost?', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: const [
                      DropdownMenuItem(value: 'ID', child: Text('ID', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Person', child: Text('Person', style: TextStyle(color: Colors.white))),
                    ],
                    dropdownColor: Colors.black,
                    onChanged: (val) {
                      setState(() => selectedCategory = val!);
                      saveDraft();
                    },
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
                      onChanged: (val) {
                        setState(() => selectedIDType = val);
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.isEmpty ? 'Please select ID type' : null,
                    ),
                    const SizedBox(height: 10),
                    if (selectedIDType == 'School ID' || selectedIDType == 'Employee ID') ...[
                      TextFormField(
                        onChanged: (val) {
                          institution = val;
                          saveDraft();
                        },
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
                  ] else ...[
                    TextFormField(
                      onChanged: (val) {
                        name = val;
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Please enter the name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      onChanged: (val) {
                        age = val;
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Please enter the age' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      onChanged: (val) {
                        location = val;
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Where (Optional)',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Please enter the location' : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick from Gallery'),
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
