class ClaseModel {
  final String id;
  final String entrenadorId;
  final String nombreEntrenador;
  final String nombreClase;
  final String descripcion;

  ClaseModel({
    required this.id,
    required this.entrenadorId,
    required this.nombreEntrenador,
    required this.nombreClase,
    required this.descripcion,
  });

  factory ClaseModel.fromJson(Map<String, dynamic> json) {
    return ClaseModel(
      id: (json['id'] ?? '').toString(),
      entrenadorId: (json['entrenadorId'] ?? '').toString(),
      nombreEntrenador: (json['nombreEntrenador'] ?? 'Entrenador FitZone').toString(),
      nombreClase: (json['nombreClase'] ?? 'Clase FitZone').toString(),
      descripcion: (json['descripcion'] ?? 'Entrenamiento guiado en sede FitZone.').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entrenadorId': entrenadorId,
        'nombreEntrenador': nombreEntrenador,
        'nombreClase': nombreClase,
        'descripcion': descripcion,
      };
}

class PagoModel {
  final String id;
  final String usuarioId;
  final String nombre;
  final String membresia;
  final double monto;
  final DateTime fecha;

  PagoModel({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.membresia,
    required this.monto,
    required this.fecha,
  });

  DateTime get fechaVencimiento => fecha.add(const Duration(days: 30));
  int get diasRestantes => fechaVencimiento.difference(DateTime.now()).inDays;
  bool get estaActiva => diasRestantes >= 0;

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    DateTime parsed = DateTime.now();
    final raw = json['fecha'];
    if (raw is String) {
      parsed = DateTime.tryParse(raw) ?? DateTime.now();
    }
    return PagoModel(
      id: (json['id'] ?? '').toString(),
      usuarioId: (json['usuarioId'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      membresia: (json['membresia'] ?? 'Plan Mensual').toString(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      fecha: parsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuarioId': usuarioId,
        'nombre': nombre,
        'membresia': membresia,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
      };
}

class AnuncioModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String? imagenUrl;
  final String fechaInicio;
  final String fechaFin;

  AnuncioModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.imagenUrl,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory AnuncioModel.fromJson(Map<String, dynamic> json) {
    return AnuncioModel(
      id: (json['id'] ?? '').toString(),
      titulo: (json['titulo'] ?? 'Promoción FitZone').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      imagenUrl: json['imagenUrl']?.toString(),
      fechaInicio: (json['fechaInicio'] ?? '').toString(),
      fechaFin: (json['fechaFin'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'imagenUrl': imagenUrl,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
      };
}

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      text: (json['text'] ?? '').toString(),
      isUser: json['isUser'] == true,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };
}
