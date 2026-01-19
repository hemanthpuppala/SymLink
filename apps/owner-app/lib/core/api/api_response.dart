class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiMeta? meta;
  final String timestamp;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.meta,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      message: json['message'],
      meta: json['meta'] != null ? ApiMeta.fromJson(json['meta']) : null,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class ApiMeta {
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;

  ApiMeta({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
    );
  }
}

class ApiError {
  final bool success;
  final String message;
  final int statusCode;
  final String? error;
  final String timestamp;

  ApiError({
    required this.success,
    required this.message,
    required this.statusCode,
    this.error,
    required this.timestamp,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      statusCode: json['statusCode'] ?? 500,
      error: json['error'],
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}
