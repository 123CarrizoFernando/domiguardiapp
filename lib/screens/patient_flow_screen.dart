import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/solicitud_model.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import 'visit_tracking_screen.dart';

class PatientFlowScreen extends StatefulWidget {
  const PatientFlowScreen({super.key});

  @override
  State<PatientFlowScreen> createState() => _PatientFlowScreenState();
}

class _PatientFlowScreenState extends State<PatientFlowScreen> {
  int _step = 1;
  bool _enviandoSolicitud = false;
  bool _esParaFamiliar = true;
  String _familiarRelacion = 'Madre / padre';

  final TextEditingController _nombreCtrl = TextEditingController(
    text: 'Carlos Ruiz',
  );
  final TextEditingController _telefonoCtrl = TextEditingController(
    text: '3875123456',
  );
  final TextEditingController _domicilioCtrl = TextEditingController(
    text: '1 de Mayo 450',
  );
  final TextEditingController _referenciasCtrl = TextEditingController(
    text: 'Portón negro, timbre 2',
  );
  final TextEditingController _sintomasCtrl = TextEditingController();

  String _barrio = 'Centro';
  String _horario = 'Lo antes posible';
  String _motivo = 'Consulta general';
  String _metodoPago = 'Mercado Pago / Transferencia';

  final MapController _mapController = MapController();
  LatLng _ubicacionSeleccionada = coordenadasBarriosSalta['Centro']!;

  final List<String> _horarios = [
    'Lo antes posible',
    'Hoy · 16:00–18:00',
    'Hoy · 18:00–20:00',
    'Hoy · 20:00–22:00',
  ];

  final List<String> _motivos = [
    'Consulta general',
    'Fiebre / malestar',
    'Dolor',
    'Adulto mayor',
    'Control clínico',
    'Otro motivo',
  ];

  final List<String> _metodosPago = [
    'Mercado Pago / Transferencia',
    'Efectivo al profesional',
    'Obra Social / Reintegro',
  ];

  void _cambiarBarrio(String nuevoBarrio) {
    setState(() {
      _barrio = nuevoBarrio;
      _ubicacionSeleccionada = coordenadasBarriosSalta[nuevoBarrio]!;
    });
    _mapController.move(_ubicacionSeleccionada, 15.0);
  }

