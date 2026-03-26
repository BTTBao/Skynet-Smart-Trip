import 'package:flutter/material.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF80ed99);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa thông tin',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[100],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 100 + bottomPadding),
        child: Column(
          children: [
            // Profile Picture Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withOpacity(0.5),
                            width: 4,
                          ),
                          image: const DecorationImage(
                            image: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuB2GJK8zDcf6Y22BRqOjzl7ZCp-Fucu0Lz0rBp2ClTwp5GVewg650Y7mzgUKQKhVKJ8UvdYVmXTMqNvMqnxdw4-XrbNsPVMAMSiJ3EkxNPzduCB9eT8NuuY6j6bJVRNJPh38cuzVGYneOvcJ60QN--hT0ilZo7zEqu-ndar6On-if9jI7sfz7s7E6C8L2K9op9lJoh1NnUwRll2olwxBQb4owm0lGq31Z5E5xBPYMDIu41cDJcibOJPWuJssoJd60nuK2LXQ_rNcGtB'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black87,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thay đổi ảnh đại diện',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Họ tên',
                    icon: Icons.person_outline,
                    initialValue: 'Nguyễn Văn Du',
                    hintText: 'Nhập họ và tên',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Email',
                    icon: Icons.mail_outline,
                    initialValue: 'vandu.traveler@email.com',
                    hintText: 'example@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                    initialValue: '0987 654 321',
                    hintText: '09xx xxx xxx',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Ngày sinh',
                    icon: Icons.calendar_today_outlined,
                    initialValue: '15/08/1995',
                    hintText: 'DD/MM/YYYY',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Fixed Bottom Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [primaryColor, Color(0xFF57cc99)],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String initialValue,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF80ed99), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
