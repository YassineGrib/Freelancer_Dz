import 'package:flutter/material.dart';

class BusinessProfileModel {
  final String? id;
  final String companyName;
  final String? companyLogo;
  final String? tagline;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phone;
  final String email;
  final String? website;
  final String? taxId;
  final String? registrationNumber;
  final String? verificationLink;
  final BusinessType businessType;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIban;
  final String? bankSwiftCode;
  final Map<String, String> socialMedia;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessProfileModel({
    this.id,
    required this.companyName,
    this.companyLogo,
    this.tagline,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phone,
    required this.email,
    this.website,
    this.taxId,
    this.registrationNumber,
    this.verificationLink,
    required this.businessType,
    this.bankName,
    this.bankAccountNumber,
    this.bankIban,
    this.bankSwiftCode,
    this.socialMedia = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessProfileModel copyWith({
    String? id,
    String? companyName,
    String? companyLogo,
    String? tagline,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phone,
    String? email,
    String? website,
    String? taxId,
    String? registrationNumber,
    String? verificationLink,
    BusinessType? businessType,
    String? bankName,
    String? bankAccountNumber,
    String? bankIban,
    String? bankSwiftCode,
    Map<String, String>? socialMedia,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfileModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      verificationLink: verificationLink ?? this.verificationLink,
      businessType: businessType ?? this.businessType,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIban: bankIban ?? this.bankIban,
      bankSwiftCode: bankSwiftCode ?? this.bankSwiftCode,
      socialMedia: socialMedia ?? this.socialMedia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'company_logo': companyLogo,
      'tagline': tagline,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
      'email': email,
      'website': website,
      'tax_id': taxId,
      'registration_number': registrationNumber,
      'verification_link': verificationLink,
      'business_type': businessType.name,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_iban': bankIban,
      'bank_swift_code': bankSwiftCode,
      'social_media': socialMedia,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileModel(
      id: json['id'],
      companyName: json['company_name'] ?? '',
      companyLogo: json['company_logo'],
      tagline: json['tagline'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'],
      taxId: json['tax_id'],
      registrationNumber: json['registration_number'],
      verificationLink: json['verification_link'],
      businessType: BusinessType.values.firstWhere(
        (type) => type.name == json['business_type'],
        orElse: () => BusinessType.individual,
      ),
      bankName: json['bank_name'],
      bankAccountNumber: json['bank_account_number'],
      bankIban: json['bank_iban'],
      bankSwiftCode: json['bank_swift_code'],
      socialMedia: Map<String, String>.from(json['social_media'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  static BusinessProfileModel get defaultProfile => BusinessProfileModel(
    companyName: '',
    address: '',
    city: '',
    state: '',
    postalCode: '',
    country: 'Algeria',
    phone: '',
    email: '',
    businessType: BusinessType.individual,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

enum BusinessType {
  individual,
  company,
  partnership,
  corporation;

  String get displayName {
    switch (this) {
      case BusinessType.individual:
        return 'Individual/Freelancer';
      case BusinessType.company:
        return 'Company';
      case BusinessType.partnership:
        return 'Partnership';
      case BusinessType.corporation:
        return 'Corporation';
    }
  }

  IconData get icon {
    switch (this) {
      case BusinessType.individual:
        return Icons.person;
      case BusinessType.company:
        return Icons.business;
      case BusinessType.partnership:
        return Icons.group;
      case BusinessType.corporation:
        return Icons.corporate_fare;
    }
  }
}

