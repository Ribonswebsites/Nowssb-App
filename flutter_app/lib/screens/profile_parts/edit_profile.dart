import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Result of the Edit profile page.
class EditProfileResult {
  final String name;
  final String motto;
  const EditProfileResult(this.name, this.motto);
}

/// Edit profile sub-page: avatar, name and motto, on a frosted card.
class EditProfileScreen extends StatefulWidget {
  final String name;
  final String motto;
  final Widget avatar;
  final Future<void> Function()? onChangePhoto;
  const EditProfileScreen(
      {super.key,
      required this.name,
      required this.motto,
      required this.avatar,
      this.onChangePhoto});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: widget.name);
  late final _motto = TextEditingController(text: widget.motto);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _motto.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.length < 2) {
      setState(() => _error = 'Name needs at least 2 letters');
      return;
    }
    Navigator.of(context).pop(EditProfileResult(n, _motto.text.trim()));
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0x99FFFFFF)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x33FFFFFF))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF8A80))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF8A80))),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Edit profile'),
        actions: [
          TextButton(
              key: const Key('edit-save'),
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)))
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0x40FFFFFF))),
              child: Column(children: [
                GestureDetector(
                  key: const Key('edit-photo'),
                  onTap: widget.onChangePhoto,
                  child: Stack(children: [
                    SizedBox(
                        width: 96,
                        height: 96,
                        child: ClipOval(child: widget.avatar)),
                    Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.photo_camera_outlined,
                                size: 16, color: Colors.black))),
                  ]),
                ),
                const SizedBox(height: 8),
                const Text('Tap to change photo',
                    style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
                const SizedBox(height: 22),
                TextField(
                    key: const Key('edit-name'),
                    controller: _name,
                    maxLength: 32,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('Name').copyWith(errorText: _error),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    }),
                const SizedBox(height: 10),
                TextField(
                    key: const Key('edit-motto'),
                    controller: _motto,
                    maxLength: 80,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('Motto')),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _save,
                    child: const Text('Save changes',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
