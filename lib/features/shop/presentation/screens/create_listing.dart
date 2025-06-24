import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_flutter_app/features/shop/domain/models/product.dart';
import 'package:my_flutter_app/features/shop/presentation/controllers/shop_controller.dart';
import 'package:my_flutter_app/core/utils/validators.dart';
import 'package:my_flutter_app/core/utils/extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final ShopController _controller = Get.find();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  
  String? _selectedCategory;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _controller.loadCategories();
  }

  Future<void> _pickImages() async {
    final images = await _controller.pickProductImages();
    if (images != null) {
      setState(() => _imageUrls = images);
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      Get.snackbar('Images Required', 'Please add at least one product image');
      return;
    }

    final product = Product(
      id: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _selectedCategory ?? '',
      stock: int.parse(_stockController.text.trim()),
      imageUrls: _imageUrls,
      sellerId: _controller.currentUserId,
      sellerName: _controller.currentUserName,
      createdAt: DateTime.now(),
      rating: 0.0,
      reviewCount: 0,
    );

    await _controller.createProductListing(product);
    Get.back();
  }

  Widget _buildImageGrid() {
    if (_imageUrls.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 48),
              SizedBox(height: 8),
              Text('Add Product Images'),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _imageUrls.length + 1,
      itemBuilder: (context, index) {
        if (index == _imageUrls.length) {
          return GestureDetector(
            onTap: _pickImages,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add),
            ),
          );
        }
        
        return Stack(
          children: [
            CachedNetworkImage(
              imageUrl: _imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() => _imageUrls.removeAt(index));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(() {
      final categories = _controller.categories;
      return DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
        ),
        items: categories.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category.capitalize()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedCategory = value);
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a category';
          }
          return null;
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageGrid(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateNotEmpty(value, 'Product name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validatePrice(value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validatePositiveNumber(value, 'Stock'),
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => Validators.validateNotEmpty(value, 'Description'),
              ),
              const SizedBox(height: 32),
              Obx(() {
                return ElevatedButton(
                  onPressed: _controller.isLoading.value ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Listing',
                          style: TextStyle(fontSize: 18),
                        ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}