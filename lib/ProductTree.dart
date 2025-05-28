import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'HomePage.dart';
import 'dashboard.dart';

class ProductNode {
  final String id;
  final String name;
  final String imageUrl;
  final List<ProductNode> children;
  final bool isNew;
  final bool isPromotion;
  final bool isActive;

  ProductNode({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.children,
    required this.isNew,
    required this.isPromotion,
    required this.isActive,
  });
}

class ProductTreeView extends StatefulWidget {
  String? selectedId;
  ProductTreeView({super.key,this.selectedId});

  @override
  State<ProductTreeView> createState() => _ProductTreeViewState();
}

class _ProductTreeViewState extends State<ProductTreeView> {
  final HomepageController homeController = Get.put(HomepageController());

  bool _isAdmin=true;

  ProductNode buildTree(String? nodeId, Map<String, dynamic> data) {
    final node = nodeId!='Root'?data[nodeId]??{}:{'name':'Root','sub_products':['Home','MY','Pro']};
    final childrenIds = List<String>.from(node['sub_products'] ?? []);

    return ProductNode(
      id: nodeId??'NA',
      name: node['name'] ?? 'Unnamed',
      imageUrl: node['image_url'] ?? '',
      children: childrenIds.map((childId) => buildTree(childId, data)).toList(),
      isNew:node['is_new']??false,
      isActive:node['is_active']??true,
      isPromotion:node['is_promotion']??false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (homeController.isTreeLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (!homeController.productsData.containsKey('Home')) {
        return const Scaffold(
          body: Center(child: Text("No 'Home' root found")),
        );
      }
      final treeRoot = buildTree(_isAdmin?'Root':'Home', homeController.productsData);

      return Scaffold(
        appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Product Tree"),
              IconButton(onPressed:()=> homeController.fetchProductsTree(), icon: Icon(Icons.refresh)),
            ],
          ),
        ),
        actions: [
          const Text("Admin View"),
          Transform.scale(scale:0.7,child: Switch(value: _isAdmin,onChanged: (_){setState((){_isAdmin=!_isAdmin;});}))
        ],
        ),

        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,  // make it larger than screen
              // height: MediaQuery.of(context).size.height * 2,
              child: TreeNodeWidget(
                node: treeRoot,
                isAdmin: _isAdmin,
                selectedId: widget.selectedId,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class TreeNodeWidget extends StatefulWidget {
  final ProductNode node;
  String? selectedId;
  bool isAdmin;
  TreeNodeWidget({super.key, required this.node,this.isAdmin=true,this.selectedId});

  @override
  State<TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<TreeNodeWidget> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.node.children.isNotEmpty)
              IconButton(
                icon: Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
              )
            else
              const SizedBox(width: 40),
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: widget.node.id==widget.selectedId?Colors.blue:Colors.transparent,
                ),
                IconButton(
                  onPressed:()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard(productId:widget.node.id ,path: '....${widget.node.name}',))),
                  icon: CircleAvatar(
                    backgroundImage:widget.node.imageUrl!=''? NetworkImage(widget.node.imageUrl):null,
                    radius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              widget.node.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: widget.node.isActive?null:Colors.red),
            ),
            const SizedBox(width: 2),
            if(widget.node.isNew)Icon(Icons.fiber_new_outlined,color: Colors.green,),
            const SizedBox(width: 2),
            if(widget.node.isPromotion)Icon(Icons.sell_sharp,color: Colors.yellow,)
          ],
        ),
        if (isExpanded && widget.node.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.node.children
                  .map((child) => TreeNodeWidget(node: child,isAdmin: widget.isAdmin,selectedId: widget.selectedId,)).where((child){return (child.node.isActive || widget.isAdmin);})
                  .toList(),
            ),
          ),
      ],
    );
  }
}

