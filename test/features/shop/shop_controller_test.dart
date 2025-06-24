import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:your_app/features/shop/data/shop_repository.dart';
import 'package:your_app/features/shop/domain/models/product.dart';
import 'package:your_app/features/shop/presentation/controllers/shop_controller.dart';

class MockShopRepository extends Mock implements ShopRepository {}

void main() {
  late ShopController shopController;
  late MockShopRepository mockShopRepository;
  late Listener<ShopState> listener;

  const testProduct = Product(
    id: 'prod1',
    name: 'Test Product',
    price: 100.0,
    description: 'Test description',
    category: 'Electronics',
    imageUrl: 'https://example.com/image.jpg',
    stock: 10,
  );

  setUp(() {
    mockShopRepository = MockShopRepository();
    shopController = ShopController(repository: mockShopRepository);
    listener = Listener<ShopState>();
    
    registerFallbackValue(ShopState.initial());
  });

  group('ShopController', () {
    test('initial state is ShopState.initial', () {
      expect(shopController.state, equals(ShopState.initial()));
    });

    group('loadProducts', () {
      test('successful product loading', () async {
        // Arrange
        final products = [testProduct];
        when(() => mockShopRepository.getProducts())
            .thenAnswer((_) async => products);

        shopController.addListener(listener);

        // Act
        await shopController.loadProducts();

        // Assert
        verifyInOrder([
          () => listener(null, const ShopState.loading()),
          () => listener(const ShopState.loading(), 
                ShopState.loaded(products)),
        ]);
      });

      test('empty product list', () async {
        // Arrange
        when(() => mockShopRepository.getProducts())
            .thenAnswer((_) async => []);

        shopController.addListener(listener);

        // Act
        await shopController.loadProducts();

        // Assert
        verifyInOrder([
          () => listener(null, const ShopState.loading()),
          () => listener(const ShopState.loading(), 
                const ShopState.loaded([])),
        ]);
      });
    });

    group('addProduct', () {
      const newProduct = Product(
        name: 'New Product',
        price: 50.0,
        description: 'New description',
        category: 'Home',
        stock: 5,
      );

      test('successful product addition', () async {
        // Arrange
        final createdProduct = testProduct.copyWith(
          name: newProduct.name,
          price: newProduct.price,
        );
        when(() => mockShopRepository.addProduct(newProduct))
            .thenAnswer((_) async => createdProduct);

        // Preload products
        shopController.state = ShopState.loaded([testProduct]);
        shopController.addListener(listener);

        // Act
        await shopController.addProduct(newProduct);

        // Assert
        verifyInOrder([
          () => listener(ShopState.loaded([testProduct]), 
                ShopState.loaded([testProduct, createdProduct])),
        ]);
      });
    });

    group('updateProduct', () {
      const updatedPrice = 120.0;

      test('successful product update', () async {
        // Arrange
        final updatedProduct = testProduct.copyWith(price: updatedPrice);
        when(() => mockShopRepository.updateProduct(updatedProduct))
            .thenAnswer((_) async => updatedProduct);

        // Preload products
        shopController.state = ShopState.loaded([testProduct]);
        shopController.addListener(listener);

        // Act
        await shopController.updateProduct(updatedProduct);

        // Assert
        verify(() => listener(
              ShopState.loaded([testProduct]), 
              ShopState.loaded([updatedProduct]))).called(1);
      });
    });

    group('deleteProduct', () {
      const productId = 'prod1';

      test('successful product deletion', () async {
        // Arrange
        when(() => mockShopRepository.deleteProduct(productId))
            .thenAnswer((_) async {});

        // Preload products
        shopController.state = ShopState.loaded([testProduct]);
        shopController.addListener(listener);

        // Act
        await shopController.deleteProduct(productId);

        // Assert
        verify(() => listener(
              ShopState.loaded([testProduct]), 
              const ShopState.loaded([]))).called(1);
      });
    });

    group('searchProducts', () {
      const query = 'test';

      test('successful search', () async {
        // Arrange
        final results = [testProduct];
        when(() => mockShopRepository.searchProducts(query))
            .thenAnswer((_) async => results);

        shopController.addListener(listener);

        // Act
        await shopController.searchProducts(query);

        // Assert
        verifyInOrder([
          () => listener(null, const ShopState.searching()),
          () => listener(const ShopState.searching(), 
                ShopState.searchResults(results)),
        ]);
      });

      test('clear search', () async {
        // Arrange
        shopController.state = ShopState.searchResults([testProduct]);
        shopController.addListener(listener);

        // Act
        shopController.clearSearch();

        // Assert
        verify(() => listener(
              ShopState.searchResults([testProduct]), 
              const ShopState.initial())).called(1);
      });
    });

    group('filterProducts', () {
      const category = 'Electronics';

      test('filter by category', () async {
        // Arrange
        final electronicsProduct = testProduct.copyWith(category: category);
        final otherProduct = testProduct.copyWith(category: 'Home');
        final products = [electronicsProduct, otherProduct];

        // Preload products
        shopController.state = ShopState.loaded(products);
        shopController.addListener(listener);

        // Act
        shopController.filterByCategory(category);

        // Assert
        verify(() => listener(
              ShopState.loaded(products), 
              ShopState.loaded([electronicsProduct]))).called(1);
      });
    });
  });
}