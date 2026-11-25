import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';

class FitbotScreen extends StatefulWidget {
  const FitbotScreen({super.key});

  @override
  State<FitbotScreen> createState() => _FitbotScreenState();
}

class _FitbotScreenState extends State<FitbotScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<String> _quickPrompts = const [
    '¿Qué planes y precios tienen?',
    'Horarios del gimnasio',
    'Clases grupales disponibles',
    'Contacto y ubicación',
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    final userId = context.read<AuthProvider>().user?.id;
    await context.read<GymProvider>().sendChatMessage(text, userId: userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final user = context.watch<AuthProvider>().user;

    return Column(
      children: [
        // Barra superior sobria
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCrimson,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FitBot Asistente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                        Text(
                          'Consultas sobre planes, clases y horarios',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Nueva conversación',
                    onPressed: () => gym.clearChat(user?.id ?? '', user?.nombre ?? 'Atleta'),
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickPrompts
                      .map(
                        (q) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: gym.loadingChat ? null : () => _send(q),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(8),
                                border: AppTheme.neonBorder,
                              ),
                              child: Text(
                                q,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),

        // Mensajes
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: gym.chatMessages.length + (gym.loadingChat ? 1 : 0),
            itemBuilder: (_, idx) {
              if (idx == gym.chatMessages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: AppTheme.neonBorder,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryCrimson),
                        ),
                        SizedBox(width: 10),
                        Text('Escribiendo...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              final msg = gym.chatMessages[idx];
              return Align(
                alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: msg.isUser ? AppTheme.primaryCrimson : AppTheme.cardDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(msg.isUser ? 14 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 14),
                    ),
                    border: msg.isUser ? null : AppTheme.neonBorder,
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
                  ),
                ),
              );
            },
          ),
        ),

        // Input inferior limpio
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu consulta...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  onPressed: gym.loadingChat ? null : () => _send(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
