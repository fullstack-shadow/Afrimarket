import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_flutter_app/features/shop/presentation/controllers/shop_controller.dart';
import 'package:my_flutter_app/features/shop/domain/models/product.dart';
import 'package:my_flutter_app/widgets/features/shop/product_card.dart';
import 'package:my_flutter_app/core/routing/app_router.dart';
import 'package:my_flutter_app/core/utils/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  final ShopController _controller = Get.find();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadInitialProducts();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _controller.loadMoreProducts();
    }
  }

  void _onSearchChanged(String value) {
    _controller.searchProducts(value);
  }

  void _onCategorySelected(String category) {
    _controller.filterByCategory(category);
  }

  void _onProductTap(Product product) {
    Get.toNamed(
      AppRoutes.productDetail,
      arguments: {'product': product},
    );
  }

  void _createNewListing() {
    Get.toNamed(AppRoutes.createListing);
  }

  Widget _buildCategoryChips() {
    return Obx(() {
      final categories = _controller.categories;
      final selectedCategory = _controller.selectedCategory.value;

      return SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(category.capitalize()),
                selected: selectedCategory == category,
                onSelected: (selected) => 
                  _onCategorySelected(selected ? category : ''),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildProductGrid() {
    return Obx(() {
      if (_controller.isLoading.value && _controller.products.isEmpty) {
        return _buildShimmerGrid();
      }

      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _controller.products.length + 
            (_controller.hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _controller.products.length) {
            return _buildLoadingIndicator();
          }
          
          final product = _controller.products[index];
          return ProductCard(
            product: product,
            onTap: () => _onProductTap(product),
          );
        },
      );
    });
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Obx(() {
      if (!_controller.isSeller.value) return const SizedBox.shrink();
      
      return FloatingActionButton(
        onPressed: _createNewListing,
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Get.toNamed(AppRoutes.cart),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          _buildCategoryChips(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}