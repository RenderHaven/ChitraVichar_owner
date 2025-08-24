import 'package:chitraowner/IteamView.dart';
import 'package:chitraowner/UserView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewApi {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all reviews with optional filtering
  Future<List<Map<String, dynamic>>> fetchReviews({
    String? itemId,
    String? userId,
  }) async {
    try {
      var query = _client.from('reviews').select('''
        *
      ''');

      if (itemId != null) {
        query = query.eq('i_id', itemId);
      }
      if (userId != null) {
        query = query.eq('u_id', userId);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  // Submit a new review
  Future<void> submitReview({
    required String itemId,
    required String userId,
    required String name,
    required String review,
    required int rating,
    String? imageUrl,
  }) async {
    try {
      await _client.from('reviews').insert({
        'i_id': itemId,
        'u_id': userId,
        'name': name,
        'review': review,
        'rating': rating,
        'image_url': imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _client.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get average rating for an item
  Future<double> getAverageRating(String itemId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('rating')
          .eq('i_id', itemId);

      if (response.isEmpty) return 0.0;

      final ratings = response.map((r) => (r['rating'] as num).toDouble()).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      throw Exception('Failed to calculate average rating: $e');
    }
  }

  // Get reviews for a specific item
  Future<List<Map<String, dynamic>>> getItemReviews(String itemId) async {
    return fetchReviews(itemId: itemId);
  }

  // Get reviews by a specific user
  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    return fetchReviews(userId: userId);
  }

  // Check if user has already reviewed an item
  Future<bool> hasUserReviewed(String itemId, String userId) async {
    try {
      final response = await _client
          .from('reviews')
          .select()
          .eq('i_id', itemId)
          .eq('u_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check user review: $e');
    }
  }

  // Update a review
  Future<void> updateReview({
    required String reviewId,
    String? review,
    int? rating,
    String? imageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (review != null) updates['review'] = review;
      if (rating != null) updates['rating'] = rating;
      if (imageUrl != null) updates['image_url'] = imageUrl;

      await _client.from('reviews').update(updates).eq('id', reviewId);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }
}


class ReviewPage extends StatefulWidget {
  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _searchController = TextEditingController();
  final ReviewApi _reviewApi = ReviewApi();
  final RxList<Map<String, dynamic>> _reviews = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _allreviews = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _sortBy = 'rating'.obs; // 'rating', 'date', 'name'
  final RxBool _sortAscending = false.obs;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      _isLoading.value = true;
      final response = await _reviewApi.fetchReviews();
      _allreviews.assignAll(response);
      _reviews.assignAll(response);
      _filterAndSortReviews();
    } finally {
      _isLoading.value = false;
    }
  }

  void _filterAndSortReviews() {
    var filtered = [..._allreviews];
    
    // Filter by search query
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((review) {
        return (review['name']?.toString().toLowerCase().contains(query) ?? false) ||
               (review['i_id']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Sort reviews
    filtered.sort((a, b) {
      switch (_sortBy.value) {
        case 'name':
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
        case 'date':
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
          return dateA.compareTo(dateB);
        case 'rating':
        default:
          return (a['rating'] ?? 0).compareTo(b['rating'] ?? 0);
      }
    });
    
    if (!_sortAscending.value) {
      filtered = filtered.reversed.toList();
    }
    
    _reviews.assignAll(filtered);
  }

  void _showReviewDetails(Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Review Details',
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
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  child: Text(review['name']?.toString().substring(0, 1) ?? '?'),
                ),
                title: Text(review['name'] ?? 'Anonymous'),
                isThreeLine: true,
                
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  
                  children: [
                    Text('User ID: ${review['u_id']}'),
                    Text('Item ID: ${review['i_id']}'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < (review['rating'] ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${review['rating'] ?? 0}.0',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(review['review'] ?? 'No review text'),
              ),
              if (review['image_url'] != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    review['image_url'],
                    height: 200,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteReview(review['id']);
                  },
                  child: const Text(
                    'Delete Review',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteReview(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this review?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteReview(id);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReview(String id) async {
    try {
      _isLoading.value = true;
      await _reviewApi.deleteReview(id);
      await _fetchReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete review: ${e.toString()}')),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed:()=>{},
      ),
      appBar: AppBar(
        title: const Text('Product Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReviews,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and filter row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        hintText: 'Search by customer name, item ID ',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery.value = '';
                                  _filterAndSortReviews();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _searchQuery.value = value.toLowerCase();
                        _filterAndSortReviews();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    if (value == 'toggle') {
                      _sortAscending.toggle();
                    } else {
                      _sortBy.value = value;
                    }
                    _filterAndSortReviews();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rating',
                      child: Text('Sort by rating'),
                    ),
                    const PopupMenuItem(
                      value: 'name',
                      child: Text('Sort by name'),
                    ),
                    const PopupMenuItem(
                      value: 'date',
                      child: Text('Sort by date'),
                    ),
                    const PopupMenuItem(
                      value: 'toggle',
                      child: Text('Toggle sort order'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Reviews list
            Expanded(
              child: Obx(() {
                if (_isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.reviews, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.value.isEmpty
                              ? 'No reviews available'
                              : 'No matching reviews found',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        if (_searchQuery.value.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery.value = '';
                              _filterAndSortReviews();
                            },
                            child: const Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: _reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return _buildReviewCard(review);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReviewDetails(review),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.all(0),
                title:Text(
                  review['name'] ?? 'Anonymous',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ), 
                subtitle:Text(
                  review['u_id'] ?? 'User ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                leading: Icon(Icons.person, color: Colors.grey), 
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) =>  Userview(userId:review['u_id']),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < (review['rating'] ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ],
              ),
              Text(
                review['review']?.length > 100
                    ? '${review['review'].substring(0, 100)}...'
                    : review['review'] ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (review['image_url'] != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review['image_url'],
                    // height: 80,
                    
                    fit: BoxFit.cover,
                    width:150,
                  ),
                ),

              
              ],
              const SizedBox(height: 8),
              Text(review['created_at'] ?? 'NA',),
              const SizedBox(height: 8),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.all(0),
                title:Text(
                  review['item_name'] ?? 'Item',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ), 
                subtitle:Text(
                  review['i_id'] ?? 'Item ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                leading: Icon(Icons.shopping_bag, color: Colors.grey), 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemViewPage(itemId: review['i_id']),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}