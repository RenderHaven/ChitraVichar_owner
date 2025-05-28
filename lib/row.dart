import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ApiManagment/ProductApi.dart';
import 'dart:html' as html;
import 'AddVariation.dart';
import 'HomePage.dart';

class AddIteam extends StatefulWidget {
  final String? productId;
  AddIteam({this.productId});

  @override
  _AddState createState() => _AddState();
}

class _AddState extends State<AddIteam> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _finaltagController = TextEditingController();
  TextEditingController _searchtagNameController = TextEditingController();

  String? _image;
  List<String> _mockupImages = [];

  Future<void> _pickImageWeb() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]!);

      reader.onLoadEnd.listen((e) {
        setState(() {
          _image = reader.result as String?;
        });
      });
    });
  }

  Future<void> _pickMockupImagesWeb() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = true; // Allow multiple image selection
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      for (final file in files) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);

        await reader.onLoadEnd.first; // Wait for the file to be read
        setState(() {
          _mockupImages.add(reader.result as String);
        });
      }
    });
  }

  Future<void> _addIteam() async {
    final String name = _nameController.text;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final int qty = int.tryParse(_qtyController.text) ?? 0;

    if (name.isEmpty || _image == null) {
      Homepage.showOverlayMessage(context, 'All fields and at least one image are required!');
      return;
    }

    String item_id = await ItemApi.addItem(
      name: name,
      price: price,
      qty: qty,
      productId: widget.productId,
      displayImg: _image != null ? _image!.split(',').last : null,
      description: _descriptionController.text,
      tag_name: _finaltagController.text.isEmpty ? name : _finaltagController.text,
    );

    if (item_id!='ERROR') {
      Homepage.showOverlayMessage(context, 'Item added successfully!');
      await ItemApi.addItemImages(item_id:item_id , images: _mockupImages.map((image) => image.split(',').last).toList());
      Navigator.pop(context);
    } else {
      Homepage.showOverlayMessage(context, 'Failed to add item. Please try again.');    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Item Name'),
          ),
          SizedBox(height: 10),
          TextField(
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
            controller: _priceController,
            decoration: InputDecoration(labelText: 'Price'),
          ),
          SizedBox(height: 10),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            controller: _qtyController,
            decoration: InputDecoration(labelText: 'Quantity In Stock'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickImageWeb,
            child: Text(_image == null ? 'Pick Main Image' : 'Change Main Image'),
          ),
          if (_image != null)
            Image.memory(
              base64Decode(_image!.split(',').last),
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickMockupImagesWeb,
            child: Text('Upload Mockups'),
          ),
          Wrap(
            children: _mockupImages.map((mockup) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Image.memory(
                      base64Decode(mockup.split(',').last),
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _mockupImages.remove(mockup);
                      });
                    },
                  ),
                ],
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addIteam,
            child: Text('Add Item'),
          ),
        ],
      ),
    );
  }
}
