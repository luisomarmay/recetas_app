import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/registro_pagina.dart';
import 'package:my_app/inicio_pagina.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  // -------------------------------
  // FUNCIÓN DE LOGIN
  // -------------------------------
  Future<void> login() async {
    setState(() => loading = true);

    // llama firebaseAuth para autenticar mediante email y password
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        //trim elimina los espacios al inico y final del texto, no dentro
        //mucho ojo 😱​😱​😱​😱​😱​😱​😱​😱​😱​😱​😱​
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      //  Navegar a HomeScreen y reemplazar Login
      /* ¿Por qué “pushReplacement” y no “push”?
          Pues facil pq:
          -elimina la pantalla de login del historial
          -el usuario NO vuelve al login presionando "Atrás"
          -es el comportamiento estándar de toda app con login*/
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );

      // Si funciona:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión exitoso 🎉')),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Error desconocido";

      if (e.code == 'user-not-found') {
        message = "No existe un usuario con ese correo.";
      } else if (e.code == 'wrong-password') {
        message = "Contraseña incorrecta.";
      } else if (e.code == 'invalid-email') {
        message = "Correo inválido.";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4C2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                size: 100,
                color: const Color(0xFF5D4037),
              ),
              const SizedBox(height: 20),

              const Text(
                "Iniciar sesión",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // CORREO
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // PASSWORD
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              // BOTÓN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Ingresar"),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistroScreen(),
                    ),
                  );
                },
                child: const Text("¿No tienes cuenta? Regístrate"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
