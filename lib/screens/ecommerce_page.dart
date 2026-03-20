import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════
class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final String description;
  final double rating;
  final int reviews;
  final bool isBestseller;
  final List<String> tags;
  final bool isFromDb;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.reviews,
    this.isBestseller = false,
    this.tags = const [],
    this.isFromDb = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id:            json['_id'] as String? ?? json['id'] as String? ?? '',
        name:          json['name'] as String? ?? '',
        category:      json['category'] as String? ?? '',
        price:         (json['price'] as num?)?.toDouble() ?? 0,
        originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
        imageUrl:      json['imageUrl'] as String? ?? '',
        description:   json['description'] as String? ?? '',
        rating:        (json['rating'] as num?)?.toDouble() ?? 4.5,
        reviews:       (json['reviews'] as num?)?.toInt() ?? 0,
        isBestseller:  json['isBestseller'] as bool? ?? false,
        tags:          (json['tags'] as List?)
                           ?.map((t) => t.toString())
                           .toList() ??
                       const [],
        isFromDb: true,
      );

  int get discountPercent => originalPrice > price
      ? ((originalPrice - price) / originalPrice * 100).round()
      : 0;
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY META
// ═══════════════════════════════════════════════════════════════
const List<Map<String, dynamic>> _categoryMeta = [
  {'label': 'All',                    'icon': Icons.category},
  {'label': 'Pooja Items & Flowers',  'icon': Icons.local_florist},
  {'label': 'Religious Books & CDs',  'icon': Icons.menu_book},
  {'label': 'Idols & Statues',        'icon': Icons.emoji_nature},
  {'label': 'Prasadam / Ootee',       'icon': Icons.restaurant},
  {'label': 'Devotee Dresses',        'icon': Icons.checkroom},
];

// ═══════════════════════════════════════════════════════════════
// HARDCODED FALLBACK PRODUCTS
// ═══════════════════════════════════════════════════════════════
String _ph(String bg, String text) =>
    'https://placehold.co/300x300/$bg/ffffff/png?text=${Uri.encodeComponent(text)}';

