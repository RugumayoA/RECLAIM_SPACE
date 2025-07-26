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
//import '../services/post_lost_firebase.dart'; // Added import for PostLostService

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
  
  // ID fields
  String? selectedIDType;
  String? institution;
  String? name;
  
  // Person fields
  String? estimatedAge;
  String? gender;
  String? description;
  String? location;
  
  // Electronics fields
  String? deviceType;
  String? brandModel;
  String? color;
  String? serialNumber;
  
  // Jewelry fields
  String? jewelryType;
  String? material;
  String? jewelryBrand;
  String? distinctiveFeatures;
  
  // Clothing fields
  String? itemType;
  String? clothingBrand;
  String? clothingColor;
  String? size;
  
  // Documents fields
  String? documentType;
  String? issuingAuthority;
  String? documentNumber;
  String? expiryDate;

  DateTime? foundDate;
  dynamic imageFile;
  bool _loading = false;

  // Category lists
  final List<String> categories = [
    'ID',
    'Person', 
    'Electronics',
    'Jewelry & Watches',
    'Clothing & Bags',
    'Documents',
    'Other'
  ];

  final List<String> idTypes = [
    'School ID',
    'National ID',
    'Employee ID',
    'Insurance ID',
    'Passport',
    'Foreigner/Refugee ID',
  ];

  final List<String> estimatedAges = [
    'Below 3',
    '3-7',
    '8-13',
    '14-20',
    '21-30',
    '31-45',
    'Above 46'
  ];

  final List<String> genders = ['Male', 'Female', 'Other'];

  // Electronics
  final List<String> deviceTypes = [
    'Phone',
    'Laptop',
    'Tablet',
    'Headphones',
    'Camera',
    'Watch',
    'Other'
  ];

  // Jewelry
  final List<String> jewelryTypes = [
    'Ring',
    'Necklace',
    'Watch',
    'Bracelet',
    'Earrings',
    'Other'
  ];

  final List<String> materials = [
    'Gold',
    'Silver',
    'Platinum',
    'Diamond',
    'Other'
  ];

  // Clothing
  final List<String> itemTypes = [
    'Jacket',
    'Bag',
    'Shoes',
    'Shirt',
    'Pants',
    'Hat',
    'Other'
  ];

  // Documents
  final List<String> documentTypes = [
    'Certificate',
    'Contract',
    'License',
    'Passport',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    loadDraft();
  }

  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('found_selectedCategory', selectedCategory);
    
    // Save all category-specific fields
    await prefs.setString('found_selectedIDType', selectedIDType ?? '');
    await prefs.setString('found_institution', institution ?? '');
    await prefs.setString('found_name', name ?? '');
    await prefs.setString('found_location', location ?? '');
    await prefs.setString('found_estimatedAge', estimatedAge ?? '');
    await prefs.setString('found_gender', gender ?? '');
    await prefs.setString('found_description', description ?? '');
    
    // Electronics
    await prefs.setString('found_deviceType', deviceType ?? '');
    await prefs.setString('found_brandModel', brandModel ?? '');
    await prefs.setString('found_color', color ?? '');
    await prefs.setString('found_serialNumber', serialNumber ?? '');
    
    // Jewelry
    await prefs.setString('found_jewelryType', jewelryType ?? '');
    await prefs.setString('found_material', material ?? '');
    await prefs.setString('found_jewelryBrand', jewelryBrand ?? '');
    await prefs.setString('found_distinctiveFeatures', distinctiveFeatures ?? '');
    
    // Clothing
    await prefs.setString('found_itemType', itemType ?? '');
    await prefs.setString('found_clothingBrand', clothingBrand ?? '');
    await prefs.setString('found_clothingColor', clothingColor ?? '');
    await prefs.setString('found_size', size ?? '');
    
    // Documents
    await prefs.setString('found_documentType', documentType ?? '');
    await prefs.setString('found_issuingAuthority', issuingAuthority ?? '');
    await prefs.setString('found_documentNumber', documentNumber ?? '');
    await prefs.setString('found_expiryDate', expiryDate ?? '');
    
    await prefs.setString(
      'found_foundDate',
      foundDate?.toIso8601String() ?? '',
    );
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCategory = prefs.getString('found_selectedCategory') ?? 'ID';
      if (selectedCategory == '') selectedCategory = 'ID';
      
      // Load all category-specific fields
      selectedIDType = prefs.getString('found_selectedIDType');
      if (selectedIDType == '') selectedIDType = null;
      institution = prefs.getString('found_institution');
      name = prefs.getString('found_name');
      location = prefs.getString('found_location');
      estimatedAge = prefs.getString('found_estimatedAge');
      gender = prefs.getString('found_gender');
      description = prefs.getString('found_description');
      
      // Electronics
      deviceType = prefs.getString('found_deviceType');
      brandModel = prefs.getString('found_brandModel');
      color = prefs.getString('found_color');
      serialNumber = prefs.getString('found_serialNumber');
      
      // Jewelry
      jewelryType = prefs.getString('found_jewelryType');
      material = prefs.getString('found_material');
      jewelryBrand = prefs.getString('found_jewelryBrand');
      distinctiveFeatures = prefs.getString('found_distinctiveFeatures');
      
      // Clothing
      itemType = prefs.getString('found_itemType');
      clothingBrand = prefs.getString('found_clothingBrand');
      clothingColor = prefs.getString('found_clothingColor');
      size = prefs.getString('found_size');
      
      // Documents
      documentType = prefs.getString('found_documentType');
      issuingAuthority = prefs.getString('found_issuingAuthority');
      documentNumber = prefs.getString('found_documentNumber');
      expiryDate = prefs.getString('found_expiryDate');
      
      final dateStr = prefs.getString('found_foundDate');
      foundDate = (dateStr != null && dateStr.isNotEmpty)
          ? DateTime.tryParse(dateStr)
          : null;
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
    await prefs.remove('found_estimatedAge');
    await prefs.remove('found_gender');
    
    // Electronics
    await prefs.remove('found_deviceType');
    await prefs.remove('found_brandModel');
    await prefs.remove('found_color');
    await prefs.remove('found_serialNumber');
    
    // Jewelry
    await prefs.remove('found_jewelryType');
    await prefs.remove('found_material');
    await prefs.remove('found_jewelryBrand');
    await prefs.remove('found_distinctiveFeatures');
    
    // Clothing
    await prefs.remove('found_itemType');
    await prefs.remove('found_clothingBrand');
    await prefs.remove('found_clothingColor');
    await prefs.remove('found_size');
    
    // Documents
    await prefs.remove('found_documentType');
    await prefs.remove('found_issuingAuthority');
    await prefs.remove('found_documentNumber');
    await prefs.remove('found_expiryDate');
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
      
      // Build details map based on category
      Map<String, dynamic> details = {};
      
      switch (selectedCategory) {
        case 'ID':
          details = {
            'name': name ?? '',
            'subType': selectedIDType ?? '',
            'institution': institution ?? '',
            'foundDate': foundDate?.toIso8601String() ?? '',
          };
          break;
        case 'Person':
          details = {
            'name': name ?? '',
            'age': estimatedAge ?? '',
            'gender': gender ?? '',
            'location': location ?? '',
            'description': description ?? '',
            'foundDate': foundDate?.toIso8601String() ?? '',
          };
          break;
        case 'Electronics':
          details = {
            'deviceType': deviceType ?? '',
            'brandModel': brandModel ?? '',
            'color': color ?? '',
            'serialNumber': serialNumber ?? '',
            'location': location ?? '',
            'foundDate': foundDate?.toIso8601String() ?? '',
          };
          break;
        case 'Jewelry & Watches':
          details = {
            'jewelryType': jewelryType ?? '',
            'material': material ?? '',
            'brand': jewelryBrand ?? '',
            'distinctiveFeatures': distinctiveFeatures ?? '',
            'location': location ?? '',
            'foundDate': foundDate?.toIso8601String() ?? '',
          };
          break;
        case 'Clothing & Bags':
          details = {
            'itemType': itemType ?? '',
            'brand': clothingBrand ?? '',
            'color': clothingColor ?? '',
            'size': size ?? '',
            'location': location ?? '',
            'foundDate': foundDate?.toIso8601String() ?? '',
          };
          break;
        case 'Documents':
          details = {
            'documentType': documentType ?? '',
            'issuingAuthority': issuingAuthority ?? '',
            'documentNumber': documentNumber ?? '',
            'expiryDate': expiryDate ?? '',
            'location': location ?? '',
            'foundDate': foundDate?.toIso8601String() ?? '',
          };
          break;
        case 'Other':
          details = {
            'description': description ?? '',
            'location': location ?? '',
            'foundDate': foundDate?.toIso8601String() ?? '',
          };
          break;
      }
      
      await PostFoundService.uploadFoundPost(
        type: selectedCategory,
        subType: selectedIDType,
        institution: institution,
        details: details,
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
                    value: categories.contains(selectedCategory) ? selectedCategory : 'ID',
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    dropdownColor: Colors.black,
                    onChanged: (val) {
                      setState(() => selectedCategory = val!);
                      saveDraft();
                    },
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  
                  // Category-specific form fields
                  _buildCategoryFields(),
                  
                  const SizedBox(height: 10),
                  TextFormField(
                    onChanged: (val) {
                      location = val;
                      saveDraft();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Where was it found?',
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

  Widget _buildCategoryFields() {
    switch (selectedCategory) {
      case 'ID':
        return _buildIDFields();
      case 'Person':
        return _buildPersonFields();
      case 'Electronics':
        return _buildElectronicsFields();
      case 'Jewelry & Watches':
        return _buildJewelryFields();
      case 'Clothing & Bags':
        return _buildClothingFields();
      case 'Documents':
        return _buildDocumentsFields();
      case 'Other':
        return _buildOtherFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIDFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select ID Type',
          style: TextStyle(color: Colors.white),
        ),
        DropdownButtonFormField<String>(
          value: selectedIDType != null && idTypes.contains(selectedIDType) ? selectedIDType : null,
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
      ],
    );
  }

  Widget _buildPersonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: estimatedAge != null && estimatedAges.contains(estimatedAge) ? estimatedAge : null,
          items: estimatedAges.map((ageGroup) {
            return DropdownMenuItem(
              value: ageGroup,
              child: Text(
                ageGroup,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => estimatedAge = val);
            saveDraft();
          },
          decoration: const InputDecoration(
            labelText: 'Estimated Age',
            labelStyle: TextStyle(color: Colors.white),
          ),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          validator: (val) => val == null || val.isEmpty
              ? 'Please select estimated age'
              : null,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: gender != null && genders.contains(gender) ? gender : null,
          items: genders.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Text(
                g,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => gender = val);
            saveDraft();
          },
          decoration: const InputDecoration(
            labelText: 'Gender',
            labelStyle: TextStyle(color: Colors.white),
          ),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          validator: (val) => val == null || val.isEmpty
              ? 'Please select gender'
              : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            description = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description / Distinguishing Features',
            labelStyle: TextStyle(color: Colors.white),
          ),
          validator: (val) => (val == null || val.isEmpty)
              ? 'Please enter a description'
              : null,
        ),
      ],
    );
  }

  Widget _buildElectronicsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: deviceType != null && deviceTypes.contains(deviceType) ? deviceType : null,
          items: deviceTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => deviceType = val);
            saveDraft();
          },
          decoration: const InputDecoration(
            labelText: 'Device Type',
            labelStyle: TextStyle(color: Colors.white),
          ),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          validator: (val) => val == null || val.isEmpty
              ? 'Please select device type'
              : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            brandModel = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Brand/Model',
            labelStyle: TextStyle(color: Colors.white),
          ),
          validator: (val) => (val == null || val.isEmpty)
              ? 'Please enter brand/model'
              : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            color = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Color',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            serialNumber = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Serial Number (Optional)',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildJewelryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: jewelryType != null && jewelryTypes.contains(jewelryType) ? jewelryType : null,
          items: jewelryTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => jewelryType = val);
            saveDraft();
          },
          decoration: const InputDecoration(
            labelText: 'Type',
            labelStyle: TextStyle(color: Colors.white),
          ),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          validator: (val) => val == null || val.isEmpty
              ? 'Please select jewelry type'
              : null,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: material != null && materials.contains(material) ? material : null,
          items: materials.map((mat) {
            return DropdownMenuItem(
              value: mat,
              child: Text(
                mat,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => material = val);
            saveDraft();
          },
          decoration: const InputDecoration(
            labelText: 'Material',
            labelStyle: TextStyle(color: Colors.white),
          ),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            jewelryBrand = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Brand',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            distinctiveFeatures = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Distinctive Features',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildClothingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: itemType != null && itemTypes.contains(itemType) ? itemType : null,
          items: itemTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => itemType = val);
            saveDraft();
          },
          decoration: const InputDecoration(
            labelText: 'Item Type',
            labelStyle: TextStyle(color: Colors.white),
          ),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          validator: (val) => val == null || val.isEmpty
              ? 'Please select item type'
              : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            clothingBrand = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Brand',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            clothingColor = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Color',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            size = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Size',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            distinctiveFeatures = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Distinctive Features',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: documentType != null && documentTypes.contains(documentType) ? documentType : null,
          items: documentTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => documentType = val);
            saveDraft();
          },
          decoration: const InputDecoration(
            labelText: 'Document Type',
            labelStyle: TextStyle(color: Colors.white),
          ),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          validator: (val) => val == null || val.isEmpty
              ? 'Please select document type'
              : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            issuingAuthority = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Issuing Authority',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            documentNumber = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Document Number',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            expiryDate = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Expiry Date',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          onChanged: (val) {
            description = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            labelStyle: TextStyle(color: Colors.white),
          ),
          validator: (val) => (val == null || val.isEmpty)
              ? 'Please enter a description'
              : null,
        ),
      ],
    );
  }
}
