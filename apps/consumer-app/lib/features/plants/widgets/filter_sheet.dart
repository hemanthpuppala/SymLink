import 'package:flutter/material.dart';
import '../models/plant_filter.dart';

class FilterSheet extends StatefulWidget {
  final PlantFilter initialFilter;
  final Function(PlantFilter) onApply;

  const FilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required PlantFilter initialFilter,
    required Function(PlantFilter) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterSheet(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late PlantFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = const PlantFilter();
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('Quick Filters'),
                const SizedBox(height: 12),
                _buildToggleChip(
                  label: 'Open Now',
                  isSelected: _filter.openNow,
                  onTap: () {
                    setState(() {
                      _filter = _filter.copyWith(openNow: !_filter.openNow);
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildToggleChip(
                  label: 'Verified Only',
                  isSelected: _filter.verifiedOnly,
                  onTap: () {
                    setState(() {
                      _filter = _filter.copyWith(verifiedOnly: !_filter.verifiedOnly);
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Sort By'),
                const SizedBox(height: 12),
                _buildSortOptions(),
                const SizedBox(height: 24),
                _buildSectionTitle('TDS Level (ppm)'),
                const SizedBox(height: 12),
                _buildTdsRange(),
                const SizedBox(height: 24),
                _buildSectionTitle('Price per Liter'),
                const SizedBox(height: 12),
                _buildPriceRange(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(_filter);
                      Navigator.pop(context);
                    },
                    child: Text(
                      _filter.hasActiveFilters
                          ? 'Apply (${_filter.activeFilterCount})'
                          : 'Apply',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSortChip(SortBy.distance, 'Distance'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSortChip(SortBy.tds, 'TDS'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSortChip(SortBy.price, 'Price'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSortChip(SortBy.name, 'Name'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOrderChip(SortOrder.asc, 'Ascending'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOrderChip(SortOrder.desc, 'Descending'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(SortBy sortBy, String label) {
    final isSelected = _filter.sortBy == sortBy;
    return InkWell(
      onTap: () {
        setState(() {
          _filter = _filter.copyWith(sortBy: sortBy);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderChip(SortOrder sortOrder, String label) {
    final isSelected = _filter.sortOrder == sortOrder;
    return InkWell(
      onTap: () {
        setState(() {
          _filter = _filter.copyWith(sortOrder: sortOrder);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sortOrder == SortOrder.asc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTdsRange() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Min TDS',
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            controller: TextEditingController(
              text: _filter.minTds?.toString() ?? '',
            ),
            onChanged: (value) {
              final tds = int.tryParse(value);
              setState(() {
                _filter = _filter.copyWith(
                  minTds: tds,
                  clearMinTds: tds == null,
                );
              });
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('-'),
        ),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max TDS',
              hintText: '500',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            controller: TextEditingController(
              text: _filter.maxTds?.toString() ?? '',
            ),
            onChanged: (value) {
              final tds = int.tryParse(value);
              setState(() {
                _filter = _filter.copyWith(
                  maxTds: tds,
                  clearMaxTds: tds == null,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRange() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Min Price',
              hintText: '0',
              prefixText: '\u20B9 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            controller: TextEditingController(
              text: _filter.minPrice?.toString() ?? '',
            ),
            onChanged: (value) {
              final price = double.tryParse(value);
              setState(() {
                _filter = _filter.copyWith(
                  minPrice: price,
                  clearMinPrice: price == null,
                );
              });
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('-'),
        ),
        Expanded(
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Max Price',
              hintText: '10',
              prefixText: '\u20B9 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            controller: TextEditingController(
              text: _filter.maxPrice?.toString() ?? '',
            ),
            onChanged: (value) {
              final price = double.tryParse(value);
              setState(() {
                _filter = _filter.copyWith(
                  maxPrice: price,
                  clearMaxPrice: price == null,
                );
              });
            },
          ),
        ),
      ],
    );
  }
}
