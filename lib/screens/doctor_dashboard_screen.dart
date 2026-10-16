import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/solicitud_model.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import 'visit_tracking_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _disponible = true;
  bool _cargandoServidor = false;
  bool _filtroPorKm = true;
  int _radioKm = 10;
  Timer? _autoRefreshTimer;

  final List<int> _radiosDisponibles = [1, 3, 5, 10, 15];
  final Set<String> _barriosSeleccionados = {
    'Centro',
    'Tres Cerritos',
    'Grand Bourg',
    'El Huaico',
    'Limache',
    'San Lorenzo',
    'Castañares',
  };

  final LatLng _posicionMedico = const LatLng(-24.7859, -65.4117);
  final List<SolicitudModel> _solicitudes = [];

  @override
  void initState() {
    super.initState();
    _cargarDesdeServidor();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_disponible && mounted) {
        _cargarDesdeServidor(silencioso: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDesdeServidor({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargandoServidor = true);
    final remotas = await ApiService.obtenerSolicitudesPendientes();
    if (!mounted) return;

    setState(() {
      _cargandoServidor = false;
      _solicitudes
        ..clear()
        ..addAll(remotas);
    });
  }

  Future<void> _abrirOAceptarVisita(SolicitudModel s) async {
    if (s.estado == 'PENDIENTE') {
      await ApiService.actualizarEstado(s.id, 'ACEPTADA');
      s.estado = 'ACEPTADA';
    }
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisitTrackingScreen(esVistaMedico: true, solicitud: s),
      ),
    );
    if (_disponible) {
      _cargarDesdeServidor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nombreDr = ApiService.usuarioLogueado?['nombre'] ?? 'Médico';

    final enCursoList = _solicitudes
        .where((s) => s.estado != 'PENDIENTE')
        .toList();
    final pendientesFiltradas = _solicitudes.where((s) {
      if (s.estado != 'PENDIENTE') return false;
      if (_filtroPorKm) {
        return s.distanciaKm <= _radioKm;
      } else {
        return _barriosSeleccionados.contains(s.barrio);
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dr. $nombreDr',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (_disponible)
            IconButton(
              icon: _cargandoServidor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.refresh, color: colorScheme.primary),
              tooltip: 'Sincronizar pedidos',
              onPressed: () => _cargarDesdeServidor(),
            ),
          IconButton(
            icon: Icon(
              Icons.account_balance_wallet_rounded,
              color: colorScheme.primary,
            ),
            tooltip: 'Mis Honorarios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(esModoMedico: true),
                ),
              );
            },
          ),
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ApiService.usuarioLogueado = null;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: _disponible
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.sensors,
                    color: _disponible ? Colors.green : Colors.grey,
                  ),
                ),
                title: const Text(
                  'Disponible para guardias',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _disponible
                      ? 'En línea · Buscando pacientes en Salta'
                      : 'Fuera de línea',
                ),
                value: _disponible,
                onChanged: (v) {
                  setState(() => _disponible = v);
                  if (v) _cargarDesdeServidor();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Cobertura
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mi cobertura',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const SizedBox(
                              width: double.infinity,
                              child: Text(
                                'Radio en km',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            selected: _filtroPorKm,
                            onSelected: (_) =>
                                setState(() => _filtroPorKm = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const SizedBox(
                              width: double.infinity,
                              child: Text(
                                'Barrios',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            selected: !_filtroPorKm,
                            onSelected: (_) =>
                                setState(() => _filtroPorKm = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_filtroPorKm) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton.outlined(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (_radioKm > 1) setState(() => _radioKm--);
                            },
                          ),
                          Column(
                            children: [
                              Text(
                                '$_radioKm km',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const Text(
                                'Radio de cobertura',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          IconButton.outlined(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _radioKm++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _radiosDisponibles.map((r) {
                          return ChoiceChip(
                            label: Text('$r km'),
                            selected: _radioKm == r,
                            onSelected: (_) => setState(() => _radioKm = r),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: coordenadasBarriosSalta.keys.map((barrio) {
                          final isSelected = _barriosSeleccionados.contains(
                            barrio,
                          );
                          return FilterChip(
                            label: Text(barrio),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _barriosSeleccionados.add(barrio);
                                } else {
                                  _barriosSeleccionados.remove(barrio);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _MetricBox(
                    label: 'Pendientes en zona',
                    value: _disponible ? '${pendientesFiltradas.length}' : '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBox(
                    label: 'En curso',
                    value: '${enCursoList.length}',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _MetricBox(label: 'Zona', value: 'Salta'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_disponible) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _posicionMedico,
                      initialZoom: 12.2,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.domiguardia.salta',
                      ),
                      if (_filtroPorKm)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _posicionMedico,
                              radius: _radioKm * 1000,
                              useRadiusInMeter: true,
                              color: colorScheme.primary.withValues(
                                alpha: 0.18,
                              ),
                              borderColor: colorScheme.primary,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _posicionMedico,
                            width: 40,
                            height: 40,
                            child: CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: const Icon(
                                Icons.local_hospital,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          ...pendientesFiltradas.map(
                            (s) => Marker(
                              point: s.ubicacion,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Si tiene guardias aceptadas en curso, las muestra arriba de todo
            if (enCursoList.isNotEmpty) ...[
              const Text(
                'Guardias en curso (Activas)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...enCursoList.map(
                (s) => _buildTarjetaSolicitud(s, colorScheme, esEnCurso: true),
              ),
              const SizedBox(height: 20),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Solicitudes pendientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_disponible)
                  TextButton.icon(
                    onPressed: () => _cargarDesdeServidor(),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Actualizar'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (!_disponible)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Estás fuera de línea',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() => _disponible = true);
                            _cargarDesdeServidor();
                          },
                          child: const Text('Activar disponibilidad'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_cargandoServidor)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (pendientesFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No hay solicitudes pendientes dentro de este radio en este momento.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...pendientesFiltradas.map(
                (s) => _buildTarjetaSolicitud(s, colorScheme, esEnCurso: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaSolicitud(
    SolicitudModel s,
    ColorScheme colorScheme, {
    required bool esEnCurso,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (esEnCurso ? Colors.orange : Colors.green)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    esEnCurso ? '● EN CURSO (${s.estado})' : '● ${s.horario}',
                    style: TextStyle(
                      color: esEnCurso ? Colors.orange : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '\$${s.precio.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.motivo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '📍 ${s.barrio} · a ${s.distanciaKm} km (${s.domicilio})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '👤 ${s.nombrePaciente} · ${s.paraQuien}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🩺 Síntomas: "${s.observacionesSintomas}"',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _abrirOAceptarVisita(s),
                child: Text(
                  esEnCurso
                      ? 'Retomar gestión de visita →'
                      : 'Aceptar visita →',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
