import 'dart:convert';

class AddressModel {
  String? id;
  String label;
  String street;
  String city;
  String state;
  String pinCode;

  AddressModel({
    this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.state,
    required this.pinCode,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] as String?,
      label: json['label'] as String,
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pinCode: json['pinCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'pinCode': pinCode,
    };
    if (id != null) {
      data['_id'] = id;
    }
    return data;
  }

  @override
  String toString() {
    return 'AddressModel(id: $id, label: $label, street: $street, city: $city, state: $state, pinCode: $pinCode)';
  }
}
