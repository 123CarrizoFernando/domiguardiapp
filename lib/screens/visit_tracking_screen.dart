import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/solicitud_model.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';

class VisitTrackingScreen extends StatefulWidget {
  final bool esVistaMedico;
  final SolicitudModel solicitud;

  const VisitTrackingScreen({
    super.key,
    required this.esVistaMedico,
    required this.solicitud,
  });

  @override
  State<VisitTrackingScreen> createState() => _VisitTrackingScreenState();
}

class _VisitTrackingScreenState extends State<VisitTrackingScreen> {
  int _estadoActual = 0;
  String _informeMedicoFinal = '';
  Timer? _pollingTimer;
  final LatLng _inicioMedico = const LatLng(-24.7859, -65.4117);

  static const List<String> _codigosEstado = [
    'ACEPTADA',
    'EN_CAMINO',
    'EN_DOMICILIO',
    'FINALIZADA',
  ];

  final List<Map<String, String>> _estados = [
    {
      'titulo': 'Visita aceptada',
      'subtitulo': 'El profesional confirmó la guardia y prepara su maletín.',
      'botonMedico': 'Salir hacia el domicilio →',
    },
    {
      'titulo': 'Médico en camino',
      'subtitulo': 'El profesional se está trasladando hacia el domicilio.',
      'botonMedico': 'Confirmar llegada al domicilio →',
    },
    {
      'titulo': 'Atendiendo en domicilio',
      'subtitulo': 'Evaluación médica en curso en el domicilio.',
      'botonMedico': 'Cargar diagnóstico y finalizar ✓',
    },
    {
      'titulo': 'Visita finalizada',
      'subtitulo': 'La atención concluyó y el informe clínico fue emitido.',
      'botonMedico': 'Volver al panel médico',
    },
  ];

