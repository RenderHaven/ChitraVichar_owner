import 'package:flutter/material.dart';
import 'ApiManagment/ProductApi.dart';
import 'EditItem.dart';
import 'GetXmodels/ItemModel.dart';
import 'HomePage.dart';
import 'dashboard.dart';
import 'package:get/get.dart';
class ItemViewPage extends StatefulWidget {
  final String itemId;

  const ItemViewPage({Key? key, required this.itemId}) : super(key: key);

  @override
  _ItemViewPageState createState() => _ItemViewPageState();
}

class _ItemViewPageState extends State<ItemViewPage> {
  String? selectedImage; // The image currently displayed as the big image
  late ItemController controller ;
  @override
  void initState() {
    super.initState();
    controller=Get.put(ItemController(widget.itemId), tag: widget.itemId.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Obx((){return
          Text(controller.item.value?.name ?? 'Item Details');
        }
        ),
      ),
      floatingActionButtonLocation:FloatingActionButtonLocation.endTop,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              onPressed: () async {
                if(controller.item.value==null)return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Delete'),
                    content: Text(
                        'Are you sure you want to delete this item?'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _deleteItem();
                }
              },
              icon:  CircleAvatar(child: Icon(Icons.delete_forever))
          ),
          IconButton(
            icon: CircleAvatar(child: Icon(Icons.edit)),
            onPressed: () {
              if(controller.item.value==null)return;
              showDialog(context: context,
                  builder: (context)=>AlertDialog(
                    contentPadding: EdgeInsets.all(5),
                    title: Text('Edit Item Data'),
                    content: EditItem(itemId: widget.itemId,),
                  )
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Visibility(
              visible: widget.itemId=='Lable',
              child: Container(
                padding: EdgeInsets.all(5),
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.blue.shade200,
                ),
                child: Text('Hii This is an special Item\nItem Mockups -> Banner/Lable on Site \nPrice -> Min Price For A Order'
                    '\nDescription-> Return Policy'

                ),
              ),
            ),
            Text(
              'Item Mockups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            imgSection(),
            SizedBox(height: 16),
            Text(
              'Item Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            buildDetailsSection(),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem() async {
    try {
      if(widget.itemId=='Lable'){
        Homepage.showOverlayMessage(context, 'Cant Delete Special Item');
        return;
      }
      final response = await ItemApi.deleteItemById(widget.itemId);
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }
      Get.delete<ItemController>(tag: widget.itemId);
      Homepage.showOverlayMessage(context, 'Item deleted successfully');
      Navigator.pop(context,'Done');
    } catch (e) {
      Homepage.showOverlayMessage(context, 'Failed to delete item: $e');    }
  }


  Widget buildDetailsSection() {
    return SingleChildScrollView(
      child: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final item = controller.item.value;

        if (item == null) {
          return Center(child: Text("Item details not available."));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // Pricing Section
            Text('${item.price}', style: TextStyle(fontSize: 16)),
            Text('${item.discount ?? "No Discount"} % OFF'),
            const SizedBox(height: 16),

            const Text(
              "Variations",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Divider(),
            const SizedBox(height: 8),
            tagBuilder(item.variations??[]),
            ExpansionTile(
              // expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Row(
                children: [
                  Icon(Icons.list_alt),
                  SizedBox(width: 5),
                  Text(
                    "Product Description",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item.description??''),
                ),
              ],
            ),
            Divider(),
            Text(
              'Associated Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            (item.associatedProducts==null && item.associatedProducts!.isEmpty)
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No associated products available.'),
            )
            : Wrap(
                spacing: 5,
                children: [
                  ...item.associatedProducts!.map((product){
                    return InkWell(
                      onTap:(){
                        final HomepageController Homecontroller = Get.put(HomepageController());
                        Homecontroller.selectedRoute.value='/dashboard';
                        Navigator.pushReplacement(context, MaterialPageRoute(builder:(context)=>Dashboard(productId:product['p_id']))).then((_)=>controller.fetchItemDetails());
                      },
                      child: Chip(
                        label:Text(product['name']),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    );
                  }),
                ],
            ),
          ],
        );
      }),
    );
  }

  Widget imgSection() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      final images = controller.item.value?.images ?? [];
      final hasImages = images.isNotEmpty;

      // If selectedImage is null, use the first image if available
      final imageUrl = selectedImage ?? (hasImages ? images[0]['image_url'] : null);

      return Column(
        children: [
          // Main Image Display
          Image.network(
            imageUrl ??
                "https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg?20200913095930",
            fit: BoxFit.cover,
            width: 500,
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Icon(Icons.broken_image, size: 50));
            },
          ),
          SizedBox(height: 16),

          // Image Thumbnails Row
          if (hasImages)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageUrl = images[index]['image_url'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImage = imageUrl;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedImage == imageUrl ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(child: Icon(Icons.broken_image, size: 50));
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
  Widget tagBuilder(List<Map<String,dynamic>> tags) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }


      return tags.isEmpty
          ? Center(child: Text("No variations available"))
          : Column(
        children: tags.map((entry) {
          String variationName = entry['variation_name']??'NA';
          List<dynamic> optionsList = entry['options']??[];

          print(variationName);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Variation Name (40% width)
                Expanded(
                  flex: 2,
                  child: Text(
                    variationName,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Options (60% width)
                Expanded(
                  flex: 6,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: optionsList
                        .map((tag) => Chip(
                      label: Text(tag['value'] ?? 'NA',
                          style: TextStyle(fontSize: 12)),
                      backgroundColor: Colors.blue.shade100,
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(), // Convert map() output to List
      );
    });
  }
}
