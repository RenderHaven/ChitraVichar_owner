import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'ApiManagment/ProductApi.dart';
import 'package:get/get.dart';
import 'HomePage.dart';
class AddProduct extends StatefulWidget {
  final String? categoryId;
  AddProduct({required this.categoryId});

  @override
  _AddProductState createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final HomepageController Homecontroller = Get.put(HomepageController());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  String? _image;
  String _selectedType = 'Other';
  List<String> _types = ['Other','Man', 'Women', 'Unisex'];
  bool isActive=true;
  bool isNew=false;
  bool isPromotion=false;
  bool isSaving=false;

  Future<void> _addProduct() async {
    final String name = _nameController.text;
    final String discount = _discountController.text;
    final image=_image?.split(',').last??'';
    if (name.isEmpty) {
      Homepage.showOverlayMessage(context, 'Product name required!');
      return;
    }
    setState(() {
      isSaving=true;
    });
    String productId = await ProductApi.addProduct(
      name: name,
      c_id: widget.categoryId,
      type: _selectedType,
      discount: discount.isNotEmpty ? double.tryParse(discount) : null,
      is_active: isActive,
      is_new: isNew,
      is_promotion: isPromotion,
    );

    if (productId!='Error') {
      Homepage.showOverlayMessage(context, 'Product added successfully!');
      if(image.isNotEmpty){
        ProductApi.addProductImage(
          product_id: productId,
          image: _image!.split(',').last,
        ).then((isSuccess) {
          if (isSuccess) {
            Homepage.showOverlayMessage(context, 'Images uploaded successfully!');
          } else {
            Homepage.showOverlayMessage(context, 'Failed to upload images.');
          }
        });
      }
      await Homecontroller.searchProducts();
      Navigator.pop(context,'Done');
    } else {
      Homepage.showOverlayMessage(context, 'Failed to add product. Please try again.');    }
    setState(() {
      isSaving=false;
    });
  }

  Future<void> _pickImageWeb() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*';
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Add Product'),
          IconButton(
              onPressed: ()=>setState(() {
                isNew=!isNew;
              }),
              icon: Icon(isNew?Icons.fiber_new_outlined:Icons.access_time,color: isNew?Colors.green:Colors.black,)
          ),
          IconButton(
              onPressed: ()=>setState(() {
                isActive=!isActive;
              }),
              icon: Icon(isActive?Icons.visibility:Icons.visibility_off,color: Colors.black,)
          ),

          IconButton(
              onPressed: ()=>Navigator.pop(context),
              icon: Icon(Icons.close,color: Colors.black,))

        ],
      ),
      content: AddProductPage(),
    );
  }

  Widget AddProductPage(){
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Product Name'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _discountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            decoration: InputDecoration(labelText: 'Discount'),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Promotional'),
              Checkbox(value: isPromotion, onChanged: (x){
                setState(() {
                  isPromotion=!isPromotion;
                });
              }),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SelectType'),
              DropdownButton<String>(
                value: _selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                items: _types.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickImageWeb,
            child: Text(_image == null ? 'Pick Image' : 'Change Image'),
          ),
          SizedBox(height: 10),
          _image != null
              ? Image.memory(
            base64Decode(_image!.split(',').last),
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          )
              : Container(),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addProduct,
            child: isSaving?CircularProgressIndicator():Text('Add Product'),
          ),
        ],
      ),
    );
  }
}
