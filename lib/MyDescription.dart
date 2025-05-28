import 'package:flutter/material.dart';
import 'ApiManagment/ProductApi.dart';
import 'package:get/get.dart';

import 'HomePage.dart';
class MyDescription extends StatefulWidget {
  @override
  _MyDescriptionState createState() => _MyDescriptionState();
}

class _MyDescriptionState extends State<MyDescription> {
  final TextEditingController _searchController = TextEditingController();
  final HomepageController controller = Get.put(HomepageController());

  String tag='';
  void initState(){
    super.initState();
    fetchData();
  }

  void fetchData()async{
    if(controller.descriptionList.value==null){
      await controller.searchDescriptions();
    }
    controller.descriptionSearchList.value = List.from(controller.descriptionList.value ?? []);
  }

  void _filterDescription() {
    print('filtering for $tag');
    final descriptionList=controller.descriptionList.value??[];
    if (tag.isEmpty) {
      controller.descriptionSearchList.value = descriptionList; // Reset to full list
    } else {
      controller.descriptionSearchList.value = descriptionList
          .where((description) => description['tag_name'].toLowerCase().contains(tag))
          .toList();
    }
  }
  
  void _addNewDescription() {
    final TextEditingController tagController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    bool isAdding=false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context,setState) {
            return AlertDialog(
              title:  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Description'),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tagController,
                    decoration: InputDecoration(labelText: 'Tag Name'),
                  ),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(labelText: 'Content'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if(isAdding)return;
                    final tagName = tagController.text.trim();
                    final content = contentController.text.trim();

                    if (tagName.isEmpty || content.isEmpty) {
                      Homepage.showOverlayMessage(context, 'Tag name and content cannot be empty');
                      return;
                    }
                    setState(() {
                      isAdding=true;
                    });
                    final result = await DescriptionApi.addDescription(
                      tag_name: tagName,
                      content: content,
                    );

                    if (result) {
                      Homepage.showOverlayMessage(context, "Added Description");
                      Navigator.pop(context);
                      await controller.searchDescriptions();
                      _filterDescription();
                    } else {
                      Homepage.showOverlayMessage(context, "Error to add");
                    }
                    setState(() {
                      isAdding=false;
                    });
                  },
                  child: isAdding?CircularProgressIndicator():Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showDescriptionDetails(Map<String, dynamic> description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:  Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(description['tag_name']),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
            ],
          ),
          content: Text(description['content']),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDescription(description['id']);
              },
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _editDescription(description);
              },
              child: Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  void _editDescription(Map<String, dynamic> description) {
    final TextEditingController tagController =
    TextEditingController(text: description['tag_name']);
    final TextEditingController contentController =
    TextEditingController(text: description['content']);
    bool isSaving=false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context,setState) {
            return AlertDialog(
              title:  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Description'),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tagController,
                    decoration: InputDecoration(labelText: 'Tag Name'),
                  ),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(labelText: 'Content'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if(isSaving)return;
                    final newTagName = tagController.text.trim();
                    final newContent = contentController.text.trim();

                    if (newTagName.isEmpty || newContent.isEmpty) {
                      Homepage.showOverlayMessage(context, 'Tag name and content cannot be empty');
                      return;
                    }
                    setState(() {
                      isSaving=true;
                    });
                    final result = await DescriptionApi.editDescription(
                      description['id'],
                      newTagName,
                      newContent,
                    );

                    if (result['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'])),
                      );
                      Navigator.pop(context);
                      await controller.searchDescriptions();
                      _filterDescription();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['error'])),
                      );
                    }
                    setState(() {
                      isSaving=false;
                    });
                  },
                  child: isSaving?CircularProgressIndicator():Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteDescription(String id) async {
    final result = await DescriptionApi.deleteDescription(id);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      await controller.searchDescriptions();
      _filterDescription();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx((){return CircleAvatar(backgroundColor: Colors.blue, child: Text('${controller.descriptionSearchList.value?.length??'NA'}'));}),
      appBar: AppBar(
        title:Row(
          children: [
            Text('My Descriptions'),
            IconButton(onPressed:()=>controller.searchDescriptions(), icon: Icon(Icons.refresh))
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewDescription,
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
                labelText: 'Search by Tag Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: (){
                    tag=_searchController.text.toLowerCase()??'';
                    _filterDescription();
                  },
                ),
              ),
              onChanged: (value) {
                tag=_searchController.text.toLowerCase()??'';
                _filterDescription();
              },
            ),
            SizedBox(height: 20),
            Obx((){
              return controller.isDescriptionLoading.value
                  ? CircularProgressIndicator()
                  : Expanded(
                child: (controller.descriptionSearchList.value??[]).isNotEmpty?ListView.builder(
                  itemCount: controller.descriptionSearchList.value?.length??0,
                  itemBuilder: (context, index) {
                    final result = controller.descriptionSearchList.value?[index]??{};
                    return result.containsKey('tag_name')?Card(
                      child: ListTile(
                          title: Text(result['tag_name'] ?? 'Unknown'),
                          onTap: () {
                            _showDescriptionDetails(result);
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
