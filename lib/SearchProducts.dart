// SearchBarWidget.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ApiManagment/ProductApi.dart';
import 'HomePage.dart';

class SearchBarWidget extends StatefulWidget {
  final String searchType;

  const SearchBarWidget({
    required this.searchType,
    Key? key,
  }) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final HomepageController controller = Get.put(HomepageController());
  String tag = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (controller.productList.value == null) {
      await controller.searchProducts();
    }
    controller.productSearchList.value = List.from(controller.productList.value ?? []);
  }

  void _filterItems() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final List = controller.productList.value ?? [];
      if (tag.isEmpty) {
        controller.productSearchList.value = List;
      } else {
        controller.productSearchList.value = List
            .where((variation) => variation['name'].toLowerCase().contains(tag))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search ${widget.searchType}s',
            hintText: 'Enter name...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => tag = '');
                      _filterItems();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (v) {
            setState(() => tag = v.toLowerCase());
            _filterItems();
          },
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isProductLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final results = controller.productSearchList.value ?? [];
          
          if (results.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                tag.isEmpty ? 'No ${widget.searchType}s available' : 'No results found',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }
          
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    title: Text(result['name'] ?? 'Unknown'),
                    onTap: () => Navigator.pop(context, result),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}