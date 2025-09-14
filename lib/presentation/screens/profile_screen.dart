import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/bloc/auth_bloc.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Cross-platform image handling
  Uint8List? _imageBytes;
  String? _imageName;

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;

  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Cross-platform image picker
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Profile Photo',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera option (only for mobile)
                  if (!kIsWeb)
                    _buildImageOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _getImage(ImageSource.camera),
                    ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: kIsWeb ? 'Choose File' : 'Gallery',
                    onTap: () => _getImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                kIsWeb
                    ? 'Profile photo will be stored as base64 data'
                    : 'Profile photo will be stored locally for now',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        // Read image as bytes (works on all platforms)
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  // Check if username is available
  Future<void> _checkUsername(String username) async {
    if (username.length < 3) return;

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();

      setState(() {
        _isCheckingUsername = false;
        if (query.docs.isNotEmpty) {
          _usernameError = 'Username is already taken';
        } else {
          _usernameError = null;
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingUsername = false;
        _usernameError = 'Error checking username';
      });
    }
  }

  // Convert image bytes to base64 string for storage
  String? _getImageBase64() {
    if (_imageBytes == null) return null;
    return base64Encode(_imageBytes!);
  }

  // Save user profile to Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Allow saving even if username check failed (we'll handle conflicts in save)
    if (_usernameError != null && !_usernameError!.contains('Cannot verify')) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final username = _usernameController.text.trim().toLowerCase();

      // Double-check username availability before saving
      try {
        final existingUser = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .get()
            .timeout(const Duration(seconds: 5));

        if (existingUser.docs.isNotEmpty) {
          setState(() {
            _usernameError = 'Username is already taken';
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Final username check failed: $e');
        // Continue with save - we'll handle conflicts on the server side
      }

      // Convert image to base64 if exists
      final imageBase64 = _getImageBase64();

      // Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': _nameController.text.trim(),
        'username': username,
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'profileImageBase64': imageBase64,
        'profileImageName': _imageName,
        'hasProfileImage': _imageBytes != null,
        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': true,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      });

      // Update Firebase Auth display name
      await user.updateDisplayName(_nameController.text.trim());

      // Trigger profile setup completion
      if (mounted) {
        context.read<AuthBloc>().add(const ProfileSetupCompleted());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Save profile error: $e');
      if (mounted) {
        String errorMessage = 'Error saving profile';

        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please check Firestore rules.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Cross-platform image display widget
  Widget _buildProfileImage() {
    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.memory(
          _imageBytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    return Icon(
      Icons.add_a_photo,
      size: 40,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image Section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: _buildProfileImage(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to add profile photo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                if (_imageBytes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _imageName ?? 'Selected image',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Username *',
                    prefixIcon: const Icon(Icons.alternate_email),
                    suffixIcon: _isCheckingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _usernameError == null &&
                              _usernameController.text.length >= 3
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    errorText: _usernameError,
                    helperText: 'This will be your unique identifier',
                  ),
                  onChanged: (value) {
                    if (value.length >= 3) {
                      // Debounce username checking
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_usernameController.text == value) {
                          _checkUsername(value);
                        }
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone Field (Optional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description Field (Optional)
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'About You (Optional)',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value != null && value.length > 150) {
                      return 'Description must be less than 150 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isCheckingUsername
                        ? null
                        : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Complete Profile',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Platform-specific info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        kIsWeb ? Icons.web : Icons.phone_android,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          kIsWeb
                              ? 'Running on Web - Images stored as base64'
                              : 'Running on ${defaultTargetPlatform.name} - Images stored locally',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '* Required fields',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
