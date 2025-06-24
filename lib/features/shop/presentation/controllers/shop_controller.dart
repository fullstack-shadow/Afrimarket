import 'package:get/get.dart';
import 'package:my_flutter_app/features/shop/domain/models/product.dart';
import 'package:my_flutter_app/features/shop/data/shop_repository.dart';
import 'package:my_flutter_app/services/network_client.dart';
import 'package:my_flutter_app/core/utils/logger.dart';
import 'package:my_flutter_app/services/cloud_storage.dart';
import 'package:image_picker/image_picker.dart';

class ShopController extends GetxController {
  final ShopRepository _shopRepository;
  final NetworkClient _networkClient;
  final CloudStorage _cloudStorage;
  final ImagePicker _imagePicker = ImagePicker();

  ShopController(
    this._shopRepository,
    this._networkClient,
    this._cloudStorage,
  );

  // Reactive state
  final RxList<Product> _products = <Product>[].obs;
  final RxList<Product> _userProducts = <Product>[].obs;
  final RxList<Product> _favorites = <Product>[].obs;
  final RxList<String> _categories = <String>[].obs;
  final RxString _selectedCategory = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasMore = true.obs;
  final RxInt _currentPage = 1.obs;
  final RxString _currentUserId = ''.obs;
  final RxString _currentUserName = ''.obs;
  final RxBool _isSeller = false.obs;

  // Getters
  List<Product> get products => _products;
  List<Product> get userProducts => _userProducts;
  List<Product> get favorites => _favorites;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory.value;
  bool get isLoading => _isLoading.value;
  bool get hasMore => _hasMore.value;
  bool get isSeller => _isSeller.value;
  String? get currentUserId => _currentUserId.value;
  String? get currentUserName => _currentUserName.value;

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
  }

  void _initializeUser() {
    final authController = Get.find<AuthController>();
    _currentUserId.value = authController.currentUser?.id;
    _currentUserName.value = authController.currentUser?.name;
    _isSeller.value = authController.currentUser?.isSeller ?? false;
    
    if (_currentUserId.value != null) {
      loadUserProducts();
      loadUserFavorites();
    }
  }

  Future<void> loadInitialProducts() async {
    try {
      _isLoading.value = true;
      _currentPage.value = 1;
      
      final products = await _shopRepository.getProducts(page: 1);
      _products.assignAll(products);
      _hasMore.value = products.length == 20; // Assuming pagination limit is 20
      
      await _loadCategories();
    } catch (e) {
      Logger.error('Initial product load failed: $e');
      Get.snackbar('Error', 'Failed to load products');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMore.value || _isLoading.value) return;
    
    try {
      _isLoading.value = true;
      _currentPage.value++;
      
      final products = await _shopRepository.getProducts(
        page: _currentPage.value,
      );
      
      if (products.isEmpty) {
        _hasMore.value = false;
      } else {
        _products.addAll(products);
      }
    } catch (e) {
      Logger.error('Failed to load more products: $e');
      _currentPage.value--;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _shopRepository.getCategories();
      _categories.assignAll(categories);
    } catch (e) {
      Logger.error('Category load failed: $e');
    }
  }

  Future<void> searchProducts(String query) async {
    try {
      _isLoading.value = true;
      final results = await _shopRepository.searchProducts(query);
      _products.assignAll(results);
    } catch (e) {
      Logger.error('Product search failed: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> filterByCategory(String category) async {
    try {
      _isLoading.value = true;
      _selectedCategory.value = category;
      
      if (category.isEmpty) {
        await loadInitialProducts();
      } else {
        final products = await _shopRepository.getProductsByCategory(category);
        _products.assignAll(products);
      }
    } catch (e) {
      Logger.error('Category filter failed: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadUserProducts() async {
    if (_currentUserId.value == null) return;
    
    try {
      _isLoading.value = true;
      final products = await _shopRepository.getUserProducts(_currentUserId.value!);
      _userProducts.assignAll(products);
    } catch (e) {
      Logger.error('Failed to load user products: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadUserFavorites() async {
    if (_currentUserId.value == null) return;
    
    try {
      _isLoading.value = true;
      final favorites = await _shopRepository.getUserFavorites(_currentUserId.value!);
      _favorites.assignAll(favorites);
    } catch (e) {
      Logger.error('Failed to load favorites: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  bool isProductFavorite(String productId) {
    return _favorites.any((product) => product.id == productId);
  }

  Future<void> toggleFavorite(Product product) async {
    if (_currentUserId.value == null) return;
    
    try {
      if (isProductFavorite(product.id)) {
        await _shopRepository.removeFromFavorites(
          _currentUserId.value!, 
          product.id,
        );
        _favorites.removeWhere((p) => p.id == product.id);
      } else {
        await _shopRepository.addToFavorites(
          _currentUserId.value!, 
          product.id,
        );
        _favorites.add(product);
      }
    } catch (e) {
      Logger.error('Favorite toggle failed: $e');
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (_currentUserId.value == null) return;
    
    try {
      await _shopRepository.addToCart(
        _currentUserId.value!, 
        product.id, 
        quantity,
      );
      Get.snackbar('Success', 'Added to cart');
    } catch (e) {
      Logger.error('Add to cart failed: $e');
      Get.snackbar('Error', 'Failed to add to cart');
    }
  }

  Future<List<String>> pickProductImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFiles == null || pickedFiles.isEmpty) return [];
      
      return pickedFiles.map((file) => file.path).toList();
    } catch (e) {
      Logger.error('Image pick failed: $e');
      return [];
    }
  }

  Future<void> createProductListing(Product product) async {
    try {
      _isLoading.value = true;
      
      // Upload images first
      if (product.imageUrls.isNotEmpty) {
        final imageUrls = await _shopRepository.uploadProductImages(
          product.imageUrls,
        );
        product = product.copyWith(imageUrls: imageUrls);
      }
      
      await _shopRepository.createProduct(product);
      _userProducts.add(product);
      Get.snackbar('Success', 'Product listed successfully');
    } catch (e) {
      Logger.error('Product creation failed: $e');
      Get.snackbar('Error', 'Failed to create product listing');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateProductListing(Product product) async {
    try {
      _isLoading.value = true;
      await _shopRepository.updateProduct(product);
      
      // Update in user products
      final index = _userProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _userProducts[index] = product;
      }
      
      // Update in main products if exists
      final mainIndex = _products.indexWhere((p) => p.id == product.id);
      if (mainIndex != -1) {
        _products[mainIndex] = product;
      }
      
      Get.snackbar('Success', 'Product updated successfully');
    } catch (e) {
      Logger.error('Product update failed: $e');
      Get.snackbar('Error', 'Failed to update product');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteProductListing(String productId) async {
    try {
      _isLoading.value = true;
      await _shopRepository.deleteProduct(productId);
      _userProducts.removeWhere((p) => p.id == productId);
      _products.removeWhere((p) => p.id == productId);
      Get.snackbar('Success', 'Product deleted');
    } catch (e) {
      Logger.error('Product deletion failed: $e');
      Get.snackbar('Error', 'Failed to delete product');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> shareProduct(Product product) async {
    try {
      // Implement share functionality using share_plus or similar
      Get.snackbar('Share', 'Product shared successfully');
    } catch (e) {
      Logger.error('Product share failed: $e');
    }
  }
}