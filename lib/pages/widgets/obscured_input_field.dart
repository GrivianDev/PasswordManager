import 'package:flutter/material.dart';

class ObscuredTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const ObscuredTextField({
    super.key,
    this.controller,
    this.label,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<ObscuredTextField> createState() => _ObscuredTextFieldState();
}

class _ObscuredTextFieldState extends State<ObscuredTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: _isObscured,
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 5.0),
          child: Icon(Icons.key),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 5.0),
          child: IconButton(
            onPressed: () => setState(() => _isObscured = !_isObscured),
            icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
          ),
        ),
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
