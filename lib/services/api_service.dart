import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/solicitud_model.dart';

class ApiService {
  // TU ENLACE DE RENDER OFICIAL
  static const String baseUrl = 'https://domiguardia-backend.onrender.com/api';

  static Map<String, dynamic>? usuarioLogueado;

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        usuarioLogueado = jsonDecode(response.body);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> registrar({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    required String telefono,
    String? matricula,
    String? especialidad,
    String? aliasCbu,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
          'rol': rol,
          'telefono': telefono,
          'matricula': matricula,
          'especialidad': especialidad,
          'alias_cbu': aliasCbu,
        }),
      );
      if (response.statusCode == 201) {
        usuarioLogueado = jsonDecode(response.body);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<List<SolicitudModel>> obtenerSolicitudesPendientes() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/solicitudes'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SolicitudModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<SolicitudModel> crearSolicitud(SolicitudModel nueva) async {
    try {
      // Le agregamos el paciente_id al JSON antes de enviarlo
      final jsonBody = nueva.toJson();
      if (usuarioLogueado != null) {
        jsonBody['paciente_id'] = usuarioLogueado!['id'];
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/solicitudes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(jsonBody),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 201) {
        return SolicitudModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return nueva;
  }

  static Future<void> actualizarEstado(
    String id,
    String nuevoEstado, {
    String? diagnostico,
  }) async {
    try {
      final body = {'estado': nuevoEstado, 'diagnostico_medico': diagnostico};

      // Si el médico acepta la visita, mandamos sus datos para que quede registrado
      if (nuevoEstado == 'ACEPTADA' &&
          usuarioLogueado != null &&
          usuarioLogueado!['rol'] == 'MEDICO') {
        body['medico_id'] = usuarioLogueado!['id'].toString();
        body['medico_nombre'] =
            'Dr. ${usuarioLogueado!['nombre']} (${usuarioLogueado!['matricula']})';
      }

      await http.patch(
        Uri.parse('$baseUrl/solicitudes/$id/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {}
  }

  static Future<SolicitudModel?> consultarSolicitud(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/solicitudes/$id'));
      if (response.statusCode == 200) {
        return SolicitudModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<List<SolicitudModel>> obtenerHistorial() async {
    try {
      // Ahora pedimos el historial enviando quién está logueado
      String url = '$baseUrl/historial';
      if (usuarioLogueado != null) {
        url +=
            '?usuario_id=${usuarioLogueado!['id']}&rol=${usuarioLogueado!['rol']}';
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SolicitudModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }
}
