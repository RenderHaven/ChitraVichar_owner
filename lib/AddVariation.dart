import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'HomePage.dart';

class AddVariationPage extends StatefulWidget {
  @override
  _AddVariationPageState createState() => _AddVariationPageState();
}

class _AddVariationPageState extends State<AddVariationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _optionsController = TextEditingController();
  final HomepageController controller = Get.put(HomepageController());
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _addVariation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final options = _optionsController.text.trim()
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    try {
      final url = Uri.parse('$apiUrl/variation/add_variation');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": apiKey,
        },
        body: json.encode({
          'name': name,
          'options': options,
          'discs': []
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        Homepage.showOverlayMessage(
          context, 
          'Variation added successfully! Name: ${responseData['name']}',
        );
        controller.searchVariations();
        Navigator.pop(context, 'Done');
      } else {
        Homepage.showOverlayMessage(
          context, 
          "Failed to add variation. Please try again.",
        );
      }
    } catch (e) {
      Homepage.showOverlayMessage(
        context, 
        "Network error occurred. Please check your connection.",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add New Variation',
              // style: Theme.of(context).textTheme.headline6?.copyWith(
              //       fontWeight: FontWeight.bold,
              //       color: Theme.of(context).colorScheme.primary,
              //     ),
            ),
            SizedBox(height: 24),
            
            // Variation Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Variation Name',
                hintText: 'Display::Identifier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.category),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a variation name';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            
            // Options Field
            TextFormField(
              controller: _optionsController,
              decoration: InputDecoration(
                labelText: 'Options',
                hintText: 'Comma-separated values (e.g., Red,Blue,Green)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.list),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                suffixIcon: IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Options Format'),
                        content: Text('Enter comma-separated values without spaces between them. Example: "Small,Medium,Large"'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter at least one option';
                }
                if (value.endsWith(',')) {
                  return 'Remove "," from end';
                }
                return null;
              },
            ),
            SizedBox(height: 8),
            Text(
              'Separate options with commas (no spaces)',
              style: TextStyle(fontSize: 10),
            ),
            SizedBox(height: 30),
            
            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _addVariation,
              style: ElevatedButton.styleFrom(
                
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Add Variation',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}