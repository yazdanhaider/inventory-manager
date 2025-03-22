import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_item.dart';
import '../blocs/inventory/inventory_bloc.dart';
import '../blocs/inventory/inventory_event.dart';
import '../blocs/inventory/inventory_state.dart';
import '../utils/ui_helpers.dart';
import '../widgets/shimmer_loading.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _thresholdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item'), elevation: 2),
      body: BlocListener<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryItemAdded) {
            setState(() {
              _isLoading = false;
            });
            UIHelpers.showSnackBar(
              context,
              message: 'Item added successfully!',
              isSuccess: true,
            );
            Navigator.pop(context);
          } else if (state is InventoryError) {
            setState(() {
              _isLoading = false;
            });
            UIHelpers.showSnackBar(
              context,
              message: 'Error: ${state.message}',
              isSuccess: false,
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section with shimmer effect when loading
                  _isLoading
                      ? ShimmerLoading(
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                      : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 48,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add New Inventory Item',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in the details below to add a new item to your inventory',
                              style: TextStyle(color: Colors.grey.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                  const SizedBox(height: 24),

                  // Form fields with shimmer effect when loading
                  _isLoading
                      ? Column(
                        children: [
                          const FormFieldShimmer(),
                          const SizedBox(height: 16),
                          const FormFieldShimmer(),
                          const SizedBox(height: 16),
                          const FormFieldShimmer(),
                          const SizedBox(height: 16),
                          const FormFieldShimmer(),
                        ],
                      )
                      : Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Item Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Item Name',
                                  hintText: 'Enter item name',
                                  prefixIcon: Icon(Icons.label),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter item name';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Initial Quantity',
                                  hintText: 'Enter initial quantity',
                                  prefixIcon: Icon(Icons.inventory_2),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter initial quantity';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  hintText: 'Enter price',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter price';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _thresholdController,
                                decoration: const InputDecoration(
                                  labelText: 'Low Stock Threshold',
                                  hintText: 'Enter threshold value',
                                  prefixIcon: Icon(Icons.warning_amber),
                                  helperText:
                                      'You will be notified when stock falls below this value',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter threshold value';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                  const SizedBox(height: 24),

                  // Submit button with shimmer effect
                  _isLoading
                      ? ShimmerLoading(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                      : ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitForm,
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: ShimmerLoading(child: Icon(Icons.add)),
                                )
                                : const Icon(Icons.add),
                        label: Text(_isLoading ? 'Adding...' : 'Add Item'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final name = _nameController.text;
      final quantity = int.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      final threshold = int.parse(_thresholdController.text);

      final item = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        quantity: quantity,
        price: price,
        threshold: threshold,
        lastUpdated: DateTime.now(),
      );

      context.read<InventoryBloc>().add(AddInventoryItemEvent(item));
    }
  }
}
