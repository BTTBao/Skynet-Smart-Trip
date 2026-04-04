import 'package:flutter/material.dart';

class ResortDescription extends StatefulWidget {
  final String description;

  const ResortDescription({Key? key, required this.description}) : super(key: key);

  @override
  State<ResortDescription> createState() => _ResortDescriptionState();
}

class _ResortDescriptionState extends State<ResortDescription> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            maxLines: isExpanded ? null : 4,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[800], height: 1.5),
          ),
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    isExpanded ? 'Thu gọn' : 'Xem thêm',
                    style: TextStyle(color: Colors.green[500], fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.green[500],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
