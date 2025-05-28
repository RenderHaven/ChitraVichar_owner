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
  // final TextEditingController _discController = TextEditingController();
  final TextEditingController _optionsController = TextEditingController();
  final HomepageController controller = Get.put(HomepageController());
  bool _isLoading = false;

  Future<void> _addVariation() async {


    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final options = _optionsController.text.trim().split(',').map((value){return value;}).where((value) {return value.isNotEmpty;}).toList();

    if(name.isEmpty || options.isEmpty){
      return;
    }

    final url = Uri.parse('$apiUrl/variation/add_variation');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": '<@pap@a123>', // Security key always included
      },
      body: json.encode({
        'name': name,
        'options': options,
        'discs':[]
      }),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      Homepage.showOverlayMessage(context, 'Variation added successfully! Name: ${responseData['name']}');
      controller.searchVariations();
      Navigator.pop(context,'Done');
    } else {
      Homepage.showOverlayMessage(context, "Failed to add variation. Please try again.");
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Variation Name(Display::Identifier)'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a variation name';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _optionsController,
            decoration: InputDecoration(labelText: 'Options (comma-separated, no spaces)'),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')), // Disallow all spaces
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter at least one option';
              }
              if(value.endsWith(',')){
                return 'Remove "," from end';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _addVariation,
            child: Text('Add Variation'),
          ),
        ],
      ),
    );
  }
}
