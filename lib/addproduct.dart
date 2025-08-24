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
  final HomepageController homeController = Get.put(HomepageController());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _image;
  String _selectedType = 'Other';
  List<String> _types = ['Other', 'Man', 'Women', 'Unisex'];
  bool isActive = true;
  bool isNew = false;
  bool isPromotion = false;
  bool isSaving = false;

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final productId = await ProductApi.addProduct(
        name: _nameController.text.trim(),
        c_id: widget.categoryId,
        type: _selectedType,
        discount: _discountController.text.isNotEmpty 
            ? double.tryParse(_discountController.text) 
            : null,
        is_active: isActive,
        is_new: isNew,
        is_promotion: isPromotion,
      );

      if (productId != 'Error') {
        if (_image != null) {
          await ProductApi.addProductImage(
            product_id: productId,
            image: _image!.split(',').last,
          );
        }
        
        Homepage.showOverlayMessage(
          context, 
          'Product added successfully!',
          
        );
        await homeController.searchProducts();
        Navigator.pop(context, 'Done');
      } else {
        Homepage.showOverlayMessage(
          context, 
          'Failed to add product. Please try again.',
          
        );
      }
    } catch (e) {
      Homepage.showOverlayMessage(
        context, 
        'An error occurred. Please try again.',
       
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _pickImageWeb() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]!);
      reader.onLoadEnd.listen((e) {
        if (mounted) {
          setState(() => _image = reader.result as String?);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Product'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.shopping_bag),
                  
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Discount Field
              TextFormField(
                controller: _discountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                decoration: InputDecoration(
                  labelText: 'Discount Percentage',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.discount),
                  suffixText: '%',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                ),
              ),
              SizedBox(height: 20),

              // Toggle Options
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildCheckboxTile(
                        'Active Product',
                        'Show this product to customers',
                        isActive,
                        () => setState(() => isActive = !isActive),
                      ),
                      Divider(height: 1),
                      _buildCheckboxTile(
                        'Mark as New',
                        'Highlight as a new arrival',
                        isNew,
                        () => setState(() => isNew = !isNew),
                      ),
                      Divider(height: 1),
                      _buildCheckboxTile(
                        'Promotional Product',
                        'Feature in promotions',
                        isPromotion,
                        () => setState(() => isPromotion = !isPromotion),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Product Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Product Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                ),
                items: _types.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              SizedBox(height: 20),

              // Image Upload
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImageWeb,
                    icon: Icon(Icons.upload),
                    label: Text(_image == null ? 'Upload Product Image' : 'Change Image'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (_image != null) ...[
                    Stack(
                      children: [
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(_image!.split(',').last)),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: Icon(Icons.close, size: 18, color: Colors.red),
                            ),
                            onPressed: () => setState(() => _image = null),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),),
                  SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: isSaving ? null : _addProduct,
                      child: isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Add Product'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildCheckboxTile(String title, String subtitle, bool value, Function() onChanged) {
      return CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        value: value,
        onChanged:(_)=>onChanged(),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading, // Puts checkbox on the left
        
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Slightly rounded corners
        ),
        dense: true, // Reduces vertical padding
      );
    }
  }