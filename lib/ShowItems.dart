import 'dart:convert';
import 'package:chitraowner/AddIteamsToProduct.dart';
import 'package:chitraowner/HomePage.dart';
import 'package:chitraowner/IteamView.dart';
import 'package:chitraowner/additeam.dart';
import 'package:flutter/material.dart';
import 'ApiManagment/ProductApi.dart';
import 'EditItem.dart';

class ShowItems extends StatefulWidget {
  String productId; // Category ID passed as a parameter

  // Constructor to accept the categoryId
  ShowItems({this.productId = 'Cat1'});

  @override
  State<ShowItems> createState() => _State();
}

class _State extends State<ShowItems> {
  List<Map<String, dynamic>> items_data = []; // List to store products
  bool isLoading = true; // Track loading state
  bool isShow=true;
  @override
  void initState() {
    super.initState();
    fetchIteams(); // Fetch products when the screen is loaded
  }

  // Function to fetch products by category
  Future<void> fetchIteams() async {
    setState(() {
      isLoading = true;
    });


    try{
      var response = await ProductApi.getItemsByProduct(widget.productId);
      setState(() {
        items_data=response;
        isLoading = false;
      });
    } catch(e) {
      setState(() {
        isLoading = false;
      });
      // Handle error here
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            height: 25,
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text("Items(${items_data.length})",style: TextStyle(fontWeight: FontWeight.bold),)
        ),
        if (isLoading)
          Center(child: CircularProgressIndicator()), // Show loading indicator
        if (!isLoading && items_data.isEmpty)
          Center(child: Text('No Item found')), // Show message if no items_data
        if (!isLoading && items_data.isNotEmpty)
          SizedBox(
            height: 500, // Set your max height here
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items_data.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3/2 // Adjust for card shape
              ),
              itemBuilder: (context, index) {
                return ItemCard(item: items_data[index]);
              },
            ),
          ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                clipBehavior: Clip.hardEdge,
                builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: AddItemsToProduct(productId: widget.productId,MyItemsId:items_data.map((d)=>d["i_id"].toString()).toList(),), // You can pass 'product' or 'item' based on the need
              );
            }
            ).then((_) {
              // This block will run when the dialog is popped
              fetchIteams(); // Re-fetch items_data after the dialog is closed
            });
          },
          icon: Icon(Icons.add),
        ),
      ],
    );
  }

  Widget ItemCard({
    required Map<String, dynamic> item,
  }) {
    String itemName = item['name'] ?? 'No name available';
    String itemImage = item['image_url']??"https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg?20200913095930";  // Default image if not available
    // Decode the product image if available
    Widget productImageWidget;
    if (itemImage.isNotEmpty) {
      try {
        productImageWidget=Image.network(itemImage);
      } catch (e) {
        productImageWidget = Icon(Icons.not_interested); // Fallback if image decoding fails
      }
    } else {
      productImageWidget = Icon(Icons.not_interested); // Fallback if no image
    }

    // Delete confirmation dialog
    Future<void> _showDeleteConfirmation(BuildContext context) async {
      bool confirm =isShow?await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Remove Item'),
            content: Text('Are you sure you want to remove this item?'),
            actions: [
              TextButton(onPressed:(){isShow=!isShow;}, child:Text("Don't show again"),),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Remove'),
              ),
            ],
          );
        },
      ) ?? false:true;

      if (confirm) {
        // Call delete function
        try {
          final x=await ProductApi.removeItemFromProduct(itemId: item['i_id'],productId: widget.productId!);
          if(x)Homepage.showOverlayMessage(context, 'Item removed successfully');
          else throw();
        } catch (e) {
          Homepage.showOverlayMessage(context, 'Failed to remove product: $e');
        }
      }
    }

    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ItemViewPage(itemId:item['i_id']))
          );
        },
        child: Container(
          // color: Colors.blue,
          width: 150,
          height: 200,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      child: productImageWidget,
                    ),
                    SizedBox(height: 10),
                    Text(
                      itemName,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Price: ${item['price']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: IconButton(
                  icon: Icon(Icons.remove, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(context).then((_){
                    fetchIteams();
                  }),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.edit_outlined),
                  onPressed: () {
                    showDialog(context: context,
                        builder: (context)=>AlertDialog(
                          contentPadding: EdgeInsets.all(5),
                          title: Text('Edit Item Data'),
                          content: EditItem(itemId: item['i_id'],),
                        )).then((v){
                        if(v=='Done')fetchIteams();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
