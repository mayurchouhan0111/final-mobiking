class ParentCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String image;

  ParentCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
  });

  factory ParentCategoryModel.fromJson(Map<String, dynamic> json) {
    return ParentCategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'slug': slug, 'image': image};
  }
}
