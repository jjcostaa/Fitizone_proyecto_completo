import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../widgets/success_check_dialog.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  static const _kRememberKey = 'fitzone_remember_me';
  static const _kRememberEmailKey = 'fitzone_remember_email';
  static const _kRememberPassKey = 'fitzone_remember_pass';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;
  String? _inlineError;

  // Controlador estrictamente visual para animación suave de entrada
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberKey) ?? false;
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember) {
        _emailCtrl.text = prefs.getString(_kRememberEmailKey) ?? '';
        _passCtrl.text = prefs.getString(_kRememberPassKey) ?? '';
      }
    });
  }

  Future<void> _persistCredentialsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberKey, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_kRememberEmailKey, _emailCtrl.text.trim());
      await prefs.setString(_kRememberPassKey, _passCtrl.text);
    } else {
      await prefs.remove(_kRememberEmailKey);
      await prefs.remove(_kRememberPassKey);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;

    FitZoneApp.messengerKey.currentState?.clearSnackBars();
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    final ok = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
      deferNavigation: true,
    );

    if (!mounted) return;
    if (ok) {
      await _persistCredentialsIfNeeded();
      TextInput.finishAutofillContext();
      if (!mounted) return;
      final user = auth.pendingUser ?? auth.user;
      final rolTexto = user?.isAdmin == true
          ? 'Administrador'
          : (user?.isEntrenador == true ? 'Entrenador' : 'Miembro');

      await SuccessCheckDialog.show(
        context,
        title: 'Sesión iniciada',
        subtitle: 'Bienvenido, ${user?.nombre ?? ''}\nAcceso como $rolTexto',
        duration: const Duration(milliseconds: 650),
      );

      auth.commitPendingSession();

      FitZoneApp.messengerKey.currentState
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.cardElevated,
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bienvenido, ${user?.nombre ?? ''} ($rolTexto)',
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
    } else {
      final rawErr = auth.error ?? '';
      final friendly = (rawErr.contains('SocketException') ||
              rawErr.contains('ClientException') ||
              rawErr.contains('Failed host') ||
              rawErr.contains('TimeoutException'))
          ? 'El servidor tardó demasiado en responder. Inténtalo nuevamente.'
          : 'Correo o contraseña incorrectos. Verifica tus datos e inténtalo nuevamente.';

      FitZoneApp.messengerKey.currentState?.clearSnackBars();
      setState(() => _inlineError = friendly);
    }
  }

  void _showForgotPasswordInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
        title: const Text('Recuperar contraseña', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Acércate a recepción en FitZone Fitness Club o escríbenos a fitzonegym.oficial@gmail.com para restablecer tu acceso.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: AppTheme.primaryCrimson, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    const radius = BorderRadius.all(Radius.circular(14));
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppTheme.textMuted.withValues(alpha: 0.78),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: const Color(0xFF0C0C10).withValues(alpha: 0.88),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: UnconstrainedBox(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF18181E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.borderSubtle,
                width: 1,
              ),
            ),
            child: Icon(prefixIcon, size: 17, color: AppTheme.textSecondary),
          ),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 48),
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: suffixIcon,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppTheme.borderSubtle, width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppTheme.borderSubtle, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppTheme.primaryCrimson, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppTheme.primaryCrimson, width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppTheme.primaryCrimson, width: 1.5),
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFE57373),
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Fondo fotográfico de gimnasio oscuro con encuadre atmosférico
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.25),
            color: Colors.black.withValues(alpha: 0.52),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),

          // 2) Viñeta cinematográfica vertical para máxima legibilidad
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.28, 0.60, 1.0],
                colors: [
                  const Color(0xFF09090C).withValues(alpha: 0.78),
                  const Color(0xFF0B0B0F).withValues(alpha: 0.56),
                  const Color(0xFF0A0A0D).withValues(alpha: 0.90),
                  const Color(0xFF070709).withValues(alpha: 0.98),
                ],
              ),
            ),
          ),

          // 3) Contenido principal centrado con ancho máximo responsive
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Encabezado de marca con logo oficial limpio y sobrio (sin brillo rojo)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0E0E12),
                                        border: Border.all(
                                          color: AppTheme.borderSubtle,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF0E0E12),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Image.asset(
                                          'assets/images/logo_oficial.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.fitness_center_rounded,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'FITZONE',
                                              style: TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 3.4,
                                                color: AppTheme.textPrimary,
                                                height: 1.05,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.primaryCrimson,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'FITNESS CLUB',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 3.0,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Insignia decorativa sobria
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16161C).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.borderSubtle,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryCrimson,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'CLUB',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.4,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // Kicker editorial refinado
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 2,
                                  color: AppTheme.primaryCrimson,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'DISCIPLINA · FUERZA · EVOLUCIÓN',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Titular de alto contraste mate
                            const Text(
                              'TU SIGUIENTE NIVEL',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.08,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'COMIENZA AQUÍ.',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.12,
                                color: AppTheme.primaryCrimson,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Accede a tu espacio de entrenamiento y continúa construyendo tu mejor versión.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Tarjeta oscura esmerilada sobria (sin brillo rojo)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      color: const Color(0xFF141418).withValues(alpha: 0.90),
                                      border: Border.all(
                                        color: AppTheme.borderSubtle,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Cabecera discreta dentro de la tarjeta
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryCrimson,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'ACCESO DE MIEMBROS',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.5,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 18),

                                        // Alerta de error sobria
                                        if (_inlineError != null) ...[
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryMuted,
                                              borderRadius: BorderRadius.circular(13),
                                              border: Border.all(
                                                color: AppTheme.primaryCrimson.withValues(alpha: 0.45),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.only(top: 1),
                                                  child: Icon(
                                                    Icons.error_outline_rounded,
                                                    color: AppTheme.primaryCrimson,
                                                    size: 19,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    _inlineError!,
                                                    style: const TextStyle(
                                                      color: AppTheme.textPrimary,
                                                      fontSize: 12.8,
                                                      fontWeight: FontWeight.w500,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                        ],

                                        // Correo electrónico y Contraseña con autocompletado nativo
                                        AutofillGroup(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'CORREO ELECTRÓNICO',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.3,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _emailCtrl,
                                                keyboardType: TextInputType.emailAddress,
                                                autofillHints: const [AutofillHints.email, AutofillHints.username],
                                                textInputAction: TextInputAction.next,
                                                onChanged: (_) {
                                                  if (_inlineError != null) setState(() => _inlineError = null);
                                                },
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                decoration: _fieldDecoration(
                                                  hintText: 'tucorreo@fitzone.com',
                                                  prefixIcon: Icons.mail_outline_rounded,
                                                ),
                                                validator: (v) =>
                                                    (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'CONTRASEÑA',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.3,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _passCtrl,
                                                obscureText: _obscure,
                                                autofillHints: const [AutofillHints.password],
                                                textInputAction: TextInputAction.done,
                                                onChanged: (_) {
                                                  if (_inlineError != null) setState(() => _inlineError = null);
                                                },
                                                onFieldSubmitted: (_) => _submit(),
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                decoration: _fieldDecoration(
                                                  hintText: '••••••••',
                                                  prefixIcon: Icons.lock_outline_rounded,
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscure
                                                          ? Icons.visibility_off_outlined
                                                          : Icons.visibility_outlined,
                                                      size: 19,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                    onPressed: () => setState(() => _obscure = !_obscure),
                                                  ),
                                                ),
                                                validator: (v) =>
                                                    (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // Recordar datos + ¿Olvidaste tu contraseña?
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: Checkbox(
                                                        value: _rememberMe,
                                                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                                        activeColor: AppTheme.primaryCrimson,
                                                        checkColor: Colors.white,
                                                        side: const BorderSide(
                                                          color: AppTheme.borderSubtle,
                                                          width: 1.4,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Recordar mis datos',
                                                      style: TextStyle(
                                                        color: AppTheme.textSecondary,
                                                        fontSize: 12.2,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _showForgotPasswordInfo,
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                                              ),
                                              child: const Text(
                                                '¿Olvidaste tu contraseña?',
                                                style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 12.2,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 14),

                                        // Botón CTA sólido mate (sin brillo ni glow)
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton(
                                            onPressed: auth.isLoading ? null : _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryCrimson,
                                              disabledBackgroundColor: AppTheme.cardElevated,
                                              elevation: 0,
                                              shadowColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: auth.isLoading
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.3,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        'INICIAR SESIÓN',
                                                        style: TextStyle(
                                                          fontSize: 14.5,
                                                          fontWeight: FontWeight.w800,
                                                          letterSpacing: 1.5,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Icon(Icons.arrow_forward_rounded, size: 19),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Sello de seguridad
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'ACCESO PERSONAL · ATENCIÓN EXCLUSIVA',
                                  style: TextStyle(
                                    fontSize: 10.2,
                                    letterSpacing: 1.3,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Separador sobrio
                            const Divider(color: AppTheme.borderSubtle, height: 1),

                            const SizedBox(height: 18),

                            // Acción de registro preservada íntegramente
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '¿NECESITAS ACCESO?',
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 0.9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _CreateAccountButton(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          transitionDuration: const Duration(milliseconds: 240),
                                          pageBuilder: (_, _, _) => const RegisterScreen(),
                                          transitionsBuilder: (_, anim, _, child) {
                                            final slide = Tween<Offset>(
                                              begin: const Offset(0, 0.08),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                                            return FadeTransition(
                                              opacity: anim,
                                              child: SlideTransition(position: slide, child: child),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            const Center(
                              child: Text(
                                '© 2026 FITZONE FITNESS CLUB',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAccountButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CreateAccountButton({required this.onTap});

  @override
  State<_CreateAccountButton> createState() => _CreateAccountButtonState();
}

class _CreateAccountButtonState extends State<_CreateAccountButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: _pressed
              ? AppTheme.cardElevated
              : (_hovered ? AppTheme.cardElevated : AppTheme.cardDark),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            splashColor: AppTheme.primaryCrimson.withValues(alpha: 0.2),
            highlightColor: AppTheme.primaryCrimson.withValues(alpha: 0.1),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hovered || _pressed
                      ? AppTheme.primaryCrimson.withValues(alpha: 0.7)
                      : AppTheme.borderSubtle,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'CREA TU CUENTA',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: AppTheme.primaryCrimson),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
