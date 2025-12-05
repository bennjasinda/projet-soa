import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  final VoidCallback onLogout;
  const ProfileMenu({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sinda Bennja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                'sinda@gmail.com',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Divider(height: 24, thickness: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}