final List<Product> _hardcodedProducts = [
  Product(id: 'p1', name: 'Rose Garland', category: 'Pooja Items & Flowers',
      price: 49, originalPrice: 70, imageUrl: _ph('C2185B', 'Rose Garland'),
      description: 'Fresh rose garland for deity decoration. Made with hand-picked roses, ideal for daily pooja and temple offerings.',
      rating: 4.8, reviews: 124, isBestseller: true, tags: ['Fresh', 'Daily Pooja']),
  Product(id: 'p2', name: 'Marigold Flowers 500g', category: 'Pooja Items & Flowers',
      price: 30, originalPrice: 45, imageUrl: _ph('F57F17', 'Marigold'),
      description: 'Fresh marigold flowers 500g. Auspicious and widely used in Hindu rituals.',
      rating: 4.7, reviews: 98, tags: ['Fresh', 'Festival']),
  Product(id: 'p3', name: 'Camphor Tablets 100g', category: 'Pooja Items & Flowers',
      price: 55, originalPrice: 65, imageUrl: _ph('2E7D32', 'Camphor'),
      description: 'Pure camphor tablets 100g for aarti and purification rituals.',
      rating: 4.9, reviews: 210, isBestseller: true, tags: ['Pure', 'Aarti']),
  Product(id: 'p4', name: 'Premium Agarbatti Set', category: 'Pooja Items & Flowers',
      price: 120, originalPrice: 180, imageUrl: _ph('6A1B9A', 'Agarbatti'),
      description: 'Premium agarbatti set with 6 fragrances. 120 sticks total.',
      rating: 4.6, reviews: 176, tags: ['Fragrant', 'Set of 6']),
  Product(id: 'p5', name: 'Brass Diya Set of 4', category: 'Pooja Items & Flowers',
      price: 299, originalPrice: 399, imageUrl: _ph('FF6F00', 'Brass Diya'),
      description: 'Handcrafted solid brass diyas, set of 4.',
      rating: 4.8, reviews: 89, tags: ['Brass', 'Diwali']),
  Product(id: 'p6', name: 'Tulsi Mala (108 Beads)', category: 'Pooja Items & Flowers',
      price: 199, originalPrice: 250, imageUrl: _ph('388E3C', 'Tulsi Mala'),
      description: 'Authentic Tulsi mala with 108 beads for japa meditation.',
      rating: 4.9, reviews: 312, isBestseller: true, tags: ['Japa', 'Meditation']),
  Product(id: 'b1', name: 'Bhagavad Gita', category: 'Religious Books & CDs',
      price: 199, originalPrice: 249, imageUrl: _ph('1565C0', 'Bhagavad Gita'),
      description: 'Complete Bhagavad Gita with Sanskrit slokas and English commentary.',
      rating: 4.9, reviews: 412, isBestseller: true, tags: ['Sanskrit', 'Commentary']),
  Product(id: 'b2', name: 'Ramayana Illustrated', category: 'Religious Books & CDs',
      price: 349, originalPrice: 450, imageUrl: _ph('880E4F', 'Ramayana'),
      description: 'Full illustrated Ramayana in Tamil & English.',
      rating: 4.8, reviews: 287, tags: ['Illustrated', 'Tamil & English']),
  Product(id: 'b4', name: 'Carnatic Devotional CD', category: 'Religious Books & CDs',
      price: 149, originalPrice: 199, imageUrl: _ph('283593', 'Carnatic CD'),
      description: 'Classic Carnatic devotional music CD. 12 tracks, 74 minutes.',
      rating: 4.9, reviews: 330, isBestseller: true, tags: ['MS Subbulakshmi', 'Classic']),
  Product(id: 'i1', name: 'Ganesha Brass Idol 6"', category: 'Idols & Statues',
      price: 799, originalPrice: 1100, imageUrl: _ph('E65100', 'Ganesha Idol'),
      description: 'Hand-crafted brass Ganesha idol, 6 inches tall.',
      rating: 4.9, reviews: 523, isBestseller: true, tags: ['Brass', '6 inch', 'Handcrafted']),
  Product(id: 'i2', name: 'Lakshmi Silver Idol 4"', category: 'Idols & Statues',
      price: 1499, originalPrice: 1999, imageUrl: _ph('37474F', 'Lakshmi Idol'),
      description: 'Pure silver-plated Lakshmi idol, 4 inches.',
      rating: 4.8, reviews: 267, tags: ['Silver Plated', 'Gift Box']),
  Product(id: 'i4', name: 'Krishna Flute Idol 5"', category: 'Idols & Statues',
      price: 649, originalPrice: 850, imageUrl: _ph('1B5E20', 'Krishna Idol'),
      description: 'Marble-finish Krishna idol with flute, 5 inches.',
      rating: 4.7, reviews: 314, isBestseller: true, tags: ['Marble Finish', 'Hand-painted']),
  Product(id: 'o1', name: 'Tirupati Ladoo (Pack 4)', category: 'Prasadam / Ootee',
      price: 250, originalPrice: 250, imageUrl: _ph('F57F17', 'Tirupati Ladoo'),
      description: 'Authentic Tirupati Venkateswara temple ladoo. Pack of 4.',
      rating: 5.0, reviews: 876, isBestseller: true, tags: ['Authentic', 'Tirupati']),
  Product(id: 'o6', name: 'Sacred Vibhuti Pouch', category: 'Prasadam / Ootee',
      price: 75, originalPrice: 100, imageUrl: _ph('4E342E', 'Vibhuti'),
      description: 'Sacred vibhuti from Thiruvannamalai. 50g.',
      rating: 4.9, reviews: 345, isBestseller: true, tags: ['Thiruvannamalai', 'Sacred']),
  Product(id: 'd1', name: "Men's Dhoti & Angavastram", category: 'Devotee Dresses',
      price: 599, originalPrice: 850, imageUrl: _ph('455A64', 'Dhoti Set'),
      description: 'Pure cotton white dhoti with gold border. Traditional temple attire.',
      rating: 4.8, reviews: 324, isBestseller: true, tags: ['Pure Cotton', 'Temple Wear']),
  Product(id: 'd2', name: "Women's Silk Saree (Temple)", category: 'Devotee Dresses',
      price: 1299, originalPrice: 1800, imageUrl: _ph('AD1457', 'Silk Saree'),
      description: 'Traditional Kanchipuram-style silk saree for temple visits.',
      rating: 4.9, reviews: 567, isBestseller: true, tags: ['Silk', 'Kanchipuram Style']),
  Product(id: 'd5', name: "Men's Veshti (Premium)", category: 'Devotee Dresses',
      price: 799, originalPrice: 1100, imageUrl: _ph('212121', 'Veshti'),
      description: 'Premium Coimbatore cotton veshti with double gold border.',
      rating: 4.9, reviews: 412, isBestseller: true, tags: ['Coimbatore Cotton', 'Premium']),
  Product(id: 'd8', name: 'Rudraksha Bracelet', category: 'Devotee Dresses',
      price: 349, originalPrice: 500, imageUrl: _ph('4E342E', 'Rudraksha'),
      description: 'Authentic 5-mukhi rudraksha bracelet with silver capping.',
      rating: 4.9, reviews: 523, isBestseller: true, tags: ['Rudraksha', 'Certified']),
];

