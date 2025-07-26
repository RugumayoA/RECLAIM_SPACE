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
    await prefs.setString('lost_selectedCategory', selectedCategory);
    
    // Save all category-specific fields
    await prefs.setString('lost_selectedIDType', selectedIDType ?? '');
    await prefs.setString('lost_institution', institution ?? '');
    await prefs.setString('lost_name', name ?? '');
    await prefs.setString('lost_location', location ?? '');
    await prefs.setString('lost_estimatedAge', estimatedAge ?? '');
    await prefs.setString('lost_gender', gender ?? '');
    await prefs.setString('lost_description', description ?? '');
    
    // Electronics
    await prefs.setString('lost_deviceType', deviceType ?? '');
    await prefs.setString('lost_brandModel', brandModel ?? '');
    await prefs.setString('lost_color', color ?? '');
    await prefs.setString('lost_serialNumber', serialNumber ?? '');
    
    // Jewelry
    await prefs.setString('lost_jewelryType', jewelryType ?? '');
    await prefs.setString('lost_material', material ?? '');
    await prefs.setString('lost_jewelryBrand', jewelryBrand ?? '');
    await prefs.setString('lost_distinctiveFeatures', distinctiveFeatures ?? '');
    
    // Clothing
    await prefs.setString('lost_itemType', itemType ?? '');
    await prefs.setString('lost_clothingBrand', clothingBrand ?? '');
    await prefs.setString('lost_clothingColor', clothingColor ?? '');
    await prefs.setString('lost_size', size ?? '');
    
    // Documents
    await prefs.setString('lost_documentType', documentType ?? '');
    await prefs.setString('lost_issuingAuthority', issuingAuthority ?? '');
    await prefs.setString('lost_documentNumber', documentNumber ?? '');
    await prefs.setString('lost_expiryDate', expiryDate ?? '');
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCategory = prefs.getString('lost_selectedCategory') ?? 'ID';
      if (selectedCategory == '') selectedCategory = 'ID';
      
      // Load all category-specific fields
      selectedIDType = prefs.getString('lost_selectedIDType');
      if (selectedIDType == '') selectedIDType = null;
      institution = prefs.getString('lost_institution');
      name = prefs.getString('lost_name');
      location = prefs.getString('lost_location');
      estimatedAge = prefs.getString('lost_estimatedAge');
      gender = prefs.getString('lost_gender');
      description = prefs.getString('lost_description');
      
      // Electronics
      deviceType = prefs.getString('lost_deviceType');
      brandModel = prefs.getString('lost_brandModel');
      color = prefs.getString('lost_color');
      serialNumber = prefs.getString('lost_serialNumber');
      
      // Jewelry
      jewelryType = prefs.getString('lost_jewelryType');
      material = prefs.getString('lost_material');
      jewelryBrand = prefs.getString('lost_jewelryBrand');
      distinctiveFeatures = prefs.getString('lost_distinctiveFeatures');
      
      // Clothing
      itemType = prefs.getString('lost_itemType');
      clothingBrand = prefs.getString('lost_clothingBrand');
      clothingColor = prefs.getString('lost_clothingColor');
      size = prefs.getString('lost_size');
      
      // Documents
      documentType = prefs.getString('lost_documentType');
      issuingAuthority = prefs.getString('lost_issuingAuthority');
      documentNumber = prefs.getString('lost_documentNumber');
      expiryDate = prefs.getString('lost_expiryDate');
    });
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lost_selectedCategory');
    await prefs.remove('lost_selectedIDType');
    await prefs.remove('lost_institution');
    await prefs.remove('lost_name');
    await prefs.remove('lost_location');
    await prefs.remove('lost_estimatedAge');
    await prefs.remove('lost_gender');
    await prefs.remove('lost_description');
    
    // Electronics
    await prefs.remove('lost_deviceType');
    await prefs.remove('lost_brandModel');
    await prefs.remove('lost_color');
    await prefs.remove('lost_serialNumber');
    
    // Jewelry
    await prefs.remove('lost_jewelryType');
    await prefs.remove('lost_material');
    await prefs.remove('lost_jewelryBrand');
    await prefs.remove('lost_distinctiveFeatures');
    
    // Clothing
    await prefs.remove('lost_itemType');
    await prefs.remove('lost_clothingBrand');
    await prefs.remove('lost_clothingColor');
    await prefs.remove('lost_size');
    
    // Documents
    await prefs.remove('lost_documentType');
    await prefs.remove('lost_issuingAuthority');
    await prefs.remove('lost_documentNumber');
    await prefs.remove('lost_expiryDate');
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
        const SnackBar(content: Text('Please attach an image'))
      );
      return;
    }
    setState(() => _loading = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploading image...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    try {
      final imageResult = await uploadImageWithHash(imageFile);
      
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
          };
          break;
        case 'Person':
          details = {
            'name': name ?? '',
            'age': estimatedAge ?? '',
            'gender': gender ?? '',
            'location': location ?? '',
            'description': description ?? '',
          };
          break;
        case 'Electronics':
          details = {
            'deviceType': deviceType ?? '',
            'brandModel': brandModel ?? '',
            'color': color ?? '',
            'serialNumber': serialNumber ?? '',
            'location': location ?? '',
          };
          break;
        case 'Jewelry & Watches':
          details = {
            'jewelryType': jewelryType ?? '',
            'material': material ?? '',
            'brand': jewelryBrand ?? '',
            'distinctiveFeatures': distinctiveFeatures ?? '',
            'location': location ?? '',
          };
          break;
        case 'Clothing & Bags':
          details = {
            'itemType': itemType ?? '',
            'brand': clothingBrand ?? '',
            'color': clothingColor ?? '',
            'size': size ?? '',
            'location': location ?? '',
          };
          break;
        case 'Documents':
          details = {
            'documentType': documentType ?? '',
            'issuingAuthority': issuingAuthority ?? '',
            'documentNumber': documentNumber ?? '',
            'expiryDate': expiryDate ?? '',
            'location': location ?? '',
          };
          break;
        case 'Other':
          details = {
            'description': description ?? '',
            'location': location ?? '',
          };
          break;
      }
      
      await PostLostService.uploadLostPost(
        type: selectedCategory,
        subType: selectedIDType,
        institution: institution,
        details: details,
        imageUrl: imageResult['url']!,
        imageHash: imageResult['hash']!,
      );
      await clearDraft();
      setState(() => _loading = false);
      if (!mounted) return;

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
        SnackBar(content: Text('Error: ${e.toString()}'))
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
                  const Text(
                    'What type of item is lost?',
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
                  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick from Gallery'),
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
            labelText: 'Name',
            labelStyle: TextStyle(color: Colors.white),
          ),
          validator: (val) => (val == null || val.isEmpty)
              ? 'Please enter the name'
              : null,
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
            location = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Where (Optional)',
            labelStyle: TextStyle(color: Colors.white),
          ),
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
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            location = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Last Known Location',
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
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            location = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Last Known Location',
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
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            location = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Last Known Location',
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
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            location = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Last Known Location',
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
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (val) {
            location = val;
            saveDraft();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Last Known Location',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
