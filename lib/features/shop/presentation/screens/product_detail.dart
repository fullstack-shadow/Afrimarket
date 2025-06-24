import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_flutter_app/features/shop/domain/models/product.dart';
import 'package:my_flutter_app/features/shop/presentation/controllers/shop_controller.dart';
import 'package:my_flutter_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:my_flutter_app/core/routing/app_router.dart';
import 'package:my_flutter_app/core/utils/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final ShopController _shopController = Get.find();
    final ChatController _chatController = Get.find();

    void _addToCart() {
      _shopController.addToCart(product);
      Get.snackbar(
        'Added to Cart',
        '${product.name} added to your cart',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    void _contactSeller() {
      _chatController.initiateChat(
        recipientId: product.sellerId,
        productId: product.id,
      );
      Get.toNamed(AppRoutes.chatScreen);
    }

    void _placeOrder() {
      Get.toNamed(
        AppRoutes.paymentProcessing,
        arguments: {'product': product},
      );
    }

    Widget _buildImageSlider() {
      return CarouselSlider(
        options: CarouselOptions(
          height: 300,
          viewportFraction: 1.0,
          autoPlay: true,
        ),
        items: product.imageUrls.map((url) {
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          );
        }).toList(),
      );
    }

    Widget _buildActionButtons() {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Contact Seller'),
              onPressed: _contactSeller,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add to Cart'),
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildBuyNowButton() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Buy Now',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shopController.shareProduct(product),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSlider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.price.toCurrency(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Obx(() {
                        final isFavorite = _shopController.isProductFavorite(product.id);
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                          ),
                          onPressed: () => _shopController.toggleFavorite(product),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category: ${product.category.capitalize()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seller: ${product.sellerName}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  _buildBuyNowButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}