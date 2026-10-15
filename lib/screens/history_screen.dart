import 'package:flutter/material.dart';

import '../models/solicitud_model.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import 'visit_tracking_screen.dart';

class HistoryScreen extends StatefulWidget {
  final bool esModoMedico;
  const HistoryScreen({super.key, this.esModoMedico = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _cargando = true;
  List<SolicitudModel> _historial = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final datos = await ApiService.obtenerHistorial();
    if (!mounted) return;
    setState(() {
      _historial = datos;
      _cargando = false;
    });
  }

  void _mostrarCertificadoDigital(SolicitudModel s) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.verified_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Constancia Médica Digital',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DOMIGUARDIA SALTA · ATENCIÓN DOMICILIARIA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dr. Martín Gómez',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Médico Clínico · Matrícula Provincial N° 4821',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Paciente: ${s.nombrePaciente}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Domicilio: ${s.domicilio}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  'Motivo: ${s.motivo}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const Divider(height: 24),
                const Text(
                  'DIAGNÓSTICO E INDICACIONES:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  s.diagnosticoMedico ?? 'Atención clínica realizada en domicilio sin complicaciones.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Firma Digital Verificada',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Guardia ID #${s.id} · Salta Capital',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Compartir certificado'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Certificado médico listo para enviar por WhatsApp o PDF.',
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final finalizadas = _historial
        .where((s) => s.estado == 'FINALIZADA')
        .toList();
    final totalRecaudado = finalizadas.fold<double>(
      0,
      (sum, item) => sum + item.precio,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esModoMedico
              ? 'Mis Guardias y Honorarios'
              : 'Historial Clínico y Recetas',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _cargarDatos,
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Si es médico, mostramos su tarjeta de Billetera / Honorarios
                  if (widget.esModoMedico) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BALANCE DE GUARDIAS FINALIZADAS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${totalRecaudado.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${finalizadas.length} visitas domiciliarias completadas · Salta Capital',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    widget.esModoMedico
                        ? 'Registro de atenciones'
                        : 'Tus visitas médicas solicitadas',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_historial.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Todavía no hay guardias registradas.'),
                      ),
                    )
                  else
                    ..._historial.map((s) {
                      final esFinalizada = s.estado == 'FINALIZADA';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: esFinalizada
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : colorScheme.primary.withValues(
                                              alpha: 0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      esFinalizada
                                          ? '✓ FINALIZADA'
                                          : '● ${s.estado}',
                                      style: TextStyle(
                                        color: esFinalizada
                                            ? Colors.green
                                            : colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${s.precio.toStringAsFixed(0)} · ${s.metodoPago}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.motivo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '👤 ${s.nombrePaciente} (${s.paraQuien})',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '📍 ${s.domicilio}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),

                              if (s.diagnosticoMedico != null &&
                                  s.diagnosticoMedico!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Informe del Dr. Martín Gómez (MP 4821):',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        s.diagnosticoMedico!,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  if (esFinalizada)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.description_outlined,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Ver Certificado / Receta',
                                        ),
                                        onPressed: () =>
                                            _mostrarCertificadoDigital(s),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: FilledButton.icon(
                                        icon: const Icon(
                                          Icons.gps_fixed,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Ver seguimiento en vivo',
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  VisitTrackingScreen(
                                                    esVistaMedico:
                                                        widget.esModoMedico,
                                                    solicitud: s,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