  Future<void> _confirmarYEnviarSolicitud() async {
    setState(() => _enviandoSolicitud = true);

    final nuevaSolicitud = SolicitudModel(
      id: 'LOCAL-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      nombrePaciente: _nombreCtrl.text.isEmpty ? 'Paciente' : _nombreCtrl.text,
      telefonoPaciente: _telefonoCtrl.text.isEmpty
          ? '3875000000'
          : _telefonoCtrl.text,
      paraQuien: _esParaFamiliar ? 'Familiar ($_familiarRelacion)' : 'Para mí',
      domicilio:
          '${_domicilioCtrl.text.isEmpty ? "Sin calle" : _domicilioCtrl.text}, $_barrio',
      referenciasCasa: _referenciasCtrl.text.isEmpty
          ? 'Sin referencias'
          : _referenciasCtrl.text,
      barrio: _barrio,
      horario: _horario,
      motivo: _motivo,
      observacionesSintomas: _sintomasCtrl.text.isEmpty
          ? 'Evaluación clínica solicitada en domicilio.'
          : _sintomasCtrl.text,
      metodoPago: _metodoPago,
      distanciaKm: 1.8,
      tiempo: 'Recién ahora',
      ubicacion: _ubicacionSeleccionada,
    );

    // Envía a Node.js + Neon PostgreSQL (y si está apagado, usa el respaldo local)
    final solicitudGuardada = await ApiService.crearSolicitud(nuevaSolicitud);

    if (!mounted) return;
    setState(() => _enviandoSolicitud = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VisitTrackingScreen(
          esVistaMedico: false,
          solicitud: solicitudGuardada,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _domicilioCtrl.dispose();
    _referenciasCtrl.dispose();
    _sintomasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SOLICITUD DE VISITA · PASO $_step DE 3',
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
            // Barra de progreso de 3 pasos
            Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    height: 5,
                    decoration: BoxDecoration(
                      color: index < _step
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            if (_step == 1) _buildStep1(colorScheme),
            if (_step == 2) _buildStep2(colorScheme),
            if (_step == 3) _buildStep3(colorScheme),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _enviandoSolicitud
                        ? null
                        : () {
                            if (_step > 1) {
                              setState(() => _step--);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                    child: Text(_step == 1 ? 'Cancelar' : '← Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _enviandoSolicitud
                        ? null
                        : () {
                            if (_step < 3) {
                              setState(() => _step++);
                            } else {
                              _confirmarYEnviarSolicitud();
                            }
                          },
                    child: _enviandoSolicitud
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _step < 3 ? 'Continuar →' : 'Confirmar solicitud ✓',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Domicilio',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Contanos para quién es la visita y marcá la ubicación en el mapa.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        const Text(
          '¿Para quién es la visita?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const SizedBox(
                  width: double.infinity,
                  child: Text('Para mí', textAlign: TextAlign.center),
                ),
                selected: !_esParaFamiliar,
                onSelected: (_) => setState(() => _esParaFamiliar = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const SizedBox(
                  width: double.infinity,
                  child: Text('Para un familiar', textAlign: TextAlign.center),
                ),
                selected: _esParaFamiliar,
                onSelected: (_) => setState(() => _esParaFamiliar = true),
              ),
            ),
          ],
        ),
        if (_esParaFamiliar) ...[
          const SizedBox(height: 16),
          const Text(
            '¿Quién es?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _familiarRelacion,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              'Madre / padre',
              'Hijo / hija',
              'Abuelo / abuela',
              'Otro',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _familiarRelacion = v!),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del paciente',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono / Celular',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Barrio en Salta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _barrio,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: coordenadasBarriosSalta.keys
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (v) => _cambiarBarrio(v!),
        ),
        const SizedBox(height: 16),
        const Text(
          'Domicilio de la visita (Calle y número)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _domicilioCtrl,
          decoration: InputDecoration(
            hintText: 'Ej: 1 de Mayo 450',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.home_outlined, color: colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Referencias de la casa (Timbre, piso, rejas)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _referenciasCtrl,
          decoration: InputDecoration(
            hintText: 'Ej: Portón negro, tocar timbre 2',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.info_outline, color: colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tocá el mapa para clavar el pin exacto:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              '${_ubicacionSeleccionada.latitude.toStringAsFixed(4)}, ${_ubicacionSeleccionada.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 210,
            width: double.infinity,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _ubicacionSeleccionada,
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() => _ubicacionSeleccionada = point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.domiguardia.salta',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionSeleccionada,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horario y motivo',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Elegí una franja horaria y contanos brevemente qué sucede.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        const Text(
          '¿Cuándo te viene bien?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _horarios.map((h) {
            return ChoiceChip(
              label: Text(h),
              selected: _horario == h,
              onSelected: (_) => setState(() => _horario = h),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Motivo de la visita',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _motivos.map((m) {
            return ChoiceChip(
              label: Text(m),
              selected: _motivo == m,
              onSelected: (_) => setState(() => _motivo = m),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Describí los síntomas o antecedentes (Opcional)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sintomasCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ej: Fiebre de 38.5°C desde anoche, dolor al tragar, paciente hipertenso...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Si se trata de una emergencia con riesgo inmediato de vida, no esperes una visita domiciliaria: llamá al SAMEC (107).',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revisar y pagar',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Verificá los datos antes de confirmar la solicitud.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESUMEN DE SOLICITUD',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRow(
                  'Paciente',
                  '${_nombreCtrl.text} (${_esParaFamiliar ? _familiarRelacion : "Titular"})',
                ),
                const Divider(height: 20),
                _buildRow('Teléfono', _telefonoCtrl.text),
                const Divider(height: 20),
                _buildRow('Domicilio', '${_domicilioCtrl.text}, $_barrio'),
                const Divider(height: 20),
                _buildRow('Referencias', _referenciasCtrl.text),
                const Divider(height: 20),
                _buildRow('Horario', _horario),
                const Divider(height: 20),
                _buildRow('Motivo', _motivo),
                if (_sintomasCtrl.text.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildRow('Síntomas', _sintomasCtrl.text),
                ],
                const Divider(height: 24),
                const Text(
                  'Seleccioná el medio de pago',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _metodoPago,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _metodosPago
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _metodoPago = v!),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total consulta a domicilio',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Incluye traslado y receta / certificado',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        '\$30.000',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
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
