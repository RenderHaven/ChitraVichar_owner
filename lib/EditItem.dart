import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ApiManagment/ProductApi.dart';
import 'package:get/get.dart';
import 'dart:html' as html;
import 'AddVariation.dart';
import 'GetXmodels/ItemModel.dart';
import 'HomePage.dart';

class EditItem extends StatefulWidget {
  final String itemId;
  final String? productId;
  EditItem({required this.itemId, this.productId='NULL'});

  @override
  _EditState createState() => _EditState();
}

class _EditState extends State<EditItem> {
  final HomepageController Homecontroller = Get.put(HomepageController());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _finaltagController = TextEditingController();
  List<String> _selectedVariationOpIds = [];
  TextEditingController _searchtagNameController = TextEditingController();

  bool isEditing=false;

  String? _selectedDescriptionId;
  List<Map<String, dynamic>> searchResults = [];
  String? _image;
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _variationop = [];
  int? _selectedVariationIndx = null;
  int? _selectedVariationOpIndx = null;


  List<Map<String, dynamic>> _selectedVariations = [];
  late ItemController controller ;


  @override
  void initState() {
    super.initState();
    controller=Get.put(ItemController(widget.itemId), tag: widget.itemId.toString());
    _addData();
    ever(controller.item, (_) => _addData());
  }

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
      discount: double.tryParse(_discountController.text) ?? 0.0
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
    //final ItemController controller = Get.find<ItemController>(tag: widget.itemId);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }

            if (controller.item.value == null) {
              return Center(child: Text("Item not found"));
            }

            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    padding: EdgeInsets.all(20),
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
                              onPressed: _addNewImage,
                            ),
                          ],
                        ),
                        Divider(color: Colors.black,),
                        Wrap(
                          spacing: 2,
                          children: _images.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> image = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  decoration:BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(width: 1),
                                  ),
                                  padding: const EdgeInsets.all(10.0),
                                  child: Image.network(
                                    image['image_url'],
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _removeImage(index),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.flip_to_front_sharp, color: Colors.blue),
                                    onPressed: () {
                                      setState(() {
                                        _images.remove(image);
                                        _images.insert(0, image);
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
                  SizedBox(height: 10,),
                  isEditing?CircularProgressIndicator():
                  ElevatedButton(
                    onPressed: _editItem,
                    child:Text('Save Changes'),
                  ),
                  SizedBox(height: 10,),
                ],
              ),
            );
          }),
        ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Variations",style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18
              ),),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Add Variations'),
                            IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
                          ],
                        ),
                        content: AddVariationPage(),
                      );
                    },
                  );
                },
              )
            ],
          ),
          Divider(color: Colors.black,),
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
