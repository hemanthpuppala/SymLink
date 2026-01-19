import 'package:equatable/equatable.dart';

enum SortBy {
  distance('distance'),
  tds('tds'),
  price('price'),
  name('name');

  final String value;
  const SortBy(this.value);
}

enum SortOrder {
  asc('asc'),
  desc('desc');

  final String value;
  const SortOrder(this.value);
}

class PlantFilter extends Equatable {
  final bool openNow;
  final bool verifiedOnly;
  final int? minTds;
  final int? maxTds;
  final double? minPrice;
  final double? maxPrice;
  final SortBy sortBy;
  final SortOrder sortOrder;

  const PlantFilter({
    this.openNow = false,
    this.verifiedOnly = false,
    this.minTds,
    this.maxTds,
    this.minPrice,
    this.maxPrice,
    this.sortBy = SortBy.distance,
    this.sortOrder = SortOrder.asc,
  });

  PlantFilter copyWith({
    bool? openNow,
    bool? verifiedOnly,
    int? minTds,
    int? maxTds,
    double? minPrice,
    double? maxPrice,
    SortBy? sortBy,
    SortOrder? sortOrder,
    bool clearMinTds = false,
    bool clearMaxTds = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return PlantFilter(
      openNow: openNow ?? this.openNow,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      minTds: clearMinTds ? null : (minTds ?? this.minTds),
      maxTds: clearMaxTds ? null : (maxTds ?? this.maxTds),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (openNow) params['openNow'] = true;
    if (verifiedOnly) params['verifiedOnly'] = true;
    if (minTds != null) params['minTds'] = minTds;
    if (maxTds != null) params['maxTds'] = maxTds;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    params['sortBy'] = sortBy.value;
    params['sortOrder'] = sortOrder.value;

    return params;
  }

  bool get hasActiveFilters =>
    openNow ||
    verifiedOnly ||
    minTds != null ||
    maxTds != null ||
    minPrice != null ||
    maxPrice != null;

  int get activeFilterCount {
    int count = 0;
    if (openNow) count++;
    if (verifiedOnly) count++;
    if (minTds != null || maxTds != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
    openNow,
    verifiedOnly,
    minTds,
    maxTds,
    minPrice,
    maxPrice,
    sortBy,
    sortOrder,
  ];
}
