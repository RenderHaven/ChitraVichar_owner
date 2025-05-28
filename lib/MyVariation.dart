import 'package:chitraowner/AddVariation.dart';
import 'package:chitraowner/HomePage.dart';
import 'package:flutter/material.dart';
import 'ApiManagment/ProductApi.dart'; // Make sure this API file is implemented// Ensure this page exists where users can add new variation
import 'package:get/get.dart';

class MyVariation extends StatefulWidget {
  @override
  _MyVariationState createState() => _MyVariationState();
}

class _MyVariationState extends State<MyVariation> {
  final TextEditingController _searchController = TextEditingController();

  final HomepageController controller = Get.put(HomepageController());
  String tag='';

  void initState(){
    super.initState();
    fetchData();
  }

  void fetchData()async{
    if(controller.variationList.value==null){
      await controller.searchVariations();
    }
    controller.variationSearchList.value = List.from(controller.variationList.value ?? []);
  }

  void _showVariationDetails(Map<String, dynamic> variation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:  Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(variation['name']),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(variation.containsKey('options'))for(var option in variation['options'])Text('${option['value']}  ${option['disc']??''}'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteVariation(variation['id']);
                    },
                    child: Text('Delete'),
                    style: ElevatedButton.styleFrom(),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editVariation(variation);
                    },
                    child: Text('Edit'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _filterVariation() {
    print('filtering for $tag');
    final variationList=controller.variationList.value??[];
    if (tag.isEmpty) {
      controller.variationSearchList.value = variationList; // Reset to full list
    } else {
      controller.variationSearchList.value = variationList
          .where((variation) => variation['name'].toLowerCase().contains(tag))
          .toList();
    }
  }


  void _editVariation(Map<String, dynamic> variation) {
    final TextEditingController nameController =
    TextEditingController(text: variation['name']);

    List<VariationOption> currentOptions = [];

    // Initialize controllers for existing options
    for (var option in variation['options']) {
      TextEditingController valueController = TextEditingController(text: option['value']);
      TextEditingController discController = TextEditingController(text: option['disc']);

      currentOptions.add(VariationOption(
        valueController: valueController,
        discController: discController,
        id: option['id'],
        value: option['value'],
        disc: option['disc'],
      ));
    }
    bool isEditing=false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Variation'),
                  IconButton(onPressed: () {
                    // Dispose all controllers before closing the dialog
                    for (var option in currentOptions) {
                      option.valueController.dispose();
                      option.discController.dispose();
                    }
                    nameController.dispose();
                    Navigator.pop(context);
                  }, icon: Icon(Icons.close))
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Variation Name Field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Variation Name(Display::Identifier)'),
                    ),
                    SizedBox(height: 10),

                    // Existing Options Fields
                    ...currentOptions.map((optionObject) {
                      return ListTile(
                        title: TextField(
                          controller: optionObject.valueController,
                          decoration: InputDecoration(labelText: 'Value'),
                        ),
                        subtitle:TextField(
                          controller: optionObject.discController,
                          decoration: InputDecoration(labelText: 'description'),
                        ) ,
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              // Dispose of the controller before removing the option
                              optionObject.valueController.dispose();
                              optionObject.discController.dispose();

                              currentOptions =
                                  currentOptions.where((o) => o != optionObject).toList();
                            });
                          },
                        ),
                      );
                    }).toList(),

                    // Button to add new options
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          TextEditingController valueController = TextEditingController();
                          TextEditingController discController = TextEditingController();
                          currentOptions = [
                            ...currentOptions,
                            VariationOption(valueController:valueController,discController: discController, id: 'New')
                          ];
                        });
                      },
                      child: Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if(isEditing)return;
                    final newName = nameController.text.trim();

                    if (newName.isEmpty || currentOptions.isEmpty) {
                      Homepage.showOverlayMessage(context, 'Variation name and at least one option are required');
                      return;
                    }

                    // Process and sanitize updated options
                    List<Map<String, dynamic>> updatedOptions = currentOptions.map((optionObject) {
                      String value = optionObject.valueController.text.trim();
                      String? disc = optionObject.discController.text.trim();
                      return {'id': optionObject.id, 'value': value, 'disc': disc};
                    }).toList();
                    setState((){
                      isEditing=true;
                    });
                    final result = await VariationApi.editVariation(
                      variation['id'],
                      newName,
                      updatedOptions,
                    );

                    if (result['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'])),
                      );
                      Navigator.pop(context);
                      await controller.searchVariations();
                      _filterVariation();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['error'])),
                      );
                    }
                    setState((){
                      isEditing=false;
                    });
                  },
                  child: isEditing?CircularProgressIndicator():Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  void _deleteVariation(String id) async {
    final result = await VariationApi.removeVariation(id);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      await controller.searchVariations();
      _filterVariation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    }
  }

  // Navigate to the page to add new variation
  void _addNewVariation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add New Variation'),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
            ],
          ),
          content: AddVariationPage(),
        );
      },
    ).then((value)async{
      _filterVariation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx((){return CircleAvatar(backgroundColor: Colors.blue, child: Text('${controller.variationSearchList.value?.length??'NA'}'));}),
      appBar: AppBar(
        title: Row(
          children: [
            Text('My Variations'),
            IconButton(onPressed:()=> controller.searchVariations(), icon: Icon(Icons.refresh))
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewVariation, // Open Add Variation page when tapped
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Variation Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: (){
                    tag=_searchController.text.toLowerCase()??'';
                    _filterVariation();
                  },
                ),
              ),
              // onSubmitted: (value) {
              //   // Trigger search when Enter is pressed
              //   _filterVariation();
              // },
              onChanged:(v){
                tag=_searchController.text.toLowerCase()??'';
                _filterVariation();
              },
            ),
            SizedBox(height: 20),
            Obx((){
              return controller.isVariationLoading.value
                  ? CircularProgressIndicator()
                  : Expanded(
                child: (controller.variationSearchList.value??[]).isNotEmpty?ListView.builder(
                  itemCount: controller.variationSearchList.value?.length??0,
                  itemBuilder: (context, index) {
                    final result = controller.variationSearchList.value?[index]??{};
                    return result.containsKey('name')?Card(
                      child: ListTile(
                        title: Text(result['name'] ?? 'Unknown'),
                        onTap: () {
                          _showVariationDetails(result);
                        }
                      ),
                    ):Text('NO DATA');
                  },
                ):Text('NO DATA'),
              );
            })
          ],
        ),
      ),
    );
  }
}

class VariationOption{
  TextEditingController valueController;
  TextEditingController discController;
  String id;
  String? value;
  String? disc;
  VariationOption({required this.valueController,required this.discController,this.id='New',this.disc,this.value});
}
