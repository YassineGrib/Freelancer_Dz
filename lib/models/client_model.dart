enum ClientType {
  individualLocal('Individual (Local)'),
  individualForeign('Individual (Foreign)'),
  nationalCompany('National Company (Local)'),
  companyInternational('Company (International)');

  const ClientType(this.displayName);
  final String displayName;
}

enum Currency {
  da('da'),
  usd('usd'),
  eur('eur');

  const Currency(this.code);
  final String code;

  // Display name for UI (uppercase)
  String get displayName {
    switch (this) {
      case Currency.da:
        return 'DA';
      case Currency.usd:
        return 'USD';
      case Currency.eur:
        return 'EUR';
    }
  }
}

class ClientModel {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final ClientType clientType;
  final Currency currency;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Company-specific fields
  final String? companyName;
  final String? commercialRegisterNumber;
  final String? taxIdentificationNumber;
  final String? companyEmail;

  ClientModel({
    this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.clientType = ClientType.individualLocal,
    this.currency = Currency.da,
    required this.createdAt,
    this.updatedAt,
    this.companyName,
    this.commercialRegisterNumber,
    this.taxIdentificationNumber,
    this.companyEmail,
  });

  // Get default currency based on client type
  static Currency getDefaultCurrency(ClientType clientType) {
    switch (clientType) {
      case ClientType.individualLocal:
      case ClientType.nationalCompany:
        return Currency.da;
      case ClientType.individualForeign:
      case ClientType.companyInternational:
        return Currency.usd;
    }
  }

  // Check if client type is a company
  static bool isCompanyType(ClientType clientType) {
    return clientType == ClientType.nationalCompany ||
        clientType == ClientType.companyInternational;
  }

  // Check if this client is a company
  bool get isCompany => isCompanyType(clientType);

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      clientType: ClientType.values.firstWhere(
        (type) => type.name == (json['client_type'] as String?),
        orElse: () => ClientType.individualLocal,
      ),
      currency: Currency.values.firstWhere(
        (curr) => curr.code == (json['currency'] as String?)?.toLowerCase(),
        orElse: () => Currency.da,
      ),
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null && json['updated_at'] is String
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      companyName: json['company_name'] as String?,
      commercialRegisterNumber: json['commercial_register_number'] as String?,
      taxIdentificationNumber: json['tax_identification_number'] as String?,
      companyEmail: json['company_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'client_type': clientType.name,
      'currency': currency.code,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (companyName != null) 'company_name': companyName,
      if (commercialRegisterNumber != null)
        'commercial_register_number': commercialRegisterNumber,
      if (taxIdentificationNumber != null)
        'tax_identification_number': taxIdentificationNumber,
      if (companyEmail != null) 'company_email': companyEmail,
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    ClientType? clientType,
    Currency? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyName,
    String? commercialRegisterNumber,
    String? taxIdentificationNumber,
    String? companyEmail,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      clientType: clientType ?? this.clientType,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyName: companyName ?? this.companyName,
      commercialRegisterNumber:
          commercialRegisterNumber ?? this.commercialRegisterNumber,
      taxIdentificationNumber:
          taxIdentificationNumber ?? this.taxIdentificationNumber,
      companyEmail: companyEmail ?? this.companyEmail,
    );
  }

  @override
  String toString() {
    return 'ClientModel(id: $id, name: $name, email: $email, phone: $phone, address: $address, clientType: $clientType, currency: $currency, companyName: $companyName, commercialRegisterNumber: $commercialRegisterNumber, taxIdentificationNumber: $taxIdentificationNumber, companyEmail: $companyEmail, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.address == address &&
        other.clientType == clientType &&
        other.currency == currency &&
        other.companyName == companyName &&
        other.commercialRegisterNumber == commercialRegisterNumber &&
        other.taxIdentificationNumber == taxIdentificationNumber &&
        other.companyEmail == companyEmail &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        address.hashCode ^
        clientType.hashCode ^
        currency.hashCode ^
        companyName.hashCode ^
        commercialRegisterNumber.hashCode ^
        taxIdentificationNumber.hashCode ^
        companyEmail.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
