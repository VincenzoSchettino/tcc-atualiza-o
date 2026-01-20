import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.')),
      );
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = cred.user;
      if (user == null) {
        throw Exception('Usuário não criado.');
      }

      // ✅ Define o nome também no Auth (para ficar igual ao Google Sign-In)
      final nome = _nameController.text.trim();
      await user.updateDisplayName(nome);
      await user.reload();

      // ✅ Salva no Firestore usando o UID (sem UUID aleatório)
      await _db.collection("usuarios").doc(user.uid).set({
        "uid": user.uid,
        "name": nome,
        "email": user.email, // e-mail oficial do Auth
        "dataCriacao": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar conta: $error')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('📱 Tela de Signup carregada!');
    return Scaffold(
      backgroundColor: Colors.pink,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset('imagens/img1.png', height: 150),
              const SizedBox(height: 20),
              const Text(
                'Criar nova conta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(_nameController, 'Nome'),
              const SizedBox(height: 20),
              _buildTextField(_emailController, 'Email'),
              const SizedBox(height: 20),
              _buildPasswordField(
                _passwordController,
                'Senha',
                _isPasswordVisible,
                (value) {
                  setState(() {
                    _isPasswordVisible = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                _confirmPasswordController,
                'Confirmar Senha',
                _isConfirmPasswordVisible,
                (value) {
                  setState(() {
                    _isConfirmPasswordVisible = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF437DAA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _signup,
                  child: const Text(
                    'Criar Conta',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                child: const Text('Voltar para Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool isVisible,
    Function(bool) onVisibilityChanged,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => onVisibilityChanged(!isVisible),
        ),
      ),
    );
  }
}
