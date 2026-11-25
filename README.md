# FitZone — Plataforma Web, Móvil y en la Nube para Gimnasios (VIII Semestre)

Sistema integral de gestión, entrenamiento, analítica predictiva y optimización operativa para **FitZone Fitness Club** (Cartagena de Indias, Colombia), desarrollado como Proyecto Integrador de Aula de **VIII Semestre — Ingeniería de Sistemas** (*Fundación Universitaria Tecnológico Comfenalco*).

**Autores:** Steven Pereira · Rodolfo Sierra Simancas · Sergio Garcés Pineda · Jeison Balseiro Castro  
**Asignaturas Articuladas:** Minería de Datos II · Computación en la Nube · Computación Móvil · Ingeniería Económica  
**Docente:** Walter

---

## Despliegue en Producción (Cloud)

- **Backend & Portal Web (Render + Docker):** [https://fitzone-backend-vjpx.onrender.com](https://fitzone-backend-vjpx.onrender.com)
- **Monitoreo de Salud (Health Check):** [https://fitzone-backend-vjpx.onrender.com/api/health](https://fitzone-backend-vjpx.onrender.com/api/health)
- **Base de Datos (DBaaS):** MongoDB Atlas (`fitzone_db`)

---

## Estructura del Repositorio

```text
Fitizone_proyecto_completo/
├── backend/                  # Backend Spring Boot 3.4.4 (Java 21), Portal Web, Python ML y PuLP
│   ├── Dockerfile            # Imagen Docker multi-etapa (Java 21 + Python 3 venv)
│   ├── requirements.txt      # Dependencias Python (scikit-learn, pandas, numpy, joblib, pulp)
│   ├── modelo_optimizacion_json.py  # Optimización lineal entera de horarios e instructores (PuLP)
│   ├── ml/                   # Pipeline de Minería de Datos II
│   │   ├── train_models.py               # Comparativa RF, Gradient Boosting, MLP + K-Means
│   │   ├── predict_service.py            # Motor de inferencia en tiempo real
│   │   ├── analisis_predictivo_fitzone.ipynb  # Notebook científico reproducible
│   │   ├── dataset_fitzone_churn.csv     # Dataset estratificado (800 registros)
│   │   ├── model_metrics.json            # Métricas, curvas ROC-AUC, matriz de confusión y K-Means
│   │   └── *.joblib                      # Modelos entrenados serializados
│   └── src/                  # API REST JWT, Spring Security, MongoDB y vistas Thymeleaf + Chart.js
├── fitzone_mobile/           # Aplicación Móvil Multiplataforma (Flutter / Dart 3)
│   ├── lib/config/           # Tema visual y configuración de URL (local / Cloud)
│   ├── lib/models/           # Modelos de usuario, clases, pagos, anuncios, ML y PuLP
│   ├── lib/services/         # ApiService, PedometerService, OfflineCacheService, NotificationService
│   ├── lib/providers/        # AuthProvider y GymProvider (gestión de estado reactiva)
│   ├── lib/widgets/          # MlChartsSection (fl_chart), OfflineBanner, SuccessCheckDialog
│   └── lib/screens/          # Interfaces diferenciadas por rol: Usuario, Entrenador y Administrador
└── docs/                     # Documentación académica y técnica completa
    ├── INFORME_FINAL_PROYECTO_FITZONE_VIII_SEMESTRE.docx  # Informe formal APA 7.ª ed. con figuras y evaluación financiera
    ├── DOCUMENTACION_COMPLETA_FITZONE.docx                # Documentación técnica integral (API + Flutter)
    └── DOCUMENTACION_COMPLETA_FITZONE.md                  # Referencia técnica en Markdown
```

---

## Funcionalidades Principales

### 1. Backend REST, Seguridad y Nube (`backend/`)
- **Autenticación Stateless JWT + BCrypt** con soporte multi-rol (`USUARIO`, `ENTRENADOR`, `ADMIN`) y CORS global.
- **Endpoints optimizados:** Paginación móvil (`/api/usuarios/resumen`), gestión de clases, reservas, pagos/membresías, promociones, IMC, FitBot (`/api/chatbot/message`), Minería de Datos II (`/api/ml/*`), Optimización (`/api/admin/optimize`) y salud (`/api/health`).
- **Portal Web Analítico (`adminpanel.html`):** 4 gráficas interactivas con **Chart.js** (Comparativa de modelos, Curvas ROC-AUC, Importancia de Variables y Segmentación K-Means) + Matriz de Confusión 2×2.
- **FitBot (Groq Cloud LLM):** Asistente conversacional con `openai/gpt-oss-120b` y respaldo automático contextualizado con `reglamento.txt`.

### 2. Minería de Datos II y Optimización (`backend/ml/`)
- **Clasificación supervisada de deserción (Churn):**
  - **Random Forest (Modelo Ganador):** `90.0 %` Accuracy · `91.3 %` F1-Score · `96.3 %` ROC-AUC (`VN=60, FP=9, FN=7, VP=84`).
  - **Red Neuronal (MLP):** `86.9 %` Accuracy · `88.1 %` F1-Score · `93.7 %` ROC-AUC.
  - **Gradient Boosting:** `85.6 %` Accuracy · `87.6 %` F1-Score · `94.8 %` ROC-AUC.
- **Clustering No Supervisado (`K-Means, k=3`):** *Silhouette Score* `0.3349` (*Atleta Comprometido* `35.4 %`, *Miembro Casual* `35.1 %`, *Miembro en Riesgo* `29.5 %`).
- **Programación Lineal Entera (`PuLP`):** Asignación óptima de instructores y disciplinas minimizando el costo operativo.

### 3. Aplicación Móvil Flutter (`fitzone_mobile/`)
- **3 interfaces diferenciadas por rol:** Usuario (5 pestañas), Entrenador (4 pestañas) y Administrador (4 pestañas).
- **Podómetro en tiempo real (`sensors_plus`):** Detección de pasos por acelerómetro, cálculo de distancia/calorías y meta diaria independiente por usuario.
- **Modo Offline (`SharedPreferences` + `connectivity_plus`):** Persistencia local de sesión, clases, reservas, anuncios, pagos, historial de FitBot por cuenta y métricas ML.
- **Notificaciones Locales (`flutter_local_notifications`):** Alertas de cumplimiento de meta diaria y recordatorios programados en Android.
- **Gráficas Móviles (`fl_chart`):** Dona de riesgo, barras comparativas de modelos Python, curvas ROC-AUC, segmentación K-Means, importancia de variables y matriz de confusión.

---

## Ejecución Local Rápida

### Backend (Spring Boot + Python ML)
```bash
cd backend
pip install -r requirements.txt
./mvnw spring-boot:run
```

### App Móvil (Flutter)
```bash
cd fitzone_mobile
flutter pub get
# En navegador (Chrome):
flutter run -d chrome --web-port 5555
# Compilar APK conectado a la nube (Render):
flutter build apk --release --dart-define=FITZONE_API_URL=https://fitzone-backend-vjpx.onrender.com
```
