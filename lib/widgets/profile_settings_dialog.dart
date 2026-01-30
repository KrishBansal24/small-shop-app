import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/user_provider.dart';
import 'package:shop_app/services/mongodb_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shop_app/widgets/custom_button.dart';
import 'package:shop_app/widgets/custom_textfield.dart';

class ProfileSettingsDialog extends StatefulWidget {
  const ProfileSettingsDialog({super.key});

  @override
  State<ProfileSettingsDialog> createState() => _ProfileSettingsDialogState();
}

class _ProfileSettingsDialogState extends State<ProfileSettingsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _shopNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: user.name);
    _shopNameController = TextEditingController(text: user.shopName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Assuming ID is stored as hex string in provider, convert back to ObjectId
      // Note: In a real app, you might store ObjectId directly or handle string conversion more robustly
      String result = await MongoDatabase.updateUser(
        mongo.ObjectId.parse(
          userProvider.id.substring(10, 34),
        ), // Extracting hex from "ObjectId("...")" if needed, or just parse if clean hex
        _nameController.text.trim(),
        _shopNameController.text.trim(),
      );

      // Handle the case where the ID string format might vary.
      // Ideally UserProvider stores clean hex string or ObjectId.
      // For now, let's try to update using the ID we have.
      // If the ID in provider is "ObjectId("5f...")", we need to parse it.

      // Let's rely on a simpler approach if possible or ensure ID is clean.
      // Re-reading UserProvider: it stores .toString() of ObjectId.
      // ObjectId.toString() usually returns 'ObjectId("hexstring")'.

      // Let's parse safely
      String idString = userProvider.id;
      mongo.ObjectId objectId;
      if (idString.startsWith('ObjectId("') && idString.endsWith('")')) {
        objectId = mongo.ObjectId.fromHexString(idString.substring(10, 34));
      } else {
        objectId = mongo.ObjectId.fromHexString(idString);
      }

      result = await MongoDatabase.updateUser(
        objectId,
        _nameController.text.trim(),
        _shopNameController.text.trim(),
      );

      if (result == "success") {
        userProvider.updateProfile(
          _nameController.text.trim(),
          _shopNameController.text.trim(),
        );
        if (mounted) {
          Navigator.pop(context);
          // Success message removed to avoid UI collision.
          // The dashboard updates immediately, providing sufficient feedback.
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $result"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Profile Settings",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildReadOnlyField(
                "Phone Number",
                user.phone,
                "Phone number cannot be changed",
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _nameController,
                label: "Your Name",
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _shopNameController,
                label: "Shop Name",
                prefixIcon: Icons.store_mall_directory_outlined,
              ),
              const SizedBox(height: 16),

              _buildReadOnlyField("Shop ID", "shop_${user.username}", ""),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: "Save Changes",
                  isLoading: _isLoading,
                  onPressed: _saveChanges,
                  icon: Icons.save_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(hint, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ],
    );
  }
}