  @override
  void initState() {
    super.initState();
    _sincronizarIndiceConEstado(widget.solicitud.estado);
    if (widget.solicitud.diagnosticoMedico != null) {
      _informeMedicoFinal = widget.solicitud.diagnosticoMedico!;
    }

    // El paciente consulta a Neon cada 3 segundos para ver si el médico avanzó
    if (!widget.esVistaMedico) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        final actualizada = await ApiService.consultarSolicitud(
          widget.solicitud.id,
        );
        if (actualizada != null && mounted) {
          setState(() {
            _sincronizarIndiceConEstado(actualizada.estado);
            if (actualizada.diagnosticoMedico != null &&
                actualizada.diagnosticoMedico!.isNotEmpty) {
              _informeMedicoFinal = actualizada.diagnosticoMedico!;
            }
          });
        }
      });
    }
  }

  void _sincronizarIndiceConEstado(String estadoDB) {
    final idx = _codigosEstado.indexOf(estadoDB);
    if (idx != -1) {
      _estadoActual = idx;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  LatLng get _posicionActualMedico {
    final destino = widget.solicitud.ubicacion;
    if (_estadoActual == 0) return _inicioMedico;
    if (_estadoActual == 1) {
      return LatLng(
        (_inicioMedico.latitude + destino.latitude) / 2,
        (_inicioMedico.longitude + destino.longitude) / 2,
      );
    }
    return destino;
  }

  Future<void> _avanzarPasoEstado() async {
    if (_estadoActual < _estados.length - 1) {
      setState(() => _estadoActual++);
      final nuevoCodigo = _codigosEstado[_estadoActual];
      widget.solicitud.estado = nuevoCodigo;
      await ApiService.actualizarEstado(widget.solicitud.id, nuevoCodigo);
    }
  }

  Future<void> _abrirLlamada() async {
    final uri = Uri.parse('tel:${widget.solicitud.telefonoPaciente}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _abrirWhatsApp() async {
    final tel = widget.solicitud.telefonoPaciente.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final mensaje = Uri.encodeComponent(
      'Hola, te escribo desde DomiGuardia Salta por la visita en ${widget.solicitud.domicilio}.',
    );
    final uri = Uri.parse('https://wa.me/$tel?text=$mensaje');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _abrirGoogleMaps() async {
    final lat = widget.solicitud.ubicacion.latitude;
    final lng = widget.solicitud.ubicacion.longitude;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _abrirModalInformeMedico() {
    final TextEditingController evolucionCtrl = TextEditingController(
      text: 'Paciente lúcido, afebril al momento del examen. Se indica reposo por 48 hs, buena hidratación y paracetamol 500mg cada 8 hs.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cierre de Guardia · Informe Clínico',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escribí el diagnóstico e indicaciones que le quedarán registradas al paciente:',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: evolucionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Diagnóstico presuntivo e indicaciones...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Guardar evolución y finalizar visita'),
                  onPressed: () async {
                    final textoDiagnostico = evolucionCtrl.text;
                    Navigator.pop(ctx);
                    setState(() {
                      _informeMedicoFinal = textoDiagnostico;
                      widget.solicitud.diagnosticoMedico = textoDiagnostico;
                      widget.solicitud.estado = 'FINALIZADA';
                      _estadoActual = 3;
                    });
                    await ApiService.actualizarEstado(
                      widget.solicitud.id,
                      'FINALIZADA',
                      diagnostico: textoDiagnostico,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final finalizado = _estadoActual == _estados.length - 1;
    final destino = widget.solicitud.ubicacion;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esVistaMedico
              ? 'GESTIÓN DE VISITA EN CURSO'
              : 'SEGUIMIENTO EN VIVO',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAPA DE SEGUIMIENTO EN TIEMPO REAL
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 210,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: destino,
                    initialZoom: 13.8,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.domiguardia.salta',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_posicionActualMedico, destino],
                          color: colorScheme.primary,
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: destino,
                          width: 45,
                          height: 45,
                          child: const Icon(
                            Icons.home_rounded,
                            color: Colors.red,
                            size: 38,
                          ),
                        ),
                        Marker(
                          point: _posicionActualMedico,
                          width: 42,
                          height: 42,
                          child: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botones rápidos de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.phone_in_talk_outlined, size: 17),
                    label: const Text('Llamar', style: TextStyle(fontSize: 13)),
                    onPressed: _abrirLlamada,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 17),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(fontSize: 13),
                    ),
                    onPressed: _abrirWhatsApp,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.near_me_outlined, size: 17),
                    label: const Text(
                      'Ruta GPS',
                      style: TextStyle(fontSize: 13),
                    ),
                    onPressed: _abrirGoogleMaps,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Banner de estado actual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: finalizado
                    ? Colors.green.withValues(alpha: 0.12)
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: finalizado
                      ? Colors.green
                      : colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    finalizado
                        ? 'ATENCIÓN COMPLETADA'
                        : 'ESTADO ACTUAL (PASO ${_estadoActual + 1} DE 4)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: finalizado ? Colors.green : colorScheme.primary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _estados[_estadoActual]['titulo']!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_estados[_estadoActual]['subtitulo']!),
                ],
              ),
            ),

            if (_informeMedicoFinal.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'INDICACIONES DEL PROFESIONAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _informeMedicoFinal,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Línea de tiempo
            ...List.generate(_estados.length, (index) {
              final completado = index <= _estadoActual;
              final esActual = index == _estadoActual;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: completado
                          ? colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.3),
                      child: Icon(
                        index < _estadoActual ? Icons.check : Icons.circle,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _estados[index]['titulo']!,
                        style: TextStyle(
                          fontWeight: esActual
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: completado ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Ficha de la guardia
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('ID Guardia', '#${widget.solicitud.id}'),
                    const Divider(height: 16),
                    _infoRow(
                      'Paciente',
                      '${widget.solicitud.nombrePaciente} (${widget.solicitud.paraQuien})',
                    ),
                    const Divider(height: 16),
                    _infoRow('Motivo', widget.solicitud.motivo),
                    const Divider(height: 16),
                    _infoRow(
                      'Síntomas',
                      widget.solicitud.observacionesSintomas,
                    ),
                    const Divider(height: 16),
                    _infoRow('Domicilio', widget.solicitud.domicilio),
                    const Divider(height: 16),
                    _infoRow('Referencias', widget.solicitud.referenciasCasa),
                    const Divider(height: 16),
                    _infoRow(
                      'Pago',
                      '${widget.solicitud.metodoPago} (\$30.000)',
                    ),
                    const Divider(height: 16),
                    _infoRow(
                      'Profesional',
                      'Dr. Martín Gómez (MP 4821)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lógica final del botón inferior
            if (widget.esVistaMedico)
              // Si es médico, ve los botones para avanzar
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(
                    finalizado
                        ? Icons.check_circle_outline
                        : Icons.fast_forward,
                  ),
                  label: Text(
                    finalizado
                        ? 'Volver al panel'
                        : _estados[_estadoActual]['botonMedico']!,
                  ),
                  onPressed: () {
                    if (_estadoActual == 2) {
                      _abrirModalInformeMedico();
                    } else if (!finalizado) {
                      _avanzarPasoEstado();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              )
            else if (finalizado)
              // Si es paciente y ya terminó, solo ve el botón de volver
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.home_filled),
                  label: const Text('Volver al inicio'),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            else
              // Si es paciente y está en curso, NO ve ningún botón engañoso, solo un aviso
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Esta pantalla se actualiza automáticamente.',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
