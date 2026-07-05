class Service {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final int fixedPrice;
  final int estimatedMinutes;
  final String description;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.fixedPrice,
    required this.estimatedMinutes,
    required this.description,
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      fixedPrice: json['fixed_price'] ?? 0,
      estimatedMinutes: json['estimated_minutes'] ?? 0,
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sub_category': subCategory,
      'fixed_price': fixedPrice,
      'estimated_minutes': estimatedMinutes,
      'description': description,
      'is_active': isActive,
    };
  }
}