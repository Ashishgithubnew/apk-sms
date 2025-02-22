import 'package:flutter/material.dart';
// import 'app_colors.dart';

class UserIconWidget extends StatelessWidget {
  final String? userName;

  const UserIconWidget({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person, color: Colors.white),
        if (userName != null) ...[
          SizedBox(width: 8),
          Text(
            userName!,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ]
      ],
    );
  }
}
