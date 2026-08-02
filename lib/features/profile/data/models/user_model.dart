class NameModel {
  final String firstname;
  final String lastname;

  const NameModel({
    required this.firstname,
    required this.lastname,
  });

  String get fullName {
    final first = firstname.isNotEmpty
        ? '${firstname[0].toUpperCase()}${firstname.substring(1)}'
        : '';
    final last = lastname.isNotEmpty
        ? '${lastname[0].toUpperCase()}${lastname.substring(1)}'
        : '';
    return '$first $last'.trim();
  }

  String get initials {
    final f = firstname.isNotEmpty ? firstname[0].toUpperCase() : '';
    final l = lastname.isNotEmpty ? lastname[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? 'U' : '$f$l';
  }

  factory NameModel.fromJson(Map<String, dynamic> json) {
    return NameModel(
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstname': firstname,
      'lastname': lastname,
    };
  }
}

class AddressModel {
  final String city;
  final String street;
  final dynamic number;
  final String zipcode;

  const AddressModel({
    required this.city,
    required this.street,
    required this.number,
    required this.zipcode,
  });

  String get formattedAddress {
    final parts = <String>[];
    if (number != null && number.toString().isNotEmpty) {
      parts.add('$number');
    }
    if (street.isNotEmpty) {
      parts.add(street);
    }
    if (city.isNotEmpty) {
      parts.add(city.toUpperCase());
    }
    if (zipcode.isNotEmpty) {
      parts.add(zipcode);
    }
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      city: json['city'] as String? ?? '',
      street: json['street'] as String? ?? '',
      number: json['number'],
      zipcode: json['zipcode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'street': street,
      'number': number,
      'zipcode': zipcode,
    };
  }
}

class UserModel {
  final int id;
  final String email;
  final String username;
  final NameModel name;
  final String phone;
  final AddressModel address;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] != null
          ? NameModel.fromJson(json['name'] as Map<String, dynamic>)
          : const NameModel(firstname: '', lastname: ''),
      phone: json['phone'] as String? ?? '',
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : const AddressModel(city: '', street: '', number: '', zipcode: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name.toJson(),
      'phone': phone,
      'address': address.toJson(),
    };
  }
}
