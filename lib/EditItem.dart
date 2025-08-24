import 'dart:convert';
import 'package:chitraowner/Tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ApiManagment/ProductApi.dart';
import 'package:get/get.dart';
import 'dart:html' as html;
import 'AddVariation.dart';
import 'GetXmodels/ItemModel.dart';
import 'HomePage.dart';
import "package:product_personaliser/product_personaliser.dart";

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EditItem extends StatefulWidget {
  final String itemId;
  final String? productId;
  EditItem({required this.itemId, this.productId = 'NULL'});

  @override
  _EditState createState() => _EditState();
}

class _EditState extends State<EditItem> {
  // Controllers and state variables (keep your existing declarations)
  final HomepageController Homecontroller = Get.put(HomepageController());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _finaltagController = TextEditingController();
  List<String> _selectedVariationOpIds = [];
  TextEditingController _searchtagNameController = TextEditingController();

  bool isEditing = false;
  DesignTemplate? _selectedTemplate;
  String? _selectedDescriptionId;
  List<Map<String, dynamic>> searchResults = [];
  String? _image;
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _variationop = [];
  int? _selectedVariationIndx;
  int? _selectedVariationOpIndx;
  List<Map<String, dynamic>> _selectedVariations = [];
  late ItemController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ItemController(widget.itemId), tag: widget.itemId.toString());
    _addData();
    ever(controller.item, (_) => _addData());
  }

  // Keep all your existing methods (_addData, _selectDescription, _addNewImage, etc.)
  void _addData(){
    if(controller.item.value!=null){
      final item = controller.item.value!;
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _discountController.text = item.discount.toString();
      _qtyController.text = item.stockQuantity.toString();
      _descriptionController.text = item.description??'';
      _finaltagController.text = item.tagName??'';
      _selectedDescriptionId = item.discId;
      _selectedTemplate=item.template;
      _image = item.displayImg;
      _images = item.images ?? [];
      if (item.variations != null) {
        for (var t in item.variations!) {
          final String name = t['variation_name'];
          final List<dynamic> options = t['options'] ?? [];

          for (var op in options) {
            _selectedVariationOpIds.add(op['id']);
            _selectedVariations.add({
              'id': op['id'],
              'variation_name': name,
              'value': op['value'],
            });
          }
        }
      }
      //print(_selectedVariations);
    }
  }

  void _selectDescription() async {

    Future<void> performSearch() async {
      final String tag = _searchtagNameController.text.trim()??'';
      Homecontroller.isDescriptionLoading.value=true;
      if(Homecontroller.descriptionList.value==null){
        await Homecontroller.searchDescriptions();
      }
      final descriptionList=Homecontroller.descriptionList.value!;
      if (tag.isEmpty) {
        searchResults=descriptionList; // Reset to full list
      } else {
        searchResults=descriptionList
            .where((description) => description['tag_name'].toLowerCase().contains(tag))
            .toList();
      }
      Homecontroller.isDescriptionLoading.value=false;
    }
    performSearch();
    showDialog(
      context: context,
      builder: (context) {
        return Obx((){
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Search Description'),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min, // Ensure the dialog fits its content
              children: [
                TextField(
                    controller: _searchtagNameController,
                    decoration: InputDecoration(labelText: 'Enter Tag Name'),
                    onChanged:(value){
                      performSearch();
                    }
                ),
                SizedBox(height: 10),
                Text("Results: ${searchResults.length}"),
                Homecontroller.isDescriptionLoading.value
                    ? CircularProgressIndicator()
                    : searchResults.isEmpty
                    ? Text('No results found') // Show a message if no results
                    : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 500,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: searchResults.map((result) {
                        return result.containsKey('tag_name')?InkWell(
                          hoverColor: Colors.blueAccent.withOpacity(0.5),
                          onTap: () {
                            setState(() {
                              _selectedDescriptionId = result['id'];
                              _finaltagController.text = result['tag_name'];
                              _descriptionController.text = result['content'];
                            });
                            Navigator.pop(context);
                          },
                          child: Card(
                            child: Container(
                              margin: EdgeInsets.all(5),
                              alignment: Alignment.centerLeft,
                              width: double.infinity,
                              // color: Colors.blueAccent,
                              child: Text("${result['tag_name']}\n${result['content']}",
                                style: TextStyle(color: Colors.black),
                                maxLines: 3, // Limits to one line
                                overflow: TextOverflow.ellipsis, // Adds "..."
                              ),
                            ),
                          ),
                        ):Text('No Data');
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        );
      },
    ).then((_){
      setState(() {
        print(_finaltagController.text);
      });
    });
  }


  void _addNewImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = true; // Allow multiple image selection
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;
      final reader = html.FileReader();
      for (final file in files) {
        reader.readAsDataUrl(file);

        reader.onLoadEnd.listen((e) {
          setState(() {
            _images.add({'id': 'New', 'image_url': reader.result as String});
          });
        });
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _addVariationToList() {
    if (_selectedVariationIndx != null && _selectedVariationOpIndx != null) {
      final opId = _variationop[_selectedVariationOpIndx!]['id'];
      final variationName =  Homecontroller.variationList.value![_selectedVariationIndx!]['name'];
      final variationValue = _variationop[_selectedVariationOpIndx!]['value'];

      if(_selectedVariationOpIds.contains(opId)){
        Homepage.showOverlayMessage(context, 'Already Exist');
        return;
      }
      setState(() {
        _selectedVariations.add({
          'id': opId,
          'variation_name': variationName,
          'value': variationValue!,
        });
        _selectedVariationOpIds.add(opId);
      });
    } else {
      Homepage.showOverlayMessage(context,'Please select both a variation and its value');
    }
  }

  void _removeVariationFromList(int index) {
    setState(() {
      _selectedVariations.removeAt(index);
      _selectedVariationOpIds.removeAt(index);
    });
  }

  Future<void> _editItem() async {
    final String name = _nameController.text;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final int qty = int.tryParse(_qtyController.text) ?? 0;
    final String tagName = _finaltagController.text;
    if (name.isEmpty) {
      Homepage.showOverlayMessage(context, 'All fields and at least one variation are required!');
      return;
    }
    setState(() {
      isEditing=true;
    });
    bool success = await ItemApi.editItem(
      itemId: widget.itemId,
      name: name,
      productId: widget.productId,
      price: price,
      qty: qty,
      displayImg: _image != null ? _image!.split(',').last : null,
      variation_value_ids: _selectedVariationOpIds,
      description: _descriptionController.text,
      disc_id: _selectedDescriptionId,
      tag_name: tagName.length < 4 ? name : tagName,
      isImgChanged: _image != null,
      discount: double.tryParse(_discountController.text) ?? 0.0,
      t_id: _selectedTemplate?.id
    );

    if (success) {
      await Homecontroller.searchItems();
      Navigator.pop(context,'Done');
      Homepage.showOverlayMessage(context, 'Item edited successfully!');
      ItemApi.editItemImages(
        item_id: widget.itemId,
        images: _images,
      ).then((isSuccess) {
        if (isSuccess) {
          Homepage.showOverlayMessage(context,'Images edited successfully!');
        } else {
          Homepage.showOverlayMessage(context, 'Failed to edit images.');

        }
      });
      await controller.fetchItemDetails();
    } else {
      Homepage.showOverlayMessage(context, 'Failed to edit item. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product Item',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              // Add help functionality
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.item.value == null) {
          return Center(child: Text("Item not found", style: theme.textTheme.titleMedium));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: isEditing ? null : 0,
                backgroundColor: theme.colorScheme.surfaceVariant,
                minHeight: 2,
              ),
              const SizedBox(height: 16),

              // Main form
              _buildSectionCard(
                context,
                title: 'Basic Information',
                icon: Icons.info_outline,
                children: [
                  _buildModernTextField(
                    controller: _nameController,
                    label: 'Item Name*',
                    icon: Icons.shopping_bag,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _priceController,
                          label: 'Price*',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          isRequired: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModernTextField(
                          controller: _qtyController,
                          label: 'Quantity*',
                          icon: Icons.inventory,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _discountController,
                    label: 'Discount (%)',
                    icon: Icons.discount,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d{1,2}(\.\d{0,2})?$'))
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Variations Section
              _buildSectionCard(
                context,
                title: 'Variations',
                icon: Icons.layers_outlined,
                children: [
                  _buildVariationField(),
                  if (_selectedVariations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Selected Variations:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedVariations.asMap().entries.map((entry) {
                        int index = entry.key;
                        var variation = entry.value;
                        return Chip(
                          label: Text('${variation['variation_name']}: ${variation['value']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          deleteIcon: Icon(Icons.close, size: 16),
                          backgroundColor: theme.primaryColor,
                          onDeleted: () => _removeVariationFromList(index),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Description Section
              _buildSectionCard(
                context,
                title: 'Description',
                icon: Icons.description_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _finaltagController,
                          label: 'Description Tag',
                          icon: Icons.tag,
                          readOnly: _selectedDescriptionId != null,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: theme.primaryColor),
                        tooltip: 'Search descriptions',
                        onPressed: _selectDescription,
                      ),
                      if (_selectedDescriptionId != null)
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          tooltip: 'Edit description',
                          onPressed: () => setState(() => _selectedDescriptionId = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildModernTextField(
                    controller: _descriptionController,
                    label: 'Description Content',
                    icon: Icons.text_snippet,
                    maxLines: 3,
                    readOnly: _selectedDescriptionId != null,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Template Section
              _buildSectionCard(
                context,
                title: 'Design Template',
                icon: Icons.design_services,
                children: [
                  if (_selectedTemplate != null)
                    _buildTemplateCard(context, _selectedTemplate!)
                  else
                    FilledButton.icon(
                      icon: Icon(Icons.add, size: 20),
                      label: Text('Add Template'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      onPressed: () {
                        Helper.selectTemplate(context, onTap: (template) {
                          setState(() => _selectedTemplate = template);
                        });
                      },
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Images Section
              _buildSectionCard(
                context,
                title: 'Product Images',
                icon: Icons.photo_library_outlined,
                children: [
                  Text('Add high-quality images of your product',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ..._images.map((image) => _buildImageThumbnail(image)),
                      _buildImageUploadButton(context),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Save Button
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _editItem,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isEditing
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text('Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVariationField() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() {
                return DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Variation Type',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  value: _selectedVariationIndx,
                  hint: Text('Select variation'),
                  items: (Homecontroller.variationList.value ?? [])
                      .asMap()
                      .entries
                      .where((entry) => entry.value.containsKey('name'))
                      .map((entry) {
                    int index = entry.key;
                    var variation = entry.value;
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(variation['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVariationIndx = value;
                      _variationop = List<Map<String, dynamic>>.from(
                        Homecontroller.variationList.value![value!]['options'] ?? [],
                      );
                      _selectedVariationOpIndx = null;
                    });
                  },
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Variation Value',
                  prefixIcon: Icon(Icons.list_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                ),
                value: _selectedVariationOpIndx,
                hint: Text('Select value'),
                items: _variationop.asMap().entries.map((entry) {
                  int index = entry.key;
                  var option = entry.value;
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(option['value']),
                  );
                }).toList(),
                onChanged: (index) {
                  setState(() {
                    _selectedVariationOpIndx = index;
                    _addVariationToList();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            icon: Icon(Icons.add, size: 18),
            label: Text('Add Variation'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: _addVariationToList,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, {
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.primaryColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 2,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool isRequired = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: isRequired ? '$label*' : label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        filled: readOnly,
        fillColor: readOnly ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : null,
      ),
      style: theme.textTheme.bodyMedium,
    );
  }

  Widget _buildTemplateCard(BuildContext context, DesignTemplate template) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.design_services, color: theme.primaryColor),
        ),
        title: Text(
          template.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          "${template.pages.length} pages • ID: ${template.id ?? 'N/A'}",
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.visibility_outlined, size: 20),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.9,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: ProductDesigner(template: template),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20),
              color: theme.colorScheme.error,
              onPressed: () => setState(() => _selectedTemplate = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(Map<String, dynamic> image) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
            image: DecorationImage(
              image: NetworkImage(image['image_url']),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _removeImage(_images.indexOf(image)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.close, size: 16, color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Material(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _images.remove(image);
                  _images.insert(0, image);
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.arrow_upward, size: 16, 
                  color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Tooltip(
      message: 'Upload images (max 10)',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _addNewImage,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, 
                size: 30, 
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 4),
              Text('Add Images', 
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Keep all your existing methods (_addVariationToList, _removeVariationFromList, 
  // _addNewImage, _editItem, _selectDescription, etc.) unchanged
}

