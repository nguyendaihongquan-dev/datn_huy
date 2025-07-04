import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  String? _currentUID;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUID = prefs.getString('UID');

      if (_currentUID != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        _userData = await authProvider.getUserDetails(_currentUID!);

        if (_userData != null) {
          _fullNameController.text = _userData!['fullName']?.toString() ?? '';
          _addressController.text = _userData!['address']?.toString() ?? '';
          _phoneController.text = _userData!['phoneNumber']?.toString() ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải thông tin: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _showSaveConfirmationDialog();
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lưu'),
        content: const Text('Bạn có muốn lưu thay đổi không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelEdit();
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveUserInfo();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserInfo() async {
    if (_currentUID == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateUserInfo(
        fullName: _fullNameController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (success) {
        setState(() {
          _isEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thành công!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi cập nhật!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    // Khôi phục dữ liệu ban đầu
    if (_userData != null) {
      _fullNameController.text = _userData!['fullName']?.toString() ?? '';
      _addressController.text = _userData!['address']?.toString() ?? '';
      _phoneController.text = _userData!['phoneNumber']?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _currentUID != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isLoading ? null : _toggleEditMode,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUID == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Vui lòng đăng nhập để xem thông tin',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar và tên
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF2196F3),
                              child: Text(
                                _fullNameController.text.isNotEmpty
                                    ? _fullNameController.text[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _fullNameController.text.isNotEmpty
                                  ? _fullNameController.text
                                  : 'Chưa có tên',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // UID
                      _buildInfoCard(
                        icon: Icons.person,
                        title: 'UID',
                        value: _currentUID ?? 'Không có',
                        isEditable: false,
                      ),
                      const SizedBox(height: 16),

                      // Họ và tên
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        title: 'Họ và tên',
                        controller: _fullNameController,
                        isEditable: _isEditing,
                      ),
                      const SizedBox(height: 16),

                      // Số điện thoại
                      _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Số điện thoại',
                        controller: _phoneController,
                        isEditable: _isEditing,
                      ),
                      const SizedBox(height: 16),

                      // Địa chỉ
                      _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'Địa chỉ',
                        controller: _addressController,
                        isEditable: _isEditing,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Nút đăng xuất
                      if (!_isEditing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showLogoutDialog(),
                            icon: const Icon(Icons.logout),
                            label: const Text('Đăng xuất'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    String? value,
    TextEditingController? controller,
    required bool isEditable,
    int maxLines = 1,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2196F3),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (controller != null)
                    TextField(
                      controller: controller,
                      enabled: isEditable,
                      maxLines: maxLines,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      value ?? 'Chưa có thông tin',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
