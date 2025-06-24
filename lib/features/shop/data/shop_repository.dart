import 'dart:async';
import 'package:my_flutter_app/features/shop/domain/models/product.dart';
import 'package:my_flutter_app/services/network_client.dart';
import 'package:my_flutter_app/services/cloud_storage.dart';
import 'package:my_flutter_app/core/utils/logger.dart';

abstract class ShopRepository {
  // Products
  Future<List<Product>> getProducts({int page = 1, int limit = 20});
  Future<Product> getProductById(String productId);
  Future<List<Product>> searchProducts(String query);
  Future<List<Product>> getProductsByCategory(String category);
  Future<String> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String productId);
  
  // Categories
  Future<List<String>> getCategories();
  
  // User products
  Future<List<Product>> getUserProducts(String userId);
  
  // Favorites
  Future<void> addToFavorites(String userId, String productId);
  Future<void> removeFromFavorites(String userId, String productId);
  Future<List<Product>> getUserFavorites(String userId);
  
  // Cart
  Future<void> addToCart(String userId, String productId, int quantity);
  Future<void> removeFromCart(String userId, String productId);
  Future<void> updateCartQuantity(String userId, String productId, int quantity);
  
  // Images
  Future<List<String>> uploadProductImages(List<String> imagePaths);
}

class ShopRepositoryImpl implements ShopRepository {
  final NetworkClient _networkClient;
  final CloudStorage _cloudStorage;

  ShopRepositoryImpl({
    required NetworkClient networkClient,
    required CloudStorage cloudStorage,
  })  : _networkClient = networkClient,
        _cloudStorage = cloudStorage;

  @override
  Future<List<Product>> getProducts({int page = 1, int limit = 20}) async {
    try {
      final response = await _networkClient.get(
        '/products',
        queryParams: {'page': page.toString(), 'limit': limit.toString()},
      );
      return (response['products'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch products: $e');
      rethrow;
    }
  }

  @override
  Future<Product> getProductById(String productId) async {
    try {
      final response = await _networkClient.get('/products/$productId');
      return Product.fromJson(response);
    } catch (e) {
      Logger.error('Failed to fetch product $productId: $e');
      rethrow;
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _networkClient.get(
        '/products/search',
        queryParams: {'q': query},
      );
      return (response['results'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      Logger.error('Product search failed for "$query": $e');
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _networkClient.get(
        '/products/category/$category',
      );
      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch products in $category: $e');
      rethrow;
    }
  }

  @override
  Future<String> createProduct(Product product) async {
    try {
      final response = await _networkClient.post(
        '/products',
        body: product.toJson(),
      );
      return response['id'] as String;
    } catch (e) {
      Logger.error('Failed to create product: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      await _networkClient.put(
        '/products/${product.id}',
        body: product.toJson(),
      );
    } catch (e) {
      Logger.error('Failed to update product ${product.id}: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _networkClient.delete('/products/$productId');
    } catch (e) {
      Logger.error('Failed to delete product $productId: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await _networkClient.get('/products/categories');
      return (response as List).cast<String>();
    } catch (e) {
      Logger.error('Failed to fetch categories: $e');
      return [];
    }
  }

  @override
  Future<List<Product>> getUserProducts(String userId) async {
    try {
      final response = await _networkClient.get('/users/$userId/products');
      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch user products: $e');
      return [];
    }
  }

  @override
  Future<void> addToFavorites(String userId, String productId) async {
    try {
      await _networkClient.post(
        '/users/$userId/favorites',
        body: {'productId': productId},
      );
    } catch (e) {
      Logger.error('Failed to add favorite: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _networkClient.delete(
        '/users/$userId/favorites/$productId',
      );
    } catch (e) {
      Logger.error('Failed to remove favorite: $e');
      rethrow;
    }
  }

  @override
  Future<List<Product>> getUserFavorites(String userId) async {
    try {
      final response = await _networkClient.get('/users/$userId/favorites');
      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch favorites: $e');
      return [];
    }
  }

  @override
  Future<void> addToCart(String userId, String productId, int quantity) async {
    try {
      await _networkClient.post(
        '/users/$userId/cart',
        body: {'productId': productId, 'quantity': quantity},
      );
    } catch (e) {
      Logger.error('Failed to add to cart: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await _networkClient.delete('/users/$userId/cart/$productId');
    } catch (e) {
      Logger.error('Failed to remove from cart: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCartQuantity(
      String userId, String productId, int quantity) async {
    try {
      await _networkClient.put(
        '/users/$userId/cart/$productId',
        body: {'quantity': quantity},
      );
    } catch (e) {
      Logger.error('Failed to update cart quantity: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> uploadProductImages(List<String> imagePaths) async {
    try {
      final urls = <String>[];
      for (final path in imagePaths) {
        final url = await _cloudStorage.uploadFile(
          'products/${DateTime.now().millisecondsSinceEpoch}',
          path,
        );
        urls.add(url);
      }
      return urls;
    } catch (e) {
      Logger.error('Failed to upload product images: $e');
      rethrow;
    }
  }
}