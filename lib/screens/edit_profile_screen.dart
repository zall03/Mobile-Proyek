import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialGender;
  final String initialPhone;
  final String? initialPhoto;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialGender,
    required this.initialPhone,
    this.initialPhoto,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  String _selectedGender = 'Laki-Laki';
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(
      text: widget.initialPhone == "-" ? "" : widget.initialPhone,
    );

    if (widget.initialGender == 'Perempuan') {
      _selectedGender = 'Perempuan';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Fungsi untuk menyimpan perubahan ke Supabase
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User belum login');

      String? photoUrl = widget.initialPhoto;

      if (_imageFile != null) {
        final fileExtension = _imageFile!.path.split('.').last;
        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final filePath = '${user.id}/$fileName';
        await supabase.storage.from('avatars').upload(filePath, _imageFile!);
        photoUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      }

      // 2. Update data teks ke tabel 'users'
      await supabase
          .from('users')
          .update({
            'name': _nameController.text.trim(),
            'no_telepon': _phoneController.text.trim(),
            'jenis_kelamin': _selectedGender,
            if (photoUrl != null) 'foto_profil': photoUrl,
          })
          .eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );

      // 3. TUTUP HALAMAN DAN KIRIM TRUE AGAR PROFILE SCREEN ME-REFRESH DATA
      Navigator.pop(context, true);
    } on StorageException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload foto: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFAF9F6,
      ), // Warna background mirip screenshot
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- AVATAR FOTO PROFIL ---
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange, width: 3),
                            color: Colors.white,
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (widget.initialPhoto != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            widget.initialPhoto!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child:
                              (_imageFile == null &&
                                  widget.initialPhoto == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E7AC1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- FORM NAMA LENGKAP ---
                  const Text(
                    'Nama Lengkap',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E7AC1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- FORM NOMOR TELEPON ---
                  const Text(
                    'Nomor Telepon',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_android_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E7AC1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Gender',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedGender = 'Laki-Laki'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedGender == 'Laki-Laki'
                                  ? const Color(0xFF1E7AC1)
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedGender == 'Laki-Laki'
                                    ? const Color(0xFF1E7AC1)
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Laki-Laki',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedGender == 'Laki-Laki'
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedGender = 'Perempuan'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedGender == 'Perempuan'
                                  ? const Color(0xFF1E7AC1)
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedGender == 'Perempuan'
                                    ? const Color(0xFF1E7AC1)
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Perempuan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedGender == 'Perempuan'
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827), // Warna hitam
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
