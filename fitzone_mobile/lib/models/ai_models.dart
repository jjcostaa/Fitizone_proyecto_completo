class MlPredictionModel {
  final String nombre;
  final String correo;
  final double probabilidadCancelar;
  final double probabilidadPorcentaje;
  final String prediccion;
  final String nivelRiesgo;
  final String segmento;
  final List<String> recomendaciones;

  MlPredictionModel({
    required this.nombre,
    required this.correo,
    required this.probabilidadCancelar,
    required this.probabilidadPorcentaje,
    required this.prediccion,
    required this.nivelRiesgo,
    required this.segmento,
    required this.recomendaciones,
  });

  factory MlPredictionModel.fromJson(Map<String, dynamic> json) {
    final prob = (json['probabilidad_cancelar'] as num?)?.toDouble() ?? 0.0;
    final pct = (json['probabilidad_porcentaje'] as num?)?.toDouble() ?? (prob * 100);
    final rawTips = json['recomendaciones'];
    final tips = rawTips is List ? rawTips.map((e) => e.toString()).toList() : <String>[];

    return MlPredictionModel(
      nombre: (json['nombre'] ?? 'Usuario FitZone').toString(),
      correo: (json['correo'] ?? '').toString(),
      probabilidadCancelar: prob,
      probabilidadPorcentaje: pct,
      prediccion: (json['prediccion'] ?? 'NO').toString(),
      nivelRiesgo: (json['nivel_riesgo'] ?? (prob >= 0.65 ? 'ALTO' : prob >= 0.35 ? 'MEDIO' : 'BAJO')).toString(),
      segmento: (json['segmento'] ?? 'Miembro Casual').toString(),
      recomendaciones: tips,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'correo': correo,
        'probabilidad_cancelar': probabilidadCancelar,
        'probabilidad_porcentaje': probabilidadPorcentaje,
        'prediccion': prediccion,
        'nivel_riesgo': nivelRiesgo,
        'segmento': segmento,
        'recomendaciones': recomendaciones,
      };
}

class RocPoint {
  final double fpr;
  final double tpr;

  RocPoint({required this.fpr, required this.tpr});

  factory RocPoint.fromJson(Map<String, dynamic> json) {
    return RocPoint(
      fpr: (json['fpr'] as num?)?.toDouble() ?? 0.0,
      tpr: (json['tpr'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ConfusionMatrixData {
  final int tn;
  final int fp;
  final int fn;
  final int tp;

  ConfusionMatrixData({
    required this.tn,
    required this.fp,
    required this.fn,
    required this.tp,
  });

  factory ConfusionMatrixData.fromJson(Map<String, dynamic> json) {
    return ConfusionMatrixData(
      tn: (json['tn'] as num?)?.toInt() ?? 0,
      fp: (json['fp'] as num?)?.toInt() ?? 0,
      fn: (json['fn'] as num?)?.toInt() ?? 0,
      tp: (json['tp'] as num?)?.toInt() ?? 0,
    );
  }
}

class FeatureImportance {
  final String variable;
  final double importancia;

  FeatureImportance({required this.variable, required this.importancia});

  factory FeatureImportance.fromJson(Map<String, dynamic> json) {
    return FeatureImportance(
      variable: (json['variable'] ?? '').toString(),
      importancia: (json['importancia'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ModelScore {
  final String modelo;
  final double accuracy;
  final double precision;
  final double recall;
  final double f1Score;
  final double rocAuc;
  final ConfusionMatrixData? matrizConfusion;
  final List<RocPoint> curvaRoc;

  ModelScore({
    required this.modelo,
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.rocAuc,
    this.matrizConfusion,
    this.curvaRoc = const [],
  });

  factory ModelScore.fromJson(Map<String, dynamic> json) {
    final cmRaw = json['matriz_confusion'];
    final rocRaw = json['curva_roc'] as List? ?? [];
    return ModelScore(
      modelo: (json['modelo'] ?? '').toString(),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      precision: (json['precision'] as num?)?.toDouble() ?? 0.0,
      recall: (json['recall'] as num?)?.toDouble() ?? 0.0,
      f1Score: (json['f1_score'] as num?)?.toDouble() ?? 0.0,
      rocAuc: (json['roc_auc'] as num?)?.toDouble() ?? 0.0,
      matrizConfusion: cmRaw is Map<String, dynamic> ? ConfusionMatrixData.fromJson(cmRaw) : null,
      curvaRoc: rocRaw.map((e) => RocPoint.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ClusterSegment {
  final String segmento;
  final int cantidad;
  final double porcentaje;
  final double frecuenciaPromedio;
  final double satisfaccionPromedio;
  final double tasaCancelacion;

  ClusterSegment({
    required this.segmento,
    required this.cantidad,
    required this.porcentaje,
    required this.frecuenciaPromedio,
    required this.satisfaccionPromedio,
    required this.tasaCancelacion,
  });

  factory ClusterSegment.fromJson(Map<String, dynamic> json) {
    return ClusterSegment(
      segmento: (json['segmento'] ?? '').toString(),
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0.0,
      frecuenciaPromedio: (json['frecuencia_promedio'] as num?)?.toDouble() ?? 0.0,
      satisfaccionPromedio: (json['satisfaccion_promedio'] as num?)?.toDouble() ?? 0.0,
      tasaCancelacion: (json['tasa_cancelacion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MlMetricsReport {
  final String modeloGanador;
  final int totalRegistros;
  final double silhouetteScore;
  final List<ModelScore> comparacion;
  final List<ClusterSegment> segmentos;
  final List<FeatureImportance> importanciaVariables;

  MlMetricsReport({
    required this.modeloGanador,
    required this.totalRegistros,
    required this.silhouetteScore,
    required this.comparacion,
    required this.segmentos,
    this.importanciaVariables = const [],
  });

  factory MlMetricsReport.fromJson(Map<String, dynamic> json) {
    final ds = json['dataset'] as Map<String, dynamic>? ?? {};
    final cl = json['clustering'] as Map<String, dynamic>? ?? {};
    final rawModels = json['comparacion_modelos'] as List? ?? [];
    final rawSegs = cl['segmentos'] as List? ?? [];
    final rawFeats = json['importancia_variables'] as List? ?? [];

    return MlMetricsReport(
      modeloGanador: (json['modelo_ganador'] ?? 'Random Forest').toString(),
      totalRegistros: (ds['total_registros'] as num?)?.toInt() ?? 0,
      silhouetteScore: (cl['silhouette_score'] as num?)?.toDouble() ?? 0.0,
      comparacion: rawModels.map((e) => ModelScore.fromJson(e as Map<String, dynamic>)).toList(),
      segmentos: rawSegs.map((e) => ClusterSegment.fromJson(e as Map<String, dynamic>)).toList(),
      importanciaVariables: rawFeats.map((e) => FeatureImportance.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OptimizationResult {
  final String status;
  final double costoTotal;
  final List<InstructorAssignment> asignaciones;

  OptimizationResult({
    required this.status,
    required this.costoTotal,
    required this.asignaciones,
  });

  factory OptimizationResult.fromJson(Map<String, dynamic> json) {
    final raw = json['asignaciones'] as List? ?? [];
    return OptimizationResult(
      status: (json['status'] ?? 'Unknown').toString(),
      costoTotal: (json['costo_total'] as num?)?.toDouble() ?? 0.0,
      asignaciones: raw.map((e) => InstructorAssignment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class InstructorAssignment {
  final String instructor;
  final double capacidad;
  final double horasUtilizadas;
  final List<Map<String, dynamic>> clases;

  InstructorAssignment({
    required this.instructor,
    required this.capacidad,
    required this.horasUtilizadas,
    required this.clases,
  });

  factory InstructorAssignment.fromJson(Map<String, dynamic> json) {
    final rawClases = json['clases'] as List? ?? [];
    return InstructorAssignment(
      instructor: (json['instructor'] ?? '').toString(),
      capacidad: (json['capacidad'] as num?)?.toDouble() ?? 0.0,
      horasUtilizadas: (json['horas_utilizadas'] as num?)?.toDouble() ?? 0.0,
      clases: rawClases.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }
}
