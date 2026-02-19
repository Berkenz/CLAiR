import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// First step of sign-up: collect first name and last name.
/// Also used when a new Google user needs to provide their name.
class SignUpNameScreen extends StatefulWidget {
  const SignUpNameScreen({super.key, this.isGoogleFlow = false});

  final bool isGoogleFlow;

  @override
  State<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends State<SignUpNameScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (widget.isGoogleFlow) {
      context.push('/signup/google-complete', extra: {
        'first_name': firstName,
        'last_name': lastName,
      });
    } else {
      context.push('/signup/email', extra: {
        'first_name': firstName,
        'last_name': lastName,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _proceed,
                child: const Text('Proceed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
