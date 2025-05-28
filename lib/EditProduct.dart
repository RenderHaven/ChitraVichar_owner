import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'ApiManagment/ProductApi.dart';
import 'package:get/get.dart';
import 'HomePage.dart';
class EditProduct extends StatefulWidget {
  final String productId;
  var productData;
  EditProduct({required this.productId,this.productData=null});

  @override
  _EditProductState createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  final HomepageController Homecontroller = Get.put(HomepageController());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _finaltagController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
   List<Map<String, dynamic>> searchResults = [];
  String? _image;
  String _selectedType = 'Other';
  List<String> _types = ['Other', 'Man', 'Women', 'Unisex'];
  bool isImgChanged=false;
  bool isActive=true;
  bool isNew=false;
  bool isSaving=false;
  bool isPromotion=false;
  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    final productData = widget.productData==null?await ProductApi.getProductById(widget.productId):widget.productData;
    print(productData);
    if (productData.containsKey('p_id')) {
      setState(() {
        print(productData);
        _nameController.text = productData['name'] ?? '';
        _discountController.text = productData['discount']?.toString() ?? '';
        _selectedType = productData['type'] ?? 'Other';
        _image = productData['image_url'] ?? null;
        isActive = (productData['is_active'] is bool) ? productData['is_active'] : true;
        isNew = (productData['is_new'] is bool) ? productData['is_new'] : false;
        isPromotion = (productData['is_promotion'] is bool) ? productData['is_promotion'] : false;
      });
    }
    else {
      Navigator.pop(context);
    }
  }

  Future<void> _editProduct() async {
    final String name = _nameController.text;
    final String discount = _discountController.text;
    // final String tag_name = _finaltagController.text;
    final image = isImgChanged?_image?.split(',').last:null;

    if (name.isEmpty) {
      Homepage.showOverlayMessage(context, 'Product name is required!');
      return;
    }

    if (_descriptionController.text.length > 200) {
      Homepage.showOverlayMessage(context, 'Description should be less than 250 characters');
      return;
    }
    setState(() {
      isSaving=true;
    });
    bool isSuccess = await ProductApi.editProduct(
      productId: widget.productId,
      name: name,
      type: _selectedType,
      discount: discount.isNotEmpty ? double.tryParse(discount) : null,
      is_active: isActive,
      is_new: isNew,
      is_promotion: isPromotion
    );

    if (isSuccess) {
      Homepage.showOverlayMessage(context, 'Product updated successfully!');

      Homecontroller.searchProducts();
      Navigator.pop(context,'Done');

      if (image!=null && image.isNotEmpty) {
        ProductApi.addProductImage(
          product_id: widget.productId,
          image: image,
        ).then((isImageSuccess) {
          if (isImageSuccess) {
            Homepage.showOverlayMessage(context,'Image updated successfully!');
          } else {
            Homepage.showOverlayMessage(context,'Failed to update image.');
          }
        });
      }
    } else {
      Homepage.showOverlayMessage(context, 'Failed to update product. Please try again.');
    }
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
          isImgChanged=true;
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
            Text('Edit Product'),
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
      content: ProductEditPage()
    );
  }
  Widget ProductEditPage() {
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
              Text('Type'),
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
          ElevatedButton(
            onPressed: _pickImageWeb,
            child: Text(_image == null ? 'Pick Image' : 'Change Image'),
          ),
          SizedBox(height: 10),
          _image != null
              ? Image.network(
            _image!,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          )
              : Container(),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _editProduct,
            child: isSaving?CircularProgressIndicator():Text('Update Product'),
          ),
        ],
      ),
    );
  }
}
