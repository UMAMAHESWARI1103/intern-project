import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AdminProductManagementPage extends StatefulWidget {
  const AdminProductManagementPage({super.key});

  @override
  State<AdminProductManagementPage> createState() =>
      _AdminProductManagementPageState();
}

class _AdminProductManagementPageState
    extends State<AdminProductManagementPage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);
  static const Color _accent   = Color(0xFFFFE0B2);

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Pooja Items & Flowers',
    'Religious Books & CDs',
    'Idols & Statues',
    'Prasadam / Ootee',
    'Devotee Dresses',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final products = await ApiService.getAdminProducts();
      if (mounted) setState(() { _products = products; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered => _products.where((p) {
    final matchCat = _selectedCategory == 'All' ||
        (p['category'] ?? '') == _selectedCategory;
    final matchSearch = _searchQuery.isEmpty ||
        (p['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (p['category'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    return matchCat && matchSearch;
  }).toList();

  void _openAddEdit({Map<String, dynamic>? product}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductFormPage(
          product: product,
          categories: _categories.where((c) => c != 'All').toList(),
        ),
      ),
    );
    if (result == true) _loadProducts();
  }

  Future<void> _deleteProduct(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final success = await ApiService.deleteProduct(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Product deleted' : 'Failed to delete'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        if (success) _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> product) async {
    final newStatus = !(product['isActive'] as bool? ?? true);
    try {
      final success = await ApiService.updateProduct(
          product['_id'] as String, {'isActive': newStatus});
      if (mounted && success) _loadProducts();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('E-Commerce Products',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        onPressed: () => _openAddEdit(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _errorView()
              : Column(children: [
                  _buildSearchBar(),
                  _buildCategoryBar(),
                  _buildStatsRow(),
                  Expanded(child: _buildProductList()),
                ]),
    );
  }

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(_error ?? 'Error',
            style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _loadProducts,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(
            backgroundColor: _primary, foregroundColor: Colors.white),
      ),
    ]),
  );

  Widget _buildSearchBar() => Container(
    color: _primary,
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
  );

  Widget _buildCategoryBar() => Container(
    height: 44,
    color: Colors.white,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: _categories.length,
      itemBuilder: (_, i) {
        final cat = _categories[i];
        final selected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? _primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? _primary : Colors.grey.shade300),
            ),
            child: Text(cat.split(' ').first,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black87)),
          ),
        );
      },
    ),
  );

  Widget _buildStatsRow() {
    final total      = _products.length;
    final active     = _products.where((p) => p['isActive'] as bool? ?? true).length;
    final outOfStock = _products.where((p) => ((p['stock'] as num?)?.toInt() ?? 0) == 0).length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(children: [
        _statChip('Total', total, Colors.blue),
        const SizedBox(width: 8),
        _statChip('Active', active, Colors.green),
        const SizedBox(width: 8),
        _statChip('Out of Stock', outOfStock, Colors.red),
        const Spacer(),
        Text('${_filtered.length} shown',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ]),
    );
  }

  Widget _statChip(String label, int value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text('$label: $value',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _buildProductList() {
    final products = _filtered;
    if (products.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No products found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _openAddEdit(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Product'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: products.length,
        itemBuilder: (_, i) => _ProductTile(
          product: products[i],
          onEdit: () => _openAddEdit(product: products[i]),
          onDelete: () => _deleteProduct(
              products[i]['_id'] as String,
              products[i]['name'] as String? ?? ''),
          onToggleActive: () => _toggleActive(products[i]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT TILE
// ═══════════════════════════════════════════════════════════════
class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  static const Color _primary  = Color(0xFFFF9933);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);
  static const Color _accent   = Color(0xFFFFE0B2);

  @override
  Widget build(BuildContext context) {
    final isActive      = product['isActive'] as bool? ?? true;
    final price         = (product['price'] as num?)?.toDouble() ?? 0;
    final originalPrice = (product['originalPrice'] as num?)?.toDouble() ?? 0;
    final stock         = (product['stock'] as num?)?.toInt() ?? 0;
    final discount      = originalPrice > price
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;
    final isBestseller  = product['isBestseller'] as bool? ?? false;
    final imageUrl      = product['imageUrl'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? _accent : Colors.grey.shade200),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72, height: 72,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback(),
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(color: const Color(0xFFFFF3E0),
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primary))))
                  : _imgFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(product['name'] as String? ?? 'Unnamed',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (isBestseller)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(6)),
                    child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(product['category'] as String? ?? '',
                  style: const TextStyle(fontSize: 11, color: _textGrey)),
              const SizedBox(height: 5),
              Row(children: [
                Text('₹${price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primary)),
                if (discount > 0) ...[
                  const SizedBox(width: 6),
                  Text('₹${originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 4),
                  Text('$discount% off',
                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(
                  stock > 10 ? Icons.check_circle_outline
                      : stock > 0 ? Icons.warning_amber_outlined
                      : Icons.cancel_outlined,
                  size: 13,
                  color: stock > 10 ? Colors.green : stock > 0 ? Colors.orange : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  stock > 10 ? 'In Stock ($stock)' : stock > 0 ? 'Low Stock ($stock)' : 'Out of Stock',
                  style: TextStyle(fontSize: 10,
                      color: stock > 10 ? Colors.green : stock > 0 ? Colors.orange : Colors.red),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: onToggleActive,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(isActive ? 'Active' : 'Hidden',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green : Colors.grey)),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined, size: 16, color: _primary),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                ),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _imgFallback() => Container(
    color: const Color(0xFFFFE0B2),
    child: const Center(child: Icon(Icons.shopping_bag_outlined, color: _primary, size: 28)),
  );
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT FORM PAGE (Add / Edit)
// ═══════════════════════════════════════════════════════════════
class _ProductFormPage extends StatefulWidget {
  const _ProductFormPage({this.product, required this.categories});
  final Map<String, dynamic>? product;
  final List<String> categories;
  @override
  State<_ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<_ProductFormPage> {
  static const Color _primary = Color(0xFFFF9933);
  static const Color _bg      = Color(0xFFFFF8F0);

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _originalPriceCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _tagsCtrl;

  String? _selectedCategory;
  bool _isBestseller = false;
  bool _isActive     = true;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl          = TextEditingController(text: p?['name']        as String? ?? '');
    _descCtrl          = TextEditingController(text: p?['description'] as String? ?? '');
    _priceCtrl         = TextEditingController(text: p != null ? (p['price']         as num?)?.toString() ?? '' : '');
    _originalPriceCtrl = TextEditingController(text: p != null ? (p['originalPrice'] as num?)?.toString() ?? '' : '');
    _imageUrlCtrl      = TextEditingController(text: p?['imageUrl']    as String? ?? '');
    _stockCtrl         = TextEditingController(text: p != null ? (p['stock']         as num?)?.toString() ?? '0' : '0');
    _tagsCtrl          = TextEditingController(text: p != null ? ((p['tags'] as List?)?.join(', ') ?? '') : '');
    _selectedCategory  = p?['category'] as String? ?? widget.categories.first;
    _isBestseller      = p?['isBestseller'] as bool? ?? false;
    _isActive          = p?['isActive']     as bool? ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _originalPriceCtrl.dispose(); _imageUrlCtrl.dispose();
    _stockCtrl.dispose(); _tagsCtrl.dispose();
    super.dispose();
  }

  // ✅ FIXED _save: always loads token first, shows real error message
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // ✅ FIX 1: Always load token from SharedPreferences before making request
    await ApiService.loadToken();

    final tags = _tagsCtrl.text.trim().isEmpty
        ? <String>[]
        : _tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final data = {
      'name':          _nameCtrl.text.trim(),
      'description':   _descCtrl.text.trim(),
      'price':         double.tryParse(_priceCtrl.text.trim()) ?? 0,
      'originalPrice': double.tryParse(_originalPriceCtrl.text.trim()) ?? 0,
      'imageUrl':      _imageUrlCtrl.text.trim(),
      'stock':         int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'category':      _selectedCategory,
      'tags':          tags,
      'isBestseller':  _isBestseller,
      'isActive':      _isActive,
    };

    try {
      if (_isEdit) {
        final success = await ApiService.updateProduct(
            widget.product!['_id'] as String, data);
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Product updated! ✓' : 'Failed to update'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        if (success) Navigator.pop(context, true);
      } else {
        final result = await ApiService.addProduct(data);
        if (!mounted) return;
        setState(() => _isSaving = false);
        // ✅ FIX 2: result is the full response body — check for product._id
        final saved = result != null &&
            (result['product'] != null || result['_id'] != null || result['message'] != null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(saved ? 'Product added! ✓' : 'Failed to add product'),
          backgroundColor: saved ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        if (saved) Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      // ✅ FIX 3: Show the REAL server error (401, 403, 404, validation, etc.)
      final msg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $msg'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Product' : 'Add New Product',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // Image preview
            AnimatedBuilder(
              animation: _imageUrlCtrl,
              builder: (_, __) => _imageUrlCtrl.text.isNotEmpty
                  ? Container(
                      height: 160, width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(_imageUrlCtrl.text, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFFFE0B2),
                              child: const Center(child: Icon(Icons.broken_image, color: _primary, size: 48)))))
                  : const SizedBox(),
            ),

            // Basic Info
            _sectionCard('📦 Basic Information', [
              _field('Product Name *', _nameCtrl, Icons.shopping_bag_outlined,
                  validator: (v) => v!.trim().isEmpty ? 'Enter product name' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: const Icon(Icons.category_outlined, color: _primary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 12),
              _field('Description *', _descCtrl, Icons.description_outlined,
                  maxLines: 4,
                  validator: (v) => v!.trim().isEmpty ? 'Enter description' : null),
            ]),
            const SizedBox(height: 14),

            // Pricing & Stock
            _sectionCard('💰 Pricing & Stock', [
              Row(children: [
                Expanded(child: _field('Price (₹) *', _priceCtrl, Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    })),
                const SizedBox(width: 12),
                Expanded(child: _field('Original Price (₹)', _originalPriceCtrl, Icons.price_change_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.trim().isNotEmpty && double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    })),
              ]),
              const SizedBox(height: 12),
              _field('Stock Quantity *', _stockCtrl, Icons.inventory_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'Required';
                    if (int.tryParse(v.trim()) == null) return 'Invalid';
                    return null;
                  }),
            ]),
            const SizedBox(height: 14),

            // Image & Tags
            _sectionCard('🖼️ Image & Tags', [
              _field('Image URL', _imageUrlCtrl, Icons.image_outlined,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 4),
              const Text('Paste a public image URL (e.g. from Cloudinary or S3)',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              _field('Tags (comma separated)', _tagsCtrl, Icons.label_outline),
              const SizedBox(height: 4),
              const Text('e.g. Brass, Handcrafted, Temple Wear',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
            const SizedBox(height: 14),

            // Settings
            _sectionCard('⚙️ Settings', [
              SwitchListTile.adaptive(
                title: const Text('Mark as Bestseller',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Shows "BESTSELLER" badge on product',
                    style: TextStyle(fontSize: 12)),
                value: _isBestseller,
                activeColor: _primary,
                onChanged: (v) => setState(() => _isBestseller = v),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                title: const Text('Active / Visible',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Product will be shown to users',
                    style: TextStyle(fontSize: 12)),
                value: _isActive,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_isEdit ? 'Update Product' : 'Add Product',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  Widget _field(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1,
       String? Function(String?)? validator, void Function(String)? onChanged}) =>
      TextFormField(
        controller: controller, keyboardType: keyboardType,
        maxLines: maxLines, validator: validator, onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
}