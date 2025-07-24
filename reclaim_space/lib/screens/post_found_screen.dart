import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../services/image_upload_service.dart';
import 'notifications_screen.dart'; // Added import for NotificationsScreen
import '../services/post_found_firebase.dart';

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
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
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

  String? ageRange;
  String? gender;

  final List<String> idTypes = [
    'School ID',
    'National ID',
    'Employee ID',
    'Insurance ID',
    'Passport',
    'Foreigner/Refugee ID',
  ];

  @override
  void initState() {
    super.initState();
    loadDraft();
  }

  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('found_selectedCategory', selectedCategory);
    await prefs.setString('found_selectedIDType', selectedIDType ?? '');
    await prefs.setString('found_institution', institution ?? '');
    await prefs.setString('found_name', name ?? '');
    await prefs.setString('found_description', description ?? '');
    await prefs.setString('found_location', location ?? '');
    await prefs.setString(
      'found_foundDate',
      foundDate?.toIso8601String() ?? '',
    );
    await prefs.setString('found_ageRange', ageRange ?? '');
    await prefs.setString('found_gender', gender ?? '');
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCategory = prefs.getString('found_selectedCategory') ?? 'ID';
      if (selectedCategory == '') selectedCategory = 'ID';
      selectedIDType = prefs.getString('found_selectedIDType');
      if (selectedIDType == '') selectedIDType = null;
      institution = prefs.getString('found_institution');
      name = prefs.getString('found_name');
      description = prefs.getString('found_description');
      location = prefs.getString('found_location');
      final dateStr = prefs.getString('found_foundDate');
      foundDate = (dateStr != null && dateStr.isNotEmpty)
          ? DateTime.tryParse(dateStr)
          : null;
      ageRange = prefs.getString('found_ageRange');
      if (ageRange == '') ageRange = null;
      gender = prefs.getString('found_gender');
      if (gender == '') gender = null;
    });
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('found_selectedCategory');
    await prefs.remove('found_selectedIDType');
    await prefs.remove('found_institution');
    await prefs.remove('found_name');
    await prefs.remove('found_description');
    await prefs.remove('found_location');
    await prefs.remove('found_foundDate');
    await prefs.remove('found_ageRange');
    await prefs.remove('found_gender');
  }

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

  Future<Map<String, String>> uploadImageWithHash(dynamic file) async {
    return await ImageUploadService.uploadImageWithHash(file);
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please attach an image')));
      return;
    }
    if (foundDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the date found')),
      );
      return;
    }
    setState(() => _loading = true);
    
    // Show initial loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploading image...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    try {
      final imageResult = await uploadImageWithHash(imageFile);
      
      // Show progress message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing your post...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      await PostLostService.uploadFoundPost(
        type: selectedCategory,
        subType: selectedIDType,
        institution: institution,
        details: {
          'name': name ?? '',
          'description': description ?? '',
          'location': location ?? '',
          'foundDate': foundDate?.toIso8601String() ?? '',
          'age': ageRange ?? '',
          'gender': gender ?? '',
        },
        imageUrl: imageResult['url'] ?? '',
        imageHash: imageResult['hash'] ?? '',
      );
      setState(() => _loading = false);
      if (!mounted) return;
      // Show a popup (Snackbar) with a button to go to notifications
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Found item posted! Check your notifications.'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            textColor: Colors.yellowAccent,
          ),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PostSuccessScreen(
            message:
                'Found item posted successfully! We will notify you if a match is found.',
          ),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
                  const Text(
                    'What type of item is found?',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: const [
                      DropdownMenuItem(
                        value: 'ID',
                        child: Text(
                          'ID',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Person',
                        child: Text(
                          'Person',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text(
                          'Other',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
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
                    const Text(
                      'Select ID Type',
                      style: TextStyle(color: Colors.white),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedIDType,
                      hint: const Text(
                        'Which type of ID?',
                        style: TextStyle(color: Colors.white),
                      ),
                      dropdownColor: Colors.black,
                      items: idTypes.map((id) {
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            id,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedIDType = val);
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please select ID type'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    if (selectedIDType == 'School ID' ||
                        selectedIDType == 'Employee ID') ...[
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
                        validator: (val) => (val == null || val.isEmpty)
                            ? 'This field is required'
                            : null,
                      ),
                    ],
                    TextFormField(
                      onChanged: (val) {
                        name = val;
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name on ID',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please enter the name on the ID'
                          : null,
                    ),
                  ] else if (selectedCategory == 'Person') ...[
                    TextFormField(
                      onChanged: (val) {
                        name = val;
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name (if known)',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please enter the name (if known)'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      onChanged: (val) {
                        description = val;
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description/Distinguishing Features',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please enter a description'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: ageRange,
                      items: const [
                        DropdownMenuItem(
                          value: 'Below 3',
                          child: Text('Below 3'),
                        ),
                        DropdownMenuItem(value: '3-7', child: Text('3-7')),
                        DropdownMenuItem(value: '8-13', child: Text('8-13')),
                        DropdownMenuItem(value: '14-20', child: Text('14-20')),
                        DropdownMenuItem(value: '21-30', child: Text('21-30')),
                        DropdownMenuItem(value: '31-45', child: Text('31-45')),
                        DropdownMenuItem(
                          value: 'Above 46',
                          child: Text('Above 46'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => ageRange = val);
                        saveDraft();
                      },
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Estimated Age',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please select estimated age'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Gender (Dropdown)
                    DropdownButtonFormField<String>(
                      value: gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                        DropdownMenuItem(
                          value: 'Prefer not to say',
                          child: Text('Prefer not to say'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => gender = val);
                        saveDraft();
                      },
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please select gender'
                          : null,
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    TextFormField(
                      onChanged: (val) {
                        description = val;
                        saveDraft();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Item Description',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please enter a description'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    onChanged: (val) {
                      location = val;
                      saveDraft();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Where was it/she/he found?',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Please enter the location'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Date Found:',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        foundDate == null
                            ? 'Select Date'
                            : foundDate!.toLocal().toString().split(' ')[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_today,
                          color: Colors.yellowAccent,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => foundDate = picked);
                            saveDraft();
                          }
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent,
                        ),
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