// ═══════════════════════════════════════════════════════════════
// CART PROVIDER
// ═══════════════════════════════════════════════════════════════
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get total =>
      _items.fold(0.0, (sum, i) => sum + i.product.price * i.quantity);

  void addToCart(Product product) {
    final existing = _items.where((i) => i.product.id == product.id);
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void incrementQty(String productId) {
    final item = _items.firstWhere((i) => i.product.id == productId);
    item.quantity++;
    notifyListeners();
  }

  void decrementQty(String productId) {
    final item = _items.firstWhere((i) => i.product.id == productId);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.removeWhere((i) => i.product.id == productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT IMAGE WIDGET
// ═══════════════════════════════════════════════════════════════
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackLabel = '',
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFFFF3E0),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFFFF9933)),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFFFE0B2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.temple_hindu, size: 32, color: Color(0xFFFF9933)),
            if (fallbackLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  fallbackLabel,
                  style: const TextStyle(fontSize: 9, color: Colors.brown),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ECOMMERCE PAGE
// ═══════════════════════════════════════════════════════════════
class EcommercePage extends StatefulWidget {
  const EcommercePage({super.key});

  @override
  State<EcommercePage> createState() => _EcommercePageState();
}

class _EcommercePageState extends State<EcommercePage> {
  final CartProvider _cart = CartProvider();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery      = '';
  String _sortBy           = 'Popular';
  bool _isLoadingProducts  = true;
  List<Product> _allProducts = [];
  bool _isDbSource         = false;

  static const Color _primary = Color(0xFFFF9933);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final raw = await ApiService.getProducts();
      final dbProducts = raw
          .where((p) => p['isActive'] as bool? ?? true)
          .map((p) => Product.fromJson(p))
          .toList();

      final merged = [...dbProducts, ..._hardcodedProducts];

      if (mounted) {
        setState(() {
          _allProducts       = merged;
          _isDbSource        = dbProducts.isNotEmpty;
          _isLoadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allProducts       = _hardcodedProducts;
          _isDbSource        = false;
          _isLoadingProducts = false;
        });
      }
    }
  }

  List<Product> get _filtered {
    var list = _allProducts.where((p) {
      final matchCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchCat && matchSearch;
    }).toList();

    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Top Rated':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Discount':
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      default:
        list.sort((a, b) => b.reviews.compareTo(a.reviews));
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cart,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(),
        body: _isLoadingProducts
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : Column(children: [
                _buildSearchBar(),
                _buildCategoryBar(),
                _buildSortBar(),
                Expanded(child: _buildGrid()),
              ]),
        floatingActionButton: _cart.itemCount > 0
            ? FloatingActionButton.extended(
                backgroundColor: _primary,
                onPressed: _openCart,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  'Cart (${_cart.itemCount}) • ₹${_cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    elevation: 0,
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    title: const Row(children: [
      Icon(Icons.temple_hindu, color: Colors.white, size: 26),
      SizedBox(width: 8),
      Text('GodsConnect Store',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
    ]),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _loadProducts,
        tooltip: 'Refresh products',
      ),
      Stack(children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: _openCart,
        ),
        if (_cart.itemCount > 0)
          Positioned(
            right: 6, top: 6,
            child: Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: Center(
                child: Text('${_cart.itemCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ]),
      const SizedBox(width: 4),
    ],
  );

  Widget _buildSearchBar() => Container(
    color: _primary,
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search products, dresses, prasadam...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF9933)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
  );

  Widget _buildCategoryBar() => Container(
    height: 80,
    color: Colors.white,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: _categoryMeta.length,
      itemBuilder: (_, i) {
        final cat      = _categoryMeta[i]['label'] as String;
        final icon     = _categoryMeta[i]['icon'] as IconData;
        final selected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? _primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? _primary : Colors.grey.shade300),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16,
                  color: selected ? Colors.white : Colors.black87),
              const SizedBox(width: 6),
              Flexible(
                child: Text(cat.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87)),
              ),
            ]),
          ),
        );
      },
    ),
  );

  Widget _buildSortBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Row(children: [
      if (_isDbSource)
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_done, size: 11, color: Colors.green),
            SizedBox(width: 4),
            Text('Live', style: TextStyle(
                fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
          ]),
        ),
      Text('${_filtered.length} products',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      const Spacer(),
      const Icon(Icons.sort, size: 18, color: Color(0xFFFF9933)),
      const SizedBox(width: 6),
      DropdownButton<String>(
        value: _sortBy,
        underline: const SizedBox(),
        style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600),
        items: [
          'Popular', 'Top Rated', 'Price: Low to High',
          'Price: High to Low', 'Discount'
        ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _sortBy = v!),
      ),
    ]),
  );

  Widget _buildGrid() {
    final products = _filtered;
    if (products.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No products found for "$_searchQuery"',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() { _searchQuery = ''; _selectedCategory = 'All'; });
            },
            child: const Text('Clear filters',
                style: TextStyle(color: Color(0xFFFF9933))),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12,
          mainAxisSpacing: 12, childAspectRatio: 0.62,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => _ProductCard(
          product: products[i],
          cart: _cart,
          onTap: () => _openProductDetail(products[i]),
        ),
      ),
    );
  }

  void _openProductDetail(Product product) => Navigator.push(context,
      MaterialPageRoute(
          builder: (_) => ProductDetailPage(product: product, cart: _cart)));

  void _openCart() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => CartPage(cart: _cart)));
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT CARD
// ═══════════════════════════════════════════════════════════════
class _ProductCard extends StatelessWidget {
  const _ProductCard(
      {required this.product, required this.cart, required this.onTap});

