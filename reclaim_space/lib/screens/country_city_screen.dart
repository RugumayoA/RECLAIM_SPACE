import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'post_found_screen.dart';

class CountryCityScreen extends StatefulWidget {
  const CountryCityScreen({super.key});

  @override
  State<CountryCityScreen> createState() => _CountryCityScreenState();
}

class _CountryCityScreenState extends State<CountryCityScreen> {
  String? selectedCountry;
  final TextEditingController _cityController = TextEditingController();

  final List<Map<String, String>> countries = [
    {'name': 'Uganda', 'flag': '🇺🇬'},
    {'name': 'Kenya', 'flag': '🇰🇪'},
    {'name': 'Tanzania', 'flag': '🇹🇿'},
    {'name': 'Rwanda', 'flag': '🇷🇼'},
  ];

  Future<void> _submit() async {
    if (selectedCountry == null || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select country and enter city')),
      );
      return;
    }

    final permission = await Permission.location.request();

    if (permission.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostFoundScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Where Did You Find It?'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Select Country', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: countries.map((country) {
                return DropdownMenuItem(
                  value: country['name'],
                  child: Text('${country['flag']} ${country['name']}', style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedCountry = val),
              value: selectedCountry,
              hint: const Text('Choose Country', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'City',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellowAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Submit & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
