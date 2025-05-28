
import 'package:chitraowner/EditProduct.dart';
import 'package:chitraowner/HomePage.dart';
import 'package:flutter/material.dart';
import 'ApiManagment/ProductApi.dart';
import 'SearchProducts.dart';
import 'addproduct.dart';
import 'package:get/get.dart';
import 'dashboard.dart'; // Assuming AddProduct is a separate widget you defined

class Showproducts extends StatefulWidget {
  String? categoryId; // Category ID passed as a parameter
  String oldpath;
  Showproducts({this.categoryId = null,this.oldpath='New'});

  @override
  State<Showproducts> createState() => _State();
}

class _State extends State<Showproducts> {
  HomepageController homepageController=Get.put(HomepageController());
  // List<dynamic> products = []; // List to store products
  List<dynamic> products_data = []; // List to store products
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    fetchProducts(); // Fetch products when the screen is loaded
  }

  // Function to fetch products by category
  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    try{
      var response = await ProductApi.getProductsByCategory(widget.categoryId);
      setState(() {
        products_data = response;
        isLoading = false;
      });
      print(products_data);
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
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              "Products(${products_data.length})", style: TextStyle(fontWeight: FontWeight.bold),)
        ),
        if (isLoading)
          Center(child: CircularProgressIndicator()),
        // Show loading indicator
        if (!isLoading && products_data.isEmpty)
          Center(child: Text('No products found')),
        // Show message if no products
        if (!isLoading && products_data.isNotEmpty)
          SizedBox(
            height: 250,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var product in products_data)ProductCard(product: product),
              ],
            ),
          ),
        IconButton(
          onPressed: () {
            // Show AddProduct form as a popup (dialog)
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return  AddProduct(categoryId: widget.categoryId,);
              },
            ).then((value){
              if(value=='Done'){
                fetchProducts();
              }
            });
          },
          icon: Icon(Icons.add),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context,
      String? productId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Product', style: TextStyle(color: Colors.red),),
          content: Text(
              'Are you sure you want to Delete this Product?,\nNOTE:This Action Will Delete All Sub Products Too'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      // Call delete function
      try {
        if (productId == null) throw();
        final x = await ProductApi.removeProduct(productId);
        if (!x.containsKey('error')){
          Homepage.showOverlayMessage(context, 'Product removed successfully');          fetchProducts();
        }
        else
          throw();
      } catch (e) {
        Homepage.showOverlayMessage(context, 'Failed to remove product: $e');      }
    }
  }

  // Widget for individual product items
  Widget ProductCard({required Map<String, dynamic> product}) {
    String productName = product['name'] ?? 'No name available';
    String productImage = product['image_url'] ??
        'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg';

    // Attempt to display the product image
    Widget productImageWidget;
    if (productImage.isNotEmpty) {
      try {
        productImageWidget = Image.network(productImage, fit: BoxFit.cover);
      } catch (e) {
        productImageWidget =
            Icon(Icons.not_interested); // Fallback if image fails
      }
    } else {
      productImageWidget = Icon(Icons.not_interested); // Fallback if no image
    }

    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Dashboard(
                    productId: product['p_id'],
                    path: widget.oldpath + ">" + productName,
                  ),
            ),
          );
        },
        child: Stack(
          children: [
            Container(
              width: 150,
              height: 300,
              color: (product['is_active']??true)?Colors.blueAccent.withOpacity(0.1):Colors.redAccent.withOpacity(0.1),
              margin: EdgeInsets.only(bottom: 35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: productImageWidget,
                  ),
                  SizedBox(height: 10),
                  Text(
                    productName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Type : ${product['type']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Discount : ${product['discount']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if(product['c_id']!=null)Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                  icon: Icon(Icons.drive_file_move_outlined),
                  onPressed: () =>showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SearchBarWidget(searchType: 'product'), // You can pass 'product' or 'item' based on the need
                      );
                    },
                  ).then((result)async{
                    if(result?['p_id']==null)return;
                    await ProductApi.moveProduct(productId: product['p_id'], parent_productId:result['p_id']);
                    fetchProducts();
                  }),
              ),
            ),
            if(product['c_id']!=null)Positioned(
              bottom: 0,
              left: 0,
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, product['p_id'])
              ),
            ),
            if(product['is_new']??true)Positioned(
              top: 2,
              right: 2,
              child: Icon(Icons.fiber_new_outlined, color: Colors.green,size: 30,),
            ),
            if(product['c_id']!=null)Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.edit_outlined),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>EditProduct(productId: product['p_id'],productData: product,)
                  ).then((value){
                    if(value=='Done'){
                      fetchProducts();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