  final Product product;
  final CartProvider cart;
  final VoidCallback onTap;
  static const Color _primary = Color(0xFFFF9933);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: ProductImage(
                    url: product.imageUrl,
                    fallbackLabel: product.name,
                    fit: BoxFit.cover),
              ),
            ),
            if (product.isBestseller)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('BESTSELLER',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            if (product.discountPercent > 0)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('${product.discountPercent}% OFF',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            if (product.isFromDb)
              Positioned(
                bottom: 6, right: 6,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.cloud_done,
                      color: Colors.white, size: 11),
                ),
              ),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text('${product.rating}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text('(${product.reviews})',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text('₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _primary)),
                    if (product.discountPercent > 0) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                            '₹${product.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ]),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        cart.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${product.name} added to cart 🛒'),
                          backgroundColor: _primary,
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Add to Cart',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT DETAIL PAGE
// ═══════════════════════════════════════════════════════════════
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage(
      {super.key, required this.product, required this.cart});

  final Product product;
  final CartProvider cart;
  static const Color _primary = Color(0xFFFF9933);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(product.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: double.infinity,
            height: 260,
            child: ProductImage(
                url: product.imageUrl,
                fallbackLabel: product.name,
                fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(product.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold))),
                if (product.isBestseller)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('BESTSELLER',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                ...List.generate(
                    5,
                    (i) => Icon(
                        i < product.rating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20)),
                const SizedBox(width: 8),
                Text('${product.rating} (${product.reviews} reviews)',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14)),
              ]),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _primary)),
                if (product.discountPercent > 0) ...[
                  const SizedBox(width: 12),
                  Text('₹${product.originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green)),
                    child: Text('${product.discountPercent}% OFF',
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              const Text(
                  'Inclusive of all taxes. Free delivery on orders above ₹499.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              if (product.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.tags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _primary.withValues(alpha: 0.4)),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: _primary,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],
              const Divider(),
              const SizedBox(height: 14),
              const Text('About this product',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(product.description,
                  style: const TextStyle(
                      fontSize: 14, height: 1.6, color: Colors.black87)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 14),
              _infoRow(Icons.local_shipping_outlined,
                  'Free delivery on orders above ₹499'),
              const SizedBox(height: 10),
              _infoRow(Icons.verified_outlined,
                  'Genuine temple-sourced products'),
              const SizedBox(height: 10),
              _infoRow(Icons.autorenew_outlined, 'Easy 7-day return policy'),
              const SizedBox(height: 10),
              _infoRow(Icons.support_agent_outlined, '24/7 customer support'),
              const SizedBox(height: 30),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  cart.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Added to cart 🛒'),
                    backgroundColor: Color(0xFFFF9933),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ));
                },
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Add to Cart',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: Color(0xFFFF9933), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  cart.addToCart(product);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => CartPage(cart: cart)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Buy Now',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 20, color: const Color(0xFFFF9933)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ]);
}

