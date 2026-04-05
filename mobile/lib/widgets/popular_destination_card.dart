import 'package:flutter/material.dart';

class PopularDestinationCard extends StatelessWidget {
  final String title;
  final String? imageUrl; // Sẽ dùng NetworkImage/AssetImage khi có link
  final Color? placeholderColor; // Màu thay thế nếu chưa có ảnh

  const PopularDestinationCard({
    Key? key,
    required this.title,
    this.imageUrl,
    this.placeholderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140, // Độ rộng cố định cho danh sách ngang
      margin: const EdgeInsets.only(right: 12), // Khoảng cách giữa các thẻ
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // Bo góc cho cả nội dung bên trong
        child: Stack(
          children: [
            // 1. Phần hình ảnh (hoặc Container màu placeholder)
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

            // 2. Lớp phủ tối (Overlay gradient) để chữ nổi bật
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Phần chữ tiêu đề địa điểm
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị khi không có hoặc lỗi ảnh
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: placeholderColor ?? Colors.teal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          color: (placeholderColor ?? Colors.teal).withOpacity(0.7),
          size: 40,
        ),
      ),
    );
  }
}