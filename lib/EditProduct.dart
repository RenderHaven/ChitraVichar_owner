import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'ApiManagment/ProductApi.dart';
import 'package:get/get.dart';
import 'HomePage.dart';

class EditProduct extends StatefulWidget {
  final String productId;
  final dynamic productData;
  EditProduct({required this.productId, this.productData});

  @override
  _EditProductState createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  final HomepageController homeController = Get.put(HomepageController());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _image;
  String _selectedType = 'Other';
  List<String> _types = ['Other', 'Man', 'Women', 'Unisex'];
  bool isImgChanged = false;
  bool isActive = true;
  bool isNew = false;
  bool isSaving = false;
  bool isPromotion = false;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      final productData = widget.productData ?? 
          await ProductApi.getProductById(widget.productId);
      
      if (productData.containsKey('p_id')) {
        setState(() {
          _nameController.text = productData['name'] ?? '';
          _discountController.text = productData['discount']?.toString() ?? '';
          _selectedType = productData['type'] ?? 'Other';
          _image = productData['image_url'];
          isActive = productData['is_active'] ?? true;
          isNew = productData['is_new'] ?? false;
          isPromotion = productData['is_promotion'] ?? false;
        });
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      Homepage.showOverlayMessage(
        context, 
        'Failed to load product data',
       
      );
    }
  }

  Future<void> _editProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final isSuccess = await ProductApi.editProduct(
        productId: widget.productId,
        name: _nameController.text.trim(),
        type: _selectedType,
        discount: _discountController.text.isNotEmpty 
            ? double.tryParse(_discountController.text) 
            : null,
        is_active: isActive,
        is_new: isNew,
        is_promotion: isPromotion,
      );

      if (isSuccess) {
        if (isImgChanged && _image != null) {
          await ProductApi.addProductImage(
            product_id: widget.productId,
            image: _image!.split(',').last,
          );
        }
        
        Homepage.showOverlayMessage(
          context, 
          'Product updated successfully!',
         
        );
        await homeController.searchProducts();
        Navigator.pop(context, 'Done');
      } else {
        Homepage.showOverlayMessage(
          context, 
          'Failed to update product',
          
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
          setState(() {
            _image = reader.result as String?;
            isImgChanged = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Product',
                  // style: Theme.of(context).textTheme.headline6?.copyWith(
                  //       fontWeight: FontWeight.bold,
                  //     ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
        
            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
        
                  // Discount
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
                    ),
                  ),
                  SizedBox(height: 16),
        
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
                    ),
                    items: _types.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                  SizedBox(height: 24),
        
                  // Image Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImageWeb,
                        icon: Icon(Icons.upload),
                        label: Text(_image == null ? 'Upload New Image' : 'Change Image'),
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
                                  image: _image!.startsWith('http')
                                      ? NetworkImage(_image!)
                                      : MemoryImage(base64Decode(_image!.split(',').last)) as ImageProvider,
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
                                onPressed: () => setState(() {
                                  _image = null;
                                  isImgChanged = true;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 32),
        
                  // Update Button
                  FilledButton(
                    onPressed: isSaving ? null : _editProduct,
                    child: isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Update Product'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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