import 'package:chitraowner/dashboard.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'ApiManagment/ProductApi.dart';
import 'HomePage.dart';
import 'package:get/get.dart';
class SearchBarWidget extends StatefulWidget {
  final String searchType; // 'product' or 'item'

  // Constructor with searchType
  SearchBarWidget({
    required this.searchType,
  });

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  TextEditingController _searchController = TextEditingController();
  final HomepageController controller = Get.put(HomepageController());
  String tag='';

  void initState(){
    super.initState();
    fetchData();
  }

  void fetchData()async{
    if(controller.productList.value==null){
      await controller.searchProducts();
    }
    controller.productSearchList.value = List.from(controller.productList.value ?? []);
  }

  void _filterItems() {
    print('filtering for $tag');
    final List=controller.productList.value??[];
    if (tag.isEmpty) {
      controller.productSearchList.value =List; // Reset to full list
    } else {
      controller.productSearchList.value = List
          .where((variation) => variation['name'].toLowerCase().contains(tag))
          .toList();
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by Product Name',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed:(){
                  tag=_searchController.text.toLowerCase()??'';
                  _filterItems();
                },
              ),
            ),
            onChanged:(v){
              tag=_searchController.text.toLowerCase()??'';
              _filterItems();
            },
          ),
          SizedBox(height: 20),
          Obx((){
            return controller.isProductLoading.value
                ? CircularProgressIndicator()
                : Expanded(
              child: (controller.productSearchList.value??[]).isNotEmpty?ListView.builder(
                itemCount: controller.productSearchList.value?.length??0,
                itemBuilder: (context, index) {
                  Map<String,dynamic> result = controller.productSearchList.value?[index]??{};
                  return result.containsKey('name')?Card(
                    child: ListTile(
                        title: Text(result['name'] ?? 'Unknown'),
                      onTap: (){
                          Navigator.pop(context,result);
                      }
                    ),
                  ):Text('NO DATA');
                },
              ):Text('NO DATA'),
            );
          })
        ],
      ),
    );
  }
}


