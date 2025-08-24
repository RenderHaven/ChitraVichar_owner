import 'dart:typed_data';

import 'package:chitraowner/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import "package:product_personaliser/product_personaliser.dart";

import 'dart:html' as html;
import 'package:flutter/material.dart';

class ClickableImageNetwork extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ClickableImageNetwork({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onDoubleTap: () {
        html.window.open(imageUrl, '_blank');
      },
      
      child: CachedWebImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
      ),
    );
  }
}
class WebImageCache {
  static final Map<String, Uint8List> _memoryCache = {};
  static final Map<String, html.Blob> _blobCache = {};
  static final Map<String, String> _objectUrlCache = {};

  /// Get cached image with multiple fallback layers
  static Future<Uint8List?> getImage(String url) async {
    // 1. Check memory cache first
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    // 2. Check if we have a blob version
    if (_blobCache.containsKey(url)) {
      final blob = _blobCache[url]!;
      final bytes = await blobToUint8List(blob);
      _memoryCache[url] = bytes; // Populate memory cache
      return bytes;
    }

    // 3. Check if we have an ObjectURL version (browser memory)
    if (_objectUrlCache.containsKey(url)) {
      try {
        final response = await html.HttpRequest.request(
          _objectUrlCache[url]!,
          responseType: 'arraybuffer',
        );
        final bytes = Uint8List.view(response.response as ByteBuffer);
        _memoryCache[url] = bytes;
        return bytes;
      } catch (e) {
        // ObjectURL might be stale, continue to fetch fresh
      }
    }

    // 4. Fetch fresh from network
    try {
      final response = await html.HttpRequest.request(
        url,
        responseType: 'arraybuffer',
      );

      if (response.status == 200) {
        final bytes = Uint8List.view(response.response as ByteBuffer);
        
        // Cache in all layers
        _memoryCache[url] = bytes;
        _blobCache[url] = html.Blob([bytes]);
        _objectUrlCache[url] = html.Url.createObjectUrl(_blobCache[url]!);
        
        return bytes;
      }
    } catch (e) {
      debugPrint('Image load error: $e');
    }

    return null;
  }

  static Future<Uint8List> blobToUint8List(html.Blob blob) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;
    return Uint8List.view(reader.result as ByteBuffer);
  }

  /// Pre-cache image without displaying it
  static void preCache(String url) async {
    if (!_memoryCache.containsKey(url) &&
        !_blobCache.containsKey(url) &&
        !_objectUrlCache.containsKey(url)) {
      await getImage(url);
    }
  }

  /// Clear caches (important for memory management)
  static void clearCache() {
    for (final url in _objectUrlCache.values) {
      html.Url.revokeObjectUrl(url);
    }
    _memoryCache.clear();
    _blobCache.clear();
    _objectUrlCache.clear();
  }
}

class CachedWebImage extends StatelessWidget {
  final String imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const CachedWebImage({
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: WebImageCache.getImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: fit,
            ),
          );
        } else if (snapshot.hasError) {
          return errorWidget ?? const Icon(Icons.broken_image);
        }
        return Center(child: placeholder ?? CircularProgressIndicator());
      },
    );
  }
}

class Helper{
  
  
  static void selectTemplate(BuildContext context,{Function(DesignTemplate)? onTap}) async {
    TextEditingController _searchController = TextEditingController();

    final HomepageController Homecontroller = Get.put(HomepageController());
    List<DesignTemplate> searchResults = [];

    Future<void> performSearch() async {
      final String keyword = _searchController.text.trim().toLowerCase();
      Homecontroller.isTemplateLoading.value = true;

      if (Homecontroller.templateList.value == null) {
        await Homecontroller.fetchTemplates(); // Replace with your actual method
      }

      final templateList = Homecontroller.templateList.value!;
      if (keyword.isEmpty) {
        searchResults = templateList;
      } else {
        searchResults = templateList
            .where((template) => template.name
                .toString()
                .toLowerCase()
                .contains(keyword))
            .toList();
      }
      Homecontroller.isTemplateLoading.value = false;
    }

    await performSearch();

    showDialog(
      context: context,
      builder: (context) {
        return Obx(() {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Template'),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(labelText: 'Search Template'),
                  onChanged: (value) => performSearch(),
                ),
                SizedBox(height: 10),
                Text("Results: ${searchResults.length}"),
                Homecontroller.isTemplateLoading.value
                    ? CircularProgressIndicator()
                    : searchResults.isEmpty
                        ? Text('No templates found')
                        : ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 500),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: searchResults.map((template) {
                                  return InkWell(
                                    hoverColor: Colors.blueAccent.withOpacity(0.5),
                                    onTap: () {
                                      Navigator.pop(context);
                                      if(onTap!=null){
                                        onTap(template);
                                      }
                                    },
                                    child: Card(
                                      child: Container(
                                        margin: EdgeInsets.all(5),
                                        alignment: Alignment.centerLeft,
                                        width: double.infinity,
                                        child: Text(
                                          "${template.name}\n${template.id}",
                                          style: TextStyle(color: Colors.black),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
              ],
            ),
          );
        });
      },
    );
  }

}