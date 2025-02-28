import 'package:flutter/material.dart';
import 'package:sms_apk/widgets/user_icon.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final String text;
  final GlobalKey<ScaffoldState>? scaffoldKey; // Nullable scaffoldKey

  const Header({super.key, required this.text, this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 18, 102, 102),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: UserIconWidget(),
        ),
      ],
      leading: scaffoldKey != null
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white), // Drawer Menu Icon
              onPressed: () {
                scaffoldKey!.currentState?.openDrawer();
              },
            )
          : ModalRoute.of(context)?.canPop == true
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom Back Button
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              : null, // If no back button needed, keep it null
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
