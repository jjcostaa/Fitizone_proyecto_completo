class ImcRegistroModel {
  final double peso;
  final double altura;
  final double imc;
  final String categoria;
  final DateTime fecha;

  ImcRegistroModel({
    required this.peso,
    required this.altura,
    required this.imc,
    required this.categoria,
    required this.fecha,
  });

  factory ImcRegistroModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final rawDate = json['fecha'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }
    return ImcRegistroModel(
      peso: (json['peso'] as num?)?.toDouble() ?? 0.0,
      altura: (json['altura'] as num?)?.toDouble() ?? 0.0,
      imc: (json['imc'] as num?)?.toDouble() ?? 0.0,
      categoria: json['categoria']?.toString() ?? 'Normal',
      fecha: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'peso': peso,
        'altura': altura,
        'imc': imc,
        'categoria': categoria,
        'fecha': fecha.toUtc().toIso8601String(),
      };
}

class UsuarioModel {
  final String id;
  final String nombre;
  final String apellido;
  final String correo;
  final String rol;
  final int edad;
  final double peso;
  final int altura;
  final String telefono;
  final String direccion;
  final String genero;
  final String objetivo;
  final String nivelActividad;
  final List<ImcRegistroModel> historialIMC;

  UsuarioModel({
    required this.id,
    required this.nombre,
    this.apellido = '',
    required this.correo,
    required this.rol,
    this.edad = 25,
    this.peso = 70.0,
    this.altura = 170,
    this.telefono = '',
    this.direccion = '',
    this.genero = 'hombre',
    this.objetivo = 'mantener',
    this.nivelActividad = 'Moderado',
    this.historialIMC = const [],
  });

  String get nombreCompleto =>
      apellido.isEmpty ? nombre : '$nombre $apellido'.trim();

  bool get isAdmin => rol.toUpperCase() == 'ADMIN';
  bool get isEntrenador => rol.toUpperCase() == 'ENTRENADOR';

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final rawImc = json['historialIMC'];
    final listImc = <ImcRegistroModel>[];
    if (rawImc is List) {
      for (final item in rawImc) {
        if (item is Map<String, dynamic>) {
          listImc.add(ImcRegistroModel.fromJson(item));
        }
      }
    }
    return UsuarioModel(
      id: (json['id'] ?? json['usuarioId'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Usuario').toString(),
      apellido: (json['apellido'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      rol: (json['rol'] ?? 'USUARIO').toString(),
      edad: (json['edad'] as num?)?.toInt() ?? 25,
      peso: (json['peso'] as num?)?.toDouble() ?? 70.0,
      altura: (json['altura'] as num?)?.toInt() ?? 170,
      telefono: (json['telefono'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
      genero: (json['genero'] ?? 'hombre').toString(),
      objetivo: (json['objetivo'] ?? 'mantener').toString(),
      nivelActividad: (json['nivelActividad'] ?? 'Moderado').toString(),
      historialIMC: listImc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'rol': rol,
        'edad': edad,
        'peso': peso,
        'altura': altura,
        'telefono': telefono,
        'direccion': direccion,
        'genero': genero,
        'objetivo': objetivo,
        'nivelActividad': nivelActividad,
        'historialIMC': historialIMC.map((e) => e.toJson()).toList(),
      };
}
