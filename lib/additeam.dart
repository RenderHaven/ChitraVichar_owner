import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ApiManagment/ProductApi.dart';
import 'dart:html' as html;
import 'AddVariation.dart';
import 'HomePage.dart';
import 'package:get/get.dart';
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
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _finaltagController = TextEditingController();
  TextEditingController _searchtagNameController = TextEditingController();

  final HomepageController Homecontroller = Get.put(HomepageController());
  bool isSaving=false;
  String? _selectedDescriptionId;
  List<Map<String, dynamic>> searchResults = [];
  List<String> _mockupImages = [];
  // List<Map<String, dynamic>> _variations = [];
  List<Map<String, dynamic>> _variationop = [];
  List<String> _selectedVariationOpIds = [];
  int? _selectedVariationIndx=null;
  int? _selectedVariationOpIndx=null;

  List<Map<String, String>> _selectedVariations = [];

  Future<List<Map<String, dynamic>>> _filterDescriptions(String tagName) async {
    if(Homecontroller.descriptionList.value==null){
      await Homecontroller.searchDescriptions();
    }
    final descriptionList=Homecontroller.descriptionList.value??[];
    if (tagName.isEmpty) {
      return descriptionList; // Reset to full list
    } else {
      return descriptionList
          .where((description) => description['tag_name'].toLowerCase().contains(tagName))
          .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    // _loadVariations();
  }

  void _addVariationToList() {
    if (_selectedVariationIndx != null && _selectedVariationOpIndx != null) {
      final opId = _variationop[_selectedVariationOpIndx!]['id'];
      final variationName = Homecontroller.variationList.value![_selectedVariationIndx!]['name'];
      final variationValue = _variationop[_selectedVariationOpIndx!]['value'];

      if(_selectedVariationOpIds.contains(opId)){
        Homepage.showOverlayMessage(context, 'Already Exist');
        return;
      }
      setState(() {
        _selectedVariations.add({
          'id': opId!,
          'variation_name': variationName,
          'value': variationValue!,
        });
        _selectedVariationOpIds.add(opId);
      });
    } else {
      Homepage.showOverlayMessage(context, 'Please select both a variation and its value');    }
  }

  void _removeVariationFromList(int index) {
    setState(() {
      _selectedVariations.removeAt(index);
      _selectedVariationOpIds.removeAt(index);
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
    final images=_mockupImages.map((image) => image.split(',').last).toList();
    if (name.isEmpty ) {
      Homepage.showOverlayMessage(context, 'All fields and at least one image are required!');
      return;
    }
    setState(() {
      isSaving=true;
    });
    String item_id = await ItemApi.addItem(
      name: name,
      price: price,
      qty: qty,
      disc_id: _selectedDescriptionId,
      productId: widget.productId,
      description: _descriptionController.text.trim(),
      tag_name: _finaltagController.text.isEmpty ? name : _finaltagController.text,
      variation_value_ids:_selectedVariationOpIds,
      discount: double.tryParse(_discountController.text) ?? 0.0
    );

    if (item_id!='ERROR') {
      Homepage.showOverlayMessage(context, 'Item added successfully!');
      await Homecontroller.searchItems();
      Navigator.pop(context,'Done');
      if(images.isNotEmpty){
        ItemApi.addItemImages(
          item_id: item_id,
          images: images,
        ).then((isSuccess) {
          if (isSuccess) {
            Homepage.showOverlayMessage(context, 'Images uploaded successfully!');
          } else {
            Homepage.showOverlayMessage(context, 'Failed to upload images.');
          }
        });
      }
    } else {
      Homepage.showOverlayMessage(context, 'Failed to add item. Please try again.');    }
    setState(() {
      isSaving=false;
    });
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10),
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
            ),
            SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              controller: _qtyController,
              decoration: InputDecoration(labelText: 'Quantity In Stock'),
            ),
            SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{1,2}(\.\d{0,2})?$')
                )
              ],
              controller: _discountController,
              decoration: InputDecoration(labelText: 'Discount'),
            ),
            SizedBox(height: 10),
            VariationField(),
            Divider(),
            DescriptionField(),
            Divider(),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: Colors.black
                  )
              ),
              padding: EdgeInsets.symmetric(horizontal: 20,vertical: 5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Images',style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18
                      ),),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _pickMockupImagesWeb,
                      ),
                    ],
                  ),
                  Divider(color: Colors.black,),
                  Wrap(
                    spacing: 2,
                    children: _mockupImages.map((mockup) {
                      return Stack(
                        children: [
                          Container(
                            decoration:BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(width: 1),
                            ),
                            padding: const EdgeInsets.all(10.0),
                            child: Image.memory(
                              base64Decode(mockup.split(',').last),
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top:0,
                            right:0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _mockupImages.remove(mockup);
                                });
                              },
                            ),
                          ),
                          Positioned(
                            bottom:0,
                            left:0,
                            child: IconButton(
                              icon: Icon(Icons.flip_to_front_sharp, color: Colors.blue),
                              onPressed: () {
                                setState(() {
                                  _mockupImages.remove(mockup); // Remove the mockup from the list
                                  _mockupImages.insert(0, mockup); // Insert the mockup at the front (index 0)
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addIteam,
              child: isSaving?CircularProgressIndicator():Text('Add Item'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget VariationField(){
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
              color: Colors.black
          )
      ),
      padding: EdgeInsets.symmetric(horizontal: 20,vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Obx((){
                return Expanded(
                  child: Homecontroller.isVariationLoading.value?Center(child: CircularProgressIndicator()):DropdownButton<int>(
                    onTap: (){
                      if(Homecontroller.variationList.value==null){
                        Homecontroller.searchVariations();
                      }
                    },
                    value: _selectedVariationIndx,
                    hint: Text('Name'),
                    items: (Homecontroller.variationList.value??[{'name':'no'}]).asMap().entries
                        .where((entry) => entry.value.containsKey('name')) // Ensure only valid variations are processed
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
                  ),
                );
              }),
              SizedBox(width: 10),
              Expanded(
                child: DropdownButton<int>(
                  value: _selectedVariationOpIndx,
                  hint: Text('Value'),
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
              // IconButton(
              //   icon: Icon(Icons.add),
              //   onPressed: _addVariationToList,
              // ),
            ],
          ),
          Wrap(
            spacing: 2,
            children: _selectedVariations.asMap().entries.map((entry) {
              int index = entry.key;
              var variation = entry.value;
              return Chip(
                label: Text('${variation['variation_name']} : ${variation['value']}'),
                deleteIcon: Icon(Icons.close),
                onDeleted: () => _removeVariationFromList(index),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget DescriptionField(){
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
              color: Colors.black
          )
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Description',style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18
              ),),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: _selectDescription,
              ),
            ],
          ),
          Divider(color: Colors.black,),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _finaltagController,
                  readOnly: _selectedDescriptionId != null, // Make field read-only if a description is selected
                  decoration: InputDecoration(labelText: 'DescriptionTag'),
                  maxLines: 1,
                ),
              ),
              IconButton(
                  icon: Icon(Icons.edit_outlined,color: _selectedDescriptionId==null?Colors.green:Colors.black,),
                  onPressed: (){
                    setState(() {
                      _selectedDescriptionId=null;
                    });
                  }
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  readOnly: _selectedDescriptionId != null, // Make field read-only if a description is selected
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}