// ═══════════════════════════════════════════════════════════════
// CART PAGE
// ═══════════════════════════════════════════════════════════════
class CartPage extends StatelessWidget {
  const CartPage({super.key, required this.cart});

  final CartProvider cart;
  static const Color _primary = Color(0xFFFF9933);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: Text('My Cart (${cart.itemCount} items)',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        body: cart.items.isEmpty
            ? _buildEmptyCart(context)
            : Column(children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) =>
                        _CartItemCard(item: cart.items[i], cart: cart),
                  ),
                ),
                _buildOrderSummary(context),
              ]),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
      const SizedBox(height: 20),
      const Text('Your cart is empty',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Add divine products to your cart',
          style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Continue Shopping',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ]),
  );

  Widget _buildOrderSummary(BuildContext context) {
    final subtotal   = cart.total;
    final delivery   = subtotal >= 499 ? 0.0 : 49.0;
    final gst        = subtotal * 0.05;
    final grandTotal = subtotal + delivery + gst;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
        const SizedBox(height: 6),
        _summaryRow('Delivery',
            delivery == 0 ? 'FREE' : '₹${delivery.toStringAsFixed(0)}',
            valueColor: delivery == 0 ? Colors.green : null),
        const SizedBox(height: 6),
        _summaryRow('GST (5%)', '₹${gst.toStringAsFixed(0)}'),
        const Divider(height: 20),
        _summaryRow('Grand Total', '₹${grandTotal.toStringAsFixed(0)}',
            isBold: true, valueColor: _primary),
        if (delivery > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                'Add ₹${(499 - subtotal).toStringAsFixed(0)} more for FREE delivery',
                style: const TextStyle(color: Colors.orange, fontSize: 12)),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        CheckoutPage(cart: cart, grandTotal: grandTotal))),
            icon: const Icon(Icons.payment, color: Colors.white),
            label: Text(
                'Proceed to Checkout ₹${grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _summaryRow(String label, String value,
          {bool isBold = false, Color? valueColor}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87)),
        Flexible(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? Colors.black87)),
        ),
      ]);
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item, required this.cart});

  final CartItem item;
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
        ],
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 70,
            height: 70,
            child: ProductImage(
                url: item.product.imageUrl,
                fallbackLabel: item.product.name,
                fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('₹${item.product.price.toStringAsFixed(0)} each',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              _qtyBtn(Icons.remove,
                  () => cart.decrementQty(item.product.id)),
              Container(
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFF9933)),
                    borderRadius: BorderRadius.circular(6)),
                child: Center(
                    child: Text('${item.quantity}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              _qtyBtn(Icons.add,
                  () => cart.incrementQty(item.product.id)),
              const Spacer(),
              Text(
                  '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFFFF9933))),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => cart.removeFromCart(item.product.id),
          child: const Icon(Icons.delete_outline,
              color: Colors.red, size: 22),
        ),
      ]),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFFF9933),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// CHECKOUT PAGE — Razorpay + MongoDB
