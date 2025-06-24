import 'package:flutter/material.dart';

class WidgetsShowcaseScreen extends StatelessWidget {
  const WidgetsShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Widgets Showcase'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Button Variants'),
            const SizedBox(height: 16),
            _buildButtonVariants(),
            const SizedBox(height: 32),
            _buildSectionTitle('App Bar Variants'),
            const SizedBox(height: 16),
            _buildAppBarVariants(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildButtonVariants() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        AppButton.primary(
          label: 'Primary',
          onPressed: () {},
        ),
        AppButton.secondary(
          label: 'Secondary',
          onPressed: () {},
        ),
        AppButton.text(
          label: 'Text Button',
          onPressed: () {},
        ),
        AppButton.icon(
          icon: Icons.favorite,
          onPressed: () {},
        ),
        AppButton.primary(
          label: 'Loading',
          onPressed: () {},
          isLoading: true,
        ),
        AppButton.primary(
          label: 'With Icon',
          icon: Icons.add,
          onPressed: () {},
        ),
        AppButton.primary(
          label: 'Disabled',
          onPressed: null,
        ),
        AppButton.primary(
          label: 'Custom',
          backgroundColor: Colors.purple,
          textColor: Colors.white,
          height: 60,
          borderRadius: 30,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildAppBarVariants(BuildContext context) {
    return Column(
      children: [
        const Card(
          child: ListTile(
            title: Text('CustomAppBar'),
            subtitle: Text('Standard app bar with back button'),
          ),
        ),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            title: Text('AdminAppBar'),
            subtitle: Text('App bar with admin styling'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            title: const Text('SearchAppBar'),
            subtitle: const Text('App bar with search field'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: SearchAppBar(
                      hintText: 'Search products...',
                      onSearchChanged: (query) {
                        debugPrint('Search query: $query');
                      },
                    ),
                    body: const Center(child: Text('Search results')),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}