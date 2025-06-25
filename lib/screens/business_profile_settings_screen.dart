import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/colors.dart';
import '../models/business_profile_model.dart';
import '../services/business_profile_service.dart';
import '../services/onboarding_service.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';

class BusinessProfileSettingsScreen extends StatefulWidget {
  const BusinessProfileSettingsScreen({super.key});

  @override
  State<BusinessProfileSettingsScreen> createState() =>
      _BusinessProfileSettingsScreenState();
}

class _BusinessProfileSettingsScreenState
    extends State<BusinessProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessProfileService = BusinessProfileService.instance;
  final _onboardingService = OnboardingService.instance;

  // Controllers
  final _companyNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _verificationLinkController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIbanController = TextEditingController();
  final _bankSwiftController = TextEditingController();
  final _ccpNumberController = TextEditingController();
  final _ccpKeyController = TextEditingController();
  final _ccpFullNameController = TextEditingController();
  final _ribNumberController = TextEditingController();

  BusinessProfileModel? _currentProfile;
  BusinessType _selectedBusinessType = BusinessType.individual;
  String _selectedCountry = 'Algeria';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
    // Add listener to verification link controller to update QR code preview
    _verificationLinkController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taglineController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    _registrationNumberController.dispose();
    _verificationLinkController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankIbanController.dispose();
    _bankSwiftController.dispose();
    _ccpNumberController.dispose();
    _ccpKeyController.dispose();
    _ccpFullNameController.dispose();
    _ribNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessProfile() async {
    try {
      final profile = await _businessProfileService.getBusinessProfile();
      setState(() {
        _currentProfile = profile;
        _companyNameController.text = profile.companyName;
        _taglineController.text = profile.tagline ?? '';
        _addressController.text = profile.address;
        _cityController.text = profile.city;
        _stateController.text = profile.state;
        _postalCodeController.text = profile.postalCode;
        _phoneController.text = profile.phone;
        _emailController.text = profile.email;
        _websiteController.text = profile.website ?? '';
        _taxIdController.text = profile.taxId ?? '';
        _registrationNumberController.text = profile.registrationNumber ?? '';
        _verificationLinkController.text = profile.verificationLink ?? '';
        _bankNameController.text = profile.bankName ?? '';
        _bankAccountController.text = profile.bankAccountNumber ?? '';
        _bankIbanController.text = profile.bankIban ?? '';
        _bankSwiftController.text = profile.bankSwiftCode ?? '';
        _ccpNumberController.text = profile.ccpNumber ?? '';
        _ccpKeyController.text = profile.ccpKey ?? '';
        _ccpFullNameController.text = profile.ccpFullName ?? '';
        _ribNumberController.text = profile.ribNumber ?? '';
        _selectedBusinessType = profile.businessType;
        _selectedCountry = profile.country;
        _logoPath = profile.companyLogo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading business profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveBusinessProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final profile = BusinessProfileModel(
        id: _currentProfile?.id,
        companyName: _companyNameController.text.trim(),
        companyLogo: _logoPath,
        tagline: _taglineController.text.trim().isEmpty
            ? null
            : _taglineController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _selectedCountry,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        taxId: _taxIdController.text.trim().isEmpty
            ? null
            : _taxIdController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim().isEmpty
            ? null
            : _registrationNumberController.text.trim(),
        verificationLink: _verificationLinkController.text.trim().isEmpty
            ? null
            : _verificationLinkController.text.trim(),
        businessType: _selectedBusinessType,
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        bankAccountNumber: _bankAccountController.text.trim().isEmpty
            ? null
            : _bankAccountController.text.trim(),
        bankIban: _bankIbanController.text.trim().isEmpty
            ? null
            : _bankIbanController.text.trim(),
        bankSwiftCode: _bankSwiftController.text.trim().isEmpty
            ? null
            : _bankSwiftController.text.trim(),
        ccpNumber: _ccpNumberController.text.trim().isEmpty
            ? null
            : _ccpNumberController.text.trim(),
        ccpKey: _ccpKeyController.text.trim().isEmpty
            ? null
            : _ccpKeyController.text.trim(),
        ccpFullName: _ccpFullNameController.text.trim().isEmpty
            ? null
            : _ccpFullNameController.text.trim(),
        ribNumber: _ribNumberController.text.trim().isEmpty
            ? null
            : _ribNumberController.text.trim(),
        socialMedia: _currentProfile?.socialMedia ?? {},
        createdAt: _currentProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success =
          await _businessProfileService.saveBusinessProfile(profile);

      if (success) {
        // Check if profile is now complete and mark onboarding as done if needed
        final isComplete =
            await _businessProfileService.isBusinessProfileComplete();
        if (isComplete) {
          await _onboardingService.markBusinessProfileCompleted();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business profile saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to save business profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving business profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _updateLogo() async {
    try {
      final logoPath = await _businessProfileService.updateCompanyLogo();
      if (logoPath != null) {
        setState(() {
          _logoPath = logoPath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company logo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeLogo() async {
    if (_logoPath != null) {
      try {
        await _businessProfileService.deleteCompanyLogo(_logoPath!);
        setState(() {
          _logoPath = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company logo removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading business profile...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Business Profile Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanyLogoSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildContactInfoSection(),
              const SizedBox(height: 24),
              _buildBusinessInfoSection(),
              const SizedBox(height: 24),
              _buildBankingInfoSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Logo',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _logoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_logoPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          FontAwesomeIcons.building,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use responsive layout for buttons
                    if (constraints.maxWidth < 300) {
                      // Stack vertically on very narrow screens
                      return Column(
                        children: [
                          CustomButton(
                            text: _logoPath != null ? 'Change Logo' : 'Add Logo',
                            onPressed: _updateLogo,
                            backgroundColor: AppColors.primary,
                            textColor: Colors.white,
                            icon: FontAwesomeIcons.upload,
                            width: double.infinity,
                            height: 40,
                          ),
                          if (_logoPath != null) ...[
                            const SizedBox(height: 12),
                            CustomButton(
                              text: 'Remove',
                              onPressed: _removeLogo,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              icon: FontAwesomeIcons.trash,
                              width: double.infinity,
                              height: 40,
                            ),
                          ],
                        ],
                      );
                    } else {
                      // Use row layout on wider screens
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: CustomButton(
                              text: _logoPath != null ? 'Change Logo' : 'Add Logo',
                              onPressed: _updateLogo,
                              backgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              icon: FontAwesomeIcons.upload,
                              width: 120,
                              height: 40,
                            ),
                          ),
                          if (_logoPath != null) ...[
                            const SizedBox(width: 12),
                            Flexible(
                              child: CustomButton(
                                text: 'Remove',
                                onPressed: _removeLogo,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                icon: FontAwesomeIcons.trash,
                                width: 100,
                                height: 40,
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _companyNameController,
            label: 'Company Name *',
            hint: 'Enter your company name',
            prefixIcon: FontAwesomeIcons.building,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _taglineController,
            label: 'Tagline (Optional)',
            hint: 'Enter your company tagline',
            prefixIcon: FontAwesomeIcons.quoteLeft,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<BusinessType>(
            value: _selectedBusinessType,
            decoration: InputDecoration(
              labelText: 'Business Type',
              prefixIcon: Icon(
                _selectedBusinessType.icon,
                color: AppColors.primary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            items: BusinessType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedBusinessType = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email Address *',
            hint: 'Enter your email address',
            prefixIcon: FontAwesomeIcons.envelope,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number *',
            hint: 'Enter your phone number',
            prefixIcon: FontAwesomeIcons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _websiteController,
            label: 'Website (Optional)',
            hint: 'Enter your website URL',
            prefixIcon: FontAwesomeIcons.globe,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _addressController,
            label: 'Address *',
            hint: 'Enter your business address',
            prefixIcon: FontAwesomeIcons.locationDot,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Use responsive layout based on available width
              if (constraints.maxWidth < 400) {
                // Stack vertically on narrow screens
                return Column(
                  children: [
                    CustomTextField(
                      controller: _cityController,
                      label: 'City *',
                      hint: 'Enter your city',
                      prefixIcon: FontAwesomeIcons.city,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _stateController,
                      label: 'State *',
                      hint: 'Enter your state',
                      prefixIcon: FontAwesomeIcons.mapLocationDot,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                  ],
                );
              } else {
                // Use row layout on wider screens
                return Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _cityController,
                        label: 'City *',
                        hint: 'Enter your city',
                        prefixIcon: FontAwesomeIcons.city,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _stateController,
                        label: 'State *',
                        hint: 'Enter your state',
                        prefixIcon: FontAwesomeIcons.mapLocationDot,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'State is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Use responsive layout based on available width
              if (constraints.maxWidth < 400) {
                // Stack vertically on narrow screens
                return Column(
                  children: [
                    CustomTextField(
                      controller: _postalCodeController,
                      label: 'Postal Code *',
                      hint: 'Enter postal code',
                      prefixIcon: FontAwesomeIcons.envelopesBulk,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Postal code is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: InputDecoration(
                        labelText: 'Country *',
                        prefixIcon: const Icon(
                          FontAwesomeIcons.flag,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      items: _businessProfileService.getCountriesList().map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(
                            country,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCountry = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Country is required';
                        }
                        return null;
                      },
                    ),
                  ],
                );
              } else {
                // Use row layout on wider screens
                return Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _postalCodeController,
                        label: 'Postal Code *',
                        hint: 'Enter postal code',
                        prefixIcon: FontAwesomeIcons.envelopesBulk,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Postal code is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: InputDecoration(
                          labelText: 'Country *',
                          prefixIcon: const Icon(
                            FontAwesomeIcons.flag,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        items: _businessProfileService.getCountriesList().map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Text(
                              country,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCountry = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Country is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _taxIdController,
            label: 'NiF ID *',
            hint: 'Enter your NiF identification number',
            prefixIcon: FontAwesomeIcons.receipt,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'NiF ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registrationNumberController,
            label: 'Card Number *',
            hint: 'Enter your self-employment card number',
            prefixIcon: FontAwesomeIcons.idCard,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Card Number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _verificationLinkController,
            label: 'Verification Link (Optional)',
            hint: 'Enter verification website URL',
            prefixIcon: FontAwesomeIcons.link,
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final uri = Uri.tryParse(value);
                if (uri == null ||
                    !uri.hasAbsolutePath ||
                    (!uri.isScheme('http') && !uri.isScheme('https'))) {
                  return 'Please enter a valid URL';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // QR Code Preview
          if (_verificationLinkController.text.trim().isNotEmpty)
            _buildQRCodePreview(),
        ],
      ),
    );
  }

  Widget _buildBankingInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Banking Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - Used for invoice payment instructions',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _bankNameController,
            label: 'Bank Name',
            hint: 'Enter your bank name',
            prefixIcon: FontAwesomeIcons.buildingColumns,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _bankAccountController,
            label: 'Account Number',
            hint: 'Enter your account number',
            prefixIcon: FontAwesomeIcons.creditCard,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _bankIbanController,
            label: 'IBAN',
            hint: 'Enter your IBAN',
            prefixIcon: FontAwesomeIcons.moneyBill,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _bankSwiftController,
            label: 'SWIFT/BIC Code',
            hint: 'Enter your SWIFT/BIC code',
            prefixIcon: FontAwesomeIcons.code,
          ),
          const SizedBox(height: 24),
          Text(
            'CCP Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - Algerian postal account information',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _ccpNumberController,
            label: 'CCP Number',
            hint: 'Enter your CCP number',
            prefixIcon: FontAwesomeIcons.envelopesBulk,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _ccpKeyController,
            label: 'CCP Key (Clé)',
            hint: 'Enter your CCP key',
            prefixIcon: FontAwesomeIcons.key,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _ccpFullNameController,
            label: 'Full Name on CCP',
            hint: 'Enter the full name on CCP account',
            prefixIcon: FontAwesomeIcons.user,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _ribNumberController,
            label: 'RIB Number',
            hint: 'Enter your RIB number',
            prefixIcon: FontAwesomeIcons.receipt,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Save Business Profile',
        onPressed: _isSaving ? null : _saveBusinessProfile,
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
        icon: _isSaving ? null : FontAwesomeIcons.floppyDisk,
        isLoading: _isSaving,
        height: 50,
      ),
    );
  }

  Widget _buildQRCodePreview() {
    final verificationUrl = _verificationLinkController.text.trim();
    if (verificationUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.qrcode,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'QR Code Preview',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: verificationUrl,
                version: QrVersions.auto,
                size: 150.0,
                backgroundColor: Colors.white,
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This QR code will be included in your invoices and business documents for verification purposes.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
