import 'package:latlong2/latlong.dart';

class SolicitudModel {
  final String id;
  final String nombrePaciente;
  final String telefonoPaciente;
  final String paraQuien;
  final String domicilio;
  final String referenciasCasa;
  final String barrio;
  final String horario;
  final String motivo;
  final String observacionesSintomas;
  final String metodoPago;
  final double precio;
  final double distanciaKm;
  final String tiempo;
  final LatLng ubicacion;
  String estado;
  String? diagnosticoMedico;
  String? medicoNombre;
  String? medicoAlias;

  SolicitudModel({
    required this.id,
    this.nombrePaciente = 'Paciente Salta',
    this.telefonoPaciente = '+5493875000000',
    required this.paraQuien,
    required this.domicilio,
    this.referenciasCasa = 'Sin referencias adicionales',
    required this.barrio,
    required this.horario,
    required this.motivo,
    this.observacionesSintomas = 'Sin detalles adicionales',
    this.metodoPago = 'Mercado Pago / Transferencia',
    this.precio = 30000.0,
    required this.distanciaKm,
    required this.tiempo,
    required this.ubicacion,
    this.estado = 'PENDIENTE',
    this.diagnosticoMedico,
    this.medicoNombre,
    this.medicoAlias,
  });

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
    return SolicitudModel(
      id: json['id'].toString(),
      nombrePaciente: json['nombre_paciente'] ?? 'Paciente',
      telefonoPaciente: json['telefono_paciente'] ?? '',
      paraQuien: json['para_quien'] ?? 'Titular',
      domicilio: json['domicilio'] ?? '',
      referenciasCasa: json['referencias_casa'] ?? 'Sin referencias',
      barrio: json['barrio'] ?? 'Centro',
      horario: json['horario'] ?? 'Lo antes posible',
      motivo: json['motivo'] ?? 'Consulta general',
      observacionesSintomas: json['observaciones_sintomas'] ?? '',
      metodoPago: json['metodo_pago'] ?? 'Mercado Pago / Transferencia',
      precio: double.tryParse(json['precio'].toString()) ?? 30000.0,
      distanciaKm:
          double.tryParse(json['distancia_km']?.toString() ?? '1.5') ?? 1.5,
      tiempo: 'Reciente',
      ubicacion: LatLng(
        double.tryParse(json['latitud'].toString()) ?? -24.7891,
        double.tryParse(json['longitud'].toString()) ?? -65.4103,
      ),
      estado: json['estado'] ?? 'PENDIENTE',
      diagnosticoMedico: json['diagnostico_medico'],
      medicoNombre: json['medico_nombre'],
      medicoAlias: json['medico_alias'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_paciente': nombrePaciente,
      'telefono_paciente': telefonoPaciente,
      'para_quien': paraQuien,
      'domicilio': domicilio,
      'referencias_casa': referenciasCasa,
      'barrio': barrio,
      'horario': horario,
      'motivo': motivo,
      'observaciones_sintomas': observacionesSintomas,
      'metodo_pago': metodoPago,
      'precio': precio,
      'latitud': ubicacion.latitude,
      'longitud': ubicacion.longitude,
    };
  }
}

final Map<String, LatLng> coordenadasBarriosSalta = {
  'Centro': const LatLng(-24.7891, -65.4103),
  'Tres Cerritos': const LatLng(-24.7695, -65.3942),
  'Grand Bourg': const LatLng(-24.7812, -65.4485),
  'El Huaico': const LatLng(-24.7265, -65.4058),
  'Limache': const LatLng(-24.8322, -65.4350),
  'San Lorenzo': const LatLng(-24.7290, -65.4855),
  'Castañares': const LatLng(-24.7405, -65.4112),
};
