import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme_controller.dart';
import 'patient_home_screen.dart';
import 'doctor_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _esRegistro = false;
  bool _esMedico = false;
  bool _cargando = false;

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _matriculaCtrl = TextEditingController();
  final TextEditingController _especialidadCtrl = TextEditingController(
    text: 'Médico Clínico',
  );
  final TextEditingController _aliasCtrl = TextEditingController();

  Future<void> _ingresar() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

    setState(() => _cargando = true);
    bool exito = false;

    if (_esRegistro) {
      exito = await ApiService.registrar(
        nombre: _nombreCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        rol: _esMedico ? 'MEDICO' : 'PACIENTE',
        telefono: _telefonoCtrl.text,
        matricula: _esMedico ? _matriculaCtrl.text : null,
        especialidad: _esMedico ? _especialidadCtrl.text : null,
        aliasCbu: _esMedico ? _aliasCtrl.text : null,
      );
    } else {
      exito = await ApiService.login(_emailCtrl.text, _passCtrl.text);
    }

    if (!mounted) return;
    setState(() => _cargando = false);

    if (exito && ApiService.usuarioLogueado != null) {
      final rolBD =
          ApiService.usuarioLogueado!['rol']; // Lee tu rol real de Neon

      if (rolBD == 'MEDICO') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Verificá tus datos o asegurate de que el servidor esté encendido.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(actions: const [ThemeToggleButton()]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.local_hospital_rounded,
                size: 60,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'DomiGuardia',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              Text(
                'SALTA · ATENCIÓN EN DOMICILIO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              if (_esRegistro) ...[
                const Text(
                  '¿Qué tipo de cuenta querés crear?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Soy Paciente',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        selected: !_esMedico,
                        onSelected: (_) => setState(() => _esMedico = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Soy Médico',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        selected: _esMedico,
                        onSelected: (_) => setState(() => _esMedico = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre y Apellido',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Celular',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                if (_esMedico) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datos Profesionales y Cobro',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _matriculaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Matrícula Provincial (MP)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _especialidadCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Especialidad',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.medical_services_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _aliasCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Alias o CBU',
                            hintText: 'Ej: martin.gomez.mp',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _cargando ? null : _ingresar,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _esRegistro ? 'Registrarme ahora' : 'Iniciar sesión',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => setState(() => _esRegistro = !_esRegistro),
                child: Text(
                  _esRegistro
                      ? '¿Ya tenés cuenta? Iniciá sesión'
                      : '¿No tenés cuenta? Registrate acá',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
