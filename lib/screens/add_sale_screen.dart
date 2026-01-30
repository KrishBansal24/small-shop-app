import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/providers/inventory_provider.dart';
import 'package:shop_app/services/mongodb_service.dart';
import 'package:shop_app/utils/app_theme.dart';
import 'package:shop_app/widgets/custom_button.dart';
import 'package:shop_app/widgets/custom_textfield.dart';
import 'package:shop_app/widgets/selection_card.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _amountController = TextEditingController(text: "0.00");
  final _descriptionController = TextEditingController();
  String _paymentMode = 'Cash';
  String _platform = 'Offline';
  bool _isLoading = false;

  // Use a map to track quantity for each product ID
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<InventoryProvider>(
        context,
        listen: false,
      ).fetchProducts(),
    );
  }

  void _calculateTotal() {
    double total = 0;
    final provider = Provider.of<InventoryProvider>(context, listen: false);

    _cart.forEach((productId, quantity) {
      final product = provider.products.firstWhere(
        (p) => p.id.toHexString() == productId,
      );
      total += (product.price * quantity);
    });

    _amountController.text = total.toStringAsFixed(2);
  }

  void _addItem(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Out of Stock!")));
      return;
    }

    final currentQty = _cart[product.id.toHexString()] ?? 0;
    if (currentQty >= product.stock) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Maximum stock reached!")));
      return;
    }

    setState(() {
      _cart[product.id.toHexString()] = currentQty + 1;
      _calculateTotal();
    });
  }

  void _removeItem(Product product) {
    final productId = product.id.toHexString();
    if (!_cart.containsKey(productId)) return;

    setState(() {
      if (_cart[productId]! > 1) {
        _cart[productId] = _cart[productId]! - 1;
      } else {
        _cart.remove(productId);
      }
      _calculateTotal();
    });
  }

  void _submitSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one item"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      List<Map<String, dynamic>> saleItems = [];
      String description = _descriptionController.text;

      if (description.isEmpty) {
        // Auto-generate description if empty
        description = "Sale: ";
      }

      for (var entry in _cart.entries) {
        final product = provider.products.firstWhere(
          (p) => p.id.toHexString() == entry.key,
        );

        if (_descriptionController.text.isEmpty) {
          description += "${product.name} (${entry.value}), ";
        }

        saleItems.add({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'quantity': entry.value,
        });

        // Deduct stock
        await MongoDatabase.updateStock(product.id, -entry.value);
      }

      // Add Sale Record
      await MongoDatabase.addSale(
        double.parse(_amountController.text),
        description.trimRight().replaceAll(RegExp(r',$'), ''), // cleanup
        _paymentMode,
        _platform,
        items: saleItems,
      );

      // Refresh products locally
      if (mounted) {
        provider.fetchProducts();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sale Added Successfully!"),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("New Sale", style: AppTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left Side: Product Selection (Scrollable)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Select Items", style: AppTheme.subHeadingStyle),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Consumer<InventoryProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading && provider.products.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: provider.products.length,
                        itemBuilder: (context, index) {
                          final product = provider.products[index];
                          final qtyInCart =
                              _cart[product.id.toHexString()] ?? 0;
                          final isOutOfStock = product.stock <= 0;

                          return GestureDetector(
                            onTap: () =>
                                isOutOfStock ? null : _addItem(product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: qtyInCart > 0
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.primaryColor
                                        .withOpacity(0.1),
                                    child: Text(
                                      product.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text("₹${product.price.toStringAsFixed(0)}"),
                                  Text(
                                    isOutOfStock
                                        ? "Out of Stock"
                                        : "Stock: ${product.stock}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isOutOfStock
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (qtyInCart > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "$qtyInCart selected",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Side: Cart & Checkout (Fixed width or Expanded)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(-4, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Cart",
                    style: AppTheme.headingStyle.copyWith(fontSize: 20),
                  ),
                  const Divider(),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text("Cart is empty"))
                        : Consumer<InventoryProvider>(
                            builder: (context, provider, _) {
                              return ListView.builder(
                                itemCount: _cart.length,
                                itemBuilder: (context, index) {
                                  final productId = _cart.keys.elementAt(index);
                                  final quantity = _cart.values.elementAt(
                                    index,
                                  );
                                  final product = provider.products.firstWhere(
                                    (p) => p.id.toHexString() == productId,
                                  );

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "₹${product.price} x $quantity",
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => _removeItem(product),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle,
                                            size: 20,
                                            color: AppTheme.primaryColor,
                                          ),
                                          onPressed: () => _addItem(product),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "₹${_amountController.text}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descriptionController,
                    label: "Customer / Notes",
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: "Complete Sale",
                    onPressed: _submitSale,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
