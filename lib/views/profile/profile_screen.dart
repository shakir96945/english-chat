import 'dart:io';
import 'package:flutter/material';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedCountry = 'United States';
  String _selectedGender = 'Male';
  String _selectedDob = 'Not Specified';
  bool _isEditing = false;

  final List<String> _genders = ['Male', 'Female', 'Non-Binary', 'Rather not say'];

  final List<Map<String, String>> _countries = [
    {"name": "United States", "flag": "🇺🇸"},
    {"name": "United Kingdom", "flag": "🇬🇧"},
    {"name": "Canada", "flag": "🇨🇦"},
    {"name": "Australia", "flag": "🇦🇺"},
    {"name": "India", "flag": "🇮🇳"},
    {"name": "Germany", "flag": "🇩🇪"},
    {"name": "France", "flag": "🇫🇷"},
    {"name": "Japan", "flag": "🇯🇵"},
    {"name": "Brazil", "flag": "🇧🇷"},
    {"name": "Saudi Arabia", "flag": "🇸🇦"},
    {"name": "Pakistan", "flag": "🇵🇰"},
    {"name": "Bangladesh", "flag": "🇧🇩"},
    {"name": "Turkey", "flag": "🇹🇷"},
    {"name": "Mexico", "flag": "🇲🇽"},
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthController>(context, listen: false);
    _nameController.text = auth.userModel?.fullName ?? '';
    _usernameController.text = auth.userModel?.username ?? '';
    _bioController.text = auth.userModel?.bio ?? '';
    _selectedCountry = auth.userModel?.country ?? 'United States';
    _selectedGender = auth.userModel?.gender ?? 'Male';
    _selectedDob = auth.userModel?.dateOfBirth ?? 'Not Specified';
  }

  Future<void> _pickAndUploadImage(ImageSource source, AuthController auth) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final success = await auth.uploadProfilePicture(file);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture uploaded successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.errorMessage ?? "Failed to upload image")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking photo: $e")),
      );
    }
  }

  void _showImagePickerOptions(BuildContext context, AuthController auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.charcoalLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Update Profile Photo", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.goldPrimary),
              title: const Text("Take Photo with Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera, auth);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.goldPrimary),
              title: const Text("Select from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery, auth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.goldPrimary,
              onPrimary: AppTheme.charcoalDark,
              surface: AppTheme.charcoalLight,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  String _getFlagForCountry(String countryName) {
    final found = _countries.firstWhere(
      (c) => c['name']!.toLowerCase() == countryName.toLowerCase(),
      orElse: () => {"name": "", "flag": "🏳️"},
    );
    return found['flag']!;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final user = auth.userModel;

    if (user == null) return const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary));

    return Scaffold(
      backgroundColor: AppTheme.charcoalDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Profile Pic Card
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 114,
                    height: 114,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.goldPrimary, AppTheme.goldDark],
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 53,
                    backgroundColor: AppTheme.charcoalDark,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(user.profilePic),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _showImagePickerOptions(context, auth),
                      child: const CircleAvatar(
                        backgroundColor: AppTheme.goldPrimary,
                        radius: 17,
                        child: Icon(Icons.camera_alt_rounded, size: 16, color: AppTheme.charcoalDark),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("@${user.username}", style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 28),

            if (!_isEditing) ...[
              // Info View
              _buildInfoRow("Bio Description", user.bio, Icons.info_outline_rounded),
              _buildInfoRow("Gender Profile", user.gender, Icons.face_rounded),
              _buildInfoRow("Country Residence", "${_getFlagForCountry(user.country)} ${user.country}", Icons.public_rounded),
              _buildInfoRow("Date of Birth", user.dateOfBirth, Icons.cake_rounded),
              _buildInfoRow("Privacy Policy", user.showOnlinePresence ? "Show Online Status" : "Offline Presence", Icons.shield_rounded),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.goldPrimary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text("Edit Premium Profile", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              // Edit forms
              _buildTextField(_nameController, "Full Name", Icons.person_rounded),
              const SizedBox(height: 14),
              _buildTextField(_usernameController, "Username", Icons.alternate_email_rounded),
              const SizedBox(height: 14),
              _buildTextField(_bioController, "Bio", Icons.description_rounded),
              const SizedBox(height: 14),

              // Gender Selector
              _buildDropdownField<String>(
                label: "Gender",
                value: _selectedGender,
                items: _genders,
                icon: Icons.face_rounded,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGender = val);
                },
              ),
              const SizedBox(height: 14),

              // Country Dropdown Selector
              _buildDropdownField<String>(
                label: "Country",
                value: _selectedCountry,
                items: _countries.map((c) => c['name']!).toList(),
                icon: Icons.public_rounded,
                itemBuilder: (context, countryName) {
                  return Row(
                    children: [
                      Text(_getFlagForCountry(countryName), style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(countryName),
                    ],
                  );
                },
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCountry = val);
                },
              ),
              const SizedBox(height: 14),

              // Date of Birth Selector
              GestureDetector(
                onTap: _selectDateOfBirth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.charcoalLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_rounded, color: AppTheme.goldPrimary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Date of Birth", style: TextStyle(color: Colors.white38, fontSize: 10)),
                            const SizedBox(height: 4),
                            Text(_selectedDob, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Icon(Icons.calendar_month_rounded, color: AppTheme.goldPrimary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () async {
                          if (auth.isLoading) return;
                          final done = await auth.editProfile(
                            fullName: _nameController.text,
                            username: _usernameController.text,
                            bio: _bioController.text,
                            country: _selectedCountry,
                            gender: _selectedGender,
                            dateOfBirth: _selectedDob,
                          );
                          if (done) setState(() => _isEditing = false);
                        },
                        child: auth.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.charcoalDark, strokeWidth: 2))
                            : const Text("Save Changes", style: TextStyle(color: AppTheme.charcoalDark, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () => setState(() => _isEditing = false),
                        child: const Text("Cancel", style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )
            ],

            const Divider(color: Colors.white10, height: 40),

            // Settings buttons
            Container(
              decoration: BoxDecoration(
                color: AppTheme.charcoalLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_rounded, color: AppTheme.goldPrimary),
                    title: const Text("Online Visibility", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text("Allow others to see your online status", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    trailing: Switch(
                      value: user.showOnlinePresence,
                      onChanged: (val) => auth.togglePrivacySetting(val),
                      activeColor: AppTheme.goldPrimary,
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
                    title: const Text("Blocked Users", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text("Manage blocked spam profiles", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    onTap: () {
                      _showBlockedUsersDialog(context, auth);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.white54),
                    title: const Text("Logout", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.redAccent)),
                    onTap: () async {
                      await auth.logOut();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.goldPrimary, size: 20),
        filled: true,
        fillColor: AppTheme.charcoalLight,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
    Widget Function(BuildContext, T)? itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.charcoalLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
            prefixIcon: Icon(icon, color: AppTheme.goldPrimary, size: 20),
            border: InputBorder.none,
          ),
          dropdownColor: AppTheme.charcoalLight,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: itemBuilder != null ? itemBuilder(context, item) : Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String val, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.charcoalLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.goldPrimary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockedUsersDialog(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.charcoalLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Blocked Users", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
        content: auth.userModel!.blockedUsers.isEmpty
            ? const Text("No blocked spammers.", style: TextStyle(color: Colors.white70))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: auth.userModel!.blockedUsers.length,
                  itemBuilder: (context, idx) {
                    final uid = auth.userModel!.blockedUsers[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(uid, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      trailing: TextButton(
                        onPressed: () {
                          auth.unblockUser(uid);
                          Navigator.pop(context);
                        },
                        child: const Text("UNBLOCK", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
