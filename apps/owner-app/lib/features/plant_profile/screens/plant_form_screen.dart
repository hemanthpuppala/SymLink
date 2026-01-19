import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlantFormScreen extends StatefulWidget {
  final String? plantId;

  const PlantFormScreen({super.key, this.plantId});

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tdsController = TextEditingController();
  final _priceController = TextEditingController();
  final _hoursController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  bool get isEditing => widget.plantId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _tdsController.dispose();
    _priceController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _savePlant() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement save functionality with repository
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Plant updated!' : 'Plant created!'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Plant' : 'Add Plant'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plant Name',
                prefixIcon: Icon(Icons.water_drop_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter plant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(
                  _latitude != null && _longitude != null
                      ? 'Location: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                      : 'Select Location on Map',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Open map picker
                  setState(() {
                    _latitude = 12.9716;
                    _longitude = 77.5946;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location selected (demo)')),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Water Quality & Pricing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tdsController,
                    decoration: const InputDecoration(
                      labelText: 'TDS Level',
                      prefixIcon: Icon(Icons.science_outlined),
                      suffixText: 'ppm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per Liter',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(
                labelText: 'Operating Hours',
                prefixIcon: Icon(Icons.schedule_outlined),
                hintText: 'e.g., 9:00 AM - 6:00 PM',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: InkWell(
                onTap: () {
                  // TODO: Implement photo picker
                },
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Add Photos', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePlant,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Plant' : 'Create Plant'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
