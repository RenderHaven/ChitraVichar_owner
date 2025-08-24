import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chitraowner/AddVariation.dart';
import 'package:chitraowner/HomePage.dart';
import 'ApiManagment/ProductApi.dart';

class MyVariation extends StatefulWidget {
  @override
  _MyVariationState createState() => _MyVariationState();
}

class _MyVariationState extends State<MyVariation> {
  final TextEditingController _searchController = TextEditingController();
  final HomepageController controller = Get.put(HomepageController());
  String tag = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (controller.variationList.value == null) {
      await controller.searchVariations();
    }
    _filterVariation();
  }

  void _filterVariation() {
    final variationList = controller.variationList.value ?? [];
    if (tag.isEmpty) {
      controller.variationSearchList.value = List.from(variationList);
    } else {
      controller.variationSearchList.value = variationList
          .where((variation) => variation['name'].toLowerCase().contains(tag))
          .toList();
    }
  }

  Future<void> _showVariationDetails(Map<String, dynamic> variation) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      variation['name'] ?? 'Variation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (variation.containsKey('options'))
                  ...variation['options'].map<Widget>((option) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['value'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (option['disc'] != null &&
                                    option['disc'].isNotEmpty)
                                  Text(
                                    option['disc'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteVariation(variation['id']);
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _editVariation(variation);
                        },
                        child: Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteVariation(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this variation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteVariation(id);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVariation(String id) async {
    final result = await VariationApi.removeVariation(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
    if (result['success']) {
      await controller.searchVariations();
      _filterVariation();
    }
  }

  Future<void> _editVariation(Map<String, dynamic> variation) async {
    final nameController = TextEditingController(text: variation['name']);
    List<VariationOption> currentOptions = [];

    for (var option in variation['options']) {
      currentOptions.add(VariationOption(
        valueController: TextEditingController(text: option['value']),
        discController: TextEditingController(text: option['disc']),
        id: option['id'],
        value: option['value'],
        disc: option['disc'],
      ));
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Variation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              // Clean up controllers
                              nameController.dispose();
                              for (var option in currentOptions) {
                                option.valueController.dispose();
                                option.discController.dispose();
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Variation Name (Display::Identifier)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Options',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...currentOptions.map((option) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: option.valueController,
                                    decoration: InputDecoration(
                                      labelText: 'Value',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: option.discController,
                                    decoration: InputDecoration(
                                      labelText: 'Description',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      option.valueController.dispose();
                                      option.discController.dispose();
                                      currentOptions.remove(option);
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentOptions.add(VariationOption(
                              valueController: TextEditingController(),
                              discController: TextEditingController(),
                              id: 'New',
                            ));
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text('Add Option'),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final newName = nameController.text.trim();
                                  if (newName.isEmpty ||
                                      currentOptions.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Variation name and at least one option are required'),
                                      ),
                                    );
                                    return;
                                  }

                                  List<Map<String, dynamic>> updatedOptions =
                                      currentOptions.map((option) {
                                    return {
                                      'id': option.id,
                                      'value':
                                          option.valueController.text.trim(),
                                      'disc': option.discController.text.trim(),
                                    };
                                  }).toList();

                                  setState(() => _isLoading = true);
                                  final result =
                                      await VariationApi.editVariation(
                                    variation['id'],
                                    newName,
                                    updatedOptions,
                                  );

                                  if (result['success']) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(result['message'])),
                                    );
                                    Navigator.pop(context);
                                    await controller.searchVariations();
                                    _filterVariation();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result['error'])),
                                    );
                                  }
                                  setState(() => _isLoading = false);
                                },
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addNewVariation() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddVariationPage(),
    ).then((v) async {
      if (v == 'Done') {
        await controller.searchVariations();
        _filterVariation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _addNewVariation,
      ),
      appBar: AppBar(
        title: Text('Product Variations',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await controller.searchVariations();
              _filterVariation();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'Search variations...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            tag = '';
                            _filterVariation();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  tag = value.toLowerCase();
                  _filterVariation();
                },
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isVariationLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }

                final variations = controller.variationSearchList.value ?? [];
                if (variations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 48, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          tag.isEmpty
                              ? 'No variations available'
                              : 'No matching variations found',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        if (tag.isNotEmpty) ...[
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              tag = '';
                              _filterVariation();
                            },
                            child: Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: variations.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final variation = variations[index];
                    return _buildVariationCard(variation);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationCard(Map<String, dynamic> variation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showVariationDetails(variation),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    variation['name'] ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              SizedBox(height: 8),
              if (variation.containsKey('options') &&
                  variation['options'].isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: variation['options'].map<Widget>((option) {
                    return Chip(
                      label: Text(option['value'] ?? ''),
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(color: Colors.blue[800]),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VariationOption {
  TextEditingController valueController;
  TextEditingController discController;
  String id;
  String? value;
  String? disc;

  VariationOption({
    required this.valueController,
    required this.discController,
    this.id = 'New',
    this.disc,
    this.value,
  });
}