// ═══════════════════════════════════════════════════════════════
class CheckoutPage extends StatefulWidget {
  const CheckoutPage(
      {super.key, required this.cart, required this.grandTotal});

  final CartProvider cart;
  final double grandTotal;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const Color _primary = Color(0xFFFF9933);

  late Razorpay _razorpay;
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _emailController   = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController    = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _paying = false;

  List<Map<String, dynamic>> _orderItemsSnapshot = [];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await ApiService.getUserProfile();
      if (!mounted || data == null) return;
      _nameController.text    = data['name']    ?? '';
      _phoneController.text   = data['phone']   ?? '';
      _emailController.text   = data['email']   ?? '';
      _addressController.text = data['address'] ?? '';
      _cityController.text    = data['city']    ?? '';
      _pincodeController.text = data['pincode'] ?? '';
      setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _startPayment() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _paying = true);

    // Snapshot cart items before payment
    _orderItemsSnapshot = widget.cart.items.map((item) => {
      'productId': item.product.id,
      'name':      item.product.name,      // ✅ 'name' matches schema
      'price':     item.product.price,
      'quantity':  item.quantity,           // ✅ 'quantity' matches schema
    }).toList();

    try {
      _razorpay.open({
        'key':         'rzp_test_SK0xB85zCUyk1j',
        'amount':      (widget.grandTotal * 100).toInt(),
        'name':        'GodsConnect Store',
        'description': 'Temple Products Order',
        'prefill': {
          'name':    _nameController.text.trim(),
          'contact': _phoneController.text.trim(),
          'email':   _emailController.text.trim(),
        },
        'notes': {
          'address': _addressController.text.trim(),
          'city':    _cityController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        },
        'theme': {'color': '#FF9933'},
        'retry': {'enabled': true, 'max_count': 1},
      });
    } catch (e) {
      setState(() => _paying = false);
      _showSnack('Failed to initialize payment. Please try again.',
          isError: true);
    }
  }

  // ✅ FIXED: all field names now match the Order schema in orders.js
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final orderData = {
      // User info
      'userName':        _nameController.text.trim(),
      'userPhone':       _phoneController.text.trim(),
      'userEmail':       _emailController.text.trim(),

      // ✅ Combine address fields into deliveryAddress
      'deliveryAddress':
          '${_addressController.text.trim()}, ${_cityController.text.trim()} - ${_pincodeController.text.trim()}',

      // ✅ Items — field names match schema: 'name', 'quantity'
      'items': _orderItemsSnapshot,

      // ✅ 'totalAmount' matches schema — was 'grandTotal' before (WRONG)
      'totalAmount': widget.grandTotal,

      // ✅ 'razorpayPaymentId' matches schema — was 'paymentId' before (WRONG)
      'razorpayPaymentId': response.paymentId  ?? '',
      'razorpayOrderId':   response.orderId    ?? '',
      'razorpaySignature': response.signature  ?? '',

      'paymentStatus': 'paid',

      // ✅ 'status' matches schema — was 'orderStatus' before (WRONG)
      'status': 'confirmed',
    };

    try {
      // ✅ Use loadToken() not getToken() — ensures token is loaded from storage
      final token = await ApiService.loadToken();
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/orders'),
        headers: {
          'Content-Type':  'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );
      debugPrint('✅ Order saved: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('❌ Order save error: $e');
    }

    widget.cart.clear();
    setState(() => _paying = false);
    _showOrderSuccess(response.paymentId ?? 'N/A');
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _paying = false);
    _showSnack(
      response.code == 2
          ? 'Payment cancelled'
          : 'Payment failed: ${response.message}',
      isError: true,
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) =>
      _showSnack('Processing with ${response.walletName}...');

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  void _showOrderSuccess(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded,
                size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Order Placed! 🙏',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                'Payment ID: ${paymentId.length > 10 ? paymentId.substring(0, 10) : paymentId}...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
                'Your divine products will be delivered within 3–5 working days.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Order Summary ──
            _sectionCard(
                title: '📦 Order Summary',
                child: Column(children: [
                  ...widget.cart.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: ProductImage(
                                  url: item.product.imageUrl,
                                  fallbackLabel: item.product.name,
                                  fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(item.product.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)),
                          Text('x${item.quantity}',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13)),
                          const SizedBox(width: 10),
                          Text(
                              '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ]),
                      )),
                  const Divider(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₹${widget.grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _primary)),
                      ]),
                ])),
            const SizedBox(height: 16),

            // ── Delivery Details ──
            _sectionCard(
                title: '🏠 Delivery Details',
                child: Column(children: [
                  _field('Full Name', _nameController,
                      Icons.person_outline,
                      validator: (v) => v!.trim().isEmpty
                          ? 'Enter your name'
                          : null),
                  const SizedBox(height: 12),
                  _field('Mobile Number', _phoneController,
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'Enter mobile number';
                        if (v.trim().length < 10) return 'Enter 10-digit number';
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _field('Email Address', _emailController,
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'Enter email';
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Enter valid email';
                        }
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _field('Full Address', _addressController,
                      Icons.location_on_outlined,
                      maxLines: 3,
                      validator: (v) => v!.trim().isEmpty
                          ? 'Enter delivery address'
                          : null),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _field('City', _cityController,
                            Icons.location_city_outlined,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Required' : null)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field('Pincode', _pincodeController,
                            Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v!.trim().isEmpty) return 'Required';
                              if (v.trim().length != 6) return '6-digit pincode';
                              return null;
                            })),
                  ]),
                ])),
            const SizedBox(height: 16),

            // ── Payment Info ──
            _sectionCard(
                title: '💳 Payment',
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _primary.withValues(alpha: 0.4)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.lock, color: Color(0xFFFF9933), size: 24),
                      SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Secure Payment via Razorpay',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            SizedBox(height: 4),
                            Text('UPI • Cards • Net Banking • Wallets',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ])),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _payChip(Icons.credit_card, 'Card'),
                    const SizedBox(width: 8),
                    _payChip(Icons.phone_android, 'UPI'),
                    const SizedBox(width: 8),
                    _payChip(Icons.account_balance, 'Net Banking'),
                    const SizedBox(width: 8),
                    _payChip(Icons.account_balance_wallet, 'Wallet'),
                  ]),
                ])),
            const SizedBox(height: 24),

            // ── Pay Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _paying ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _paying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        'Pay ₹${widget.grandTotal.toStringAsFixed(0)} Securely 🙏',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
                child: Text(
              'By placing order you agree to our Terms & Conditions',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            )),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ]),
      );

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
        ),
      );

  Widget _payChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: const Color(0xFFFF9933)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600)),
        ]),
      );
}