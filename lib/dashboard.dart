// Dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'HomePage.dart';
import 'ProductTree.dart';
import 'SearchProducts.dart';
import 'ShowItems.dart';
import 'ShowProducts.dart';

class Dashboard extends StatefulWidget {
  final String? productId;
  final String path;
  
  const Dashboard({
    this.productId,
    this.path = 'MyProducts',
    Key? key,
  }) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final HomepageController homeController = Get.put(HomepageController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Make sure you have this key defined
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        child: const Icon(Icons.account_tree),
        tooltip: 'Show product tree',
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ProductTreeView(selectedId: widget.productId),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false, // This hides the drawer menu icon
        leading: Navigator.canPop(context) 
          ? const BackButton() 
          : null,
        title: Obx(() => Text(
          homeController.productsData[widget.productId ?? 'null']?['name'] ?? 'Root',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search products',
            onPressed: _showSearchBottomSheet,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Showproducts(
              categoryId: widget.productId == 'Root' ? null : widget.productId,
              oldpath: widget.path,
            ),
            const Divider(height: 40),
            if (widget.productId != null && widget.productId != 'Root')
              ShowItems(productId: widget.productId!),
          ],
        ),
      ),
    );
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SearchBarWidget(searchType: 'product'),
          ],
        ),
      ),
    ).then((result) {
      if (result?['p_id'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(
              productId: result['p_id'],
              path: '....${result['name']}',
            ),
          ),
        );
      }
    });
  }
}