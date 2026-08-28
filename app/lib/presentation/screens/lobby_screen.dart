import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../theme/durak_colors.dart';
import '../widgets/felt_background.dart';
import '../widgets/gold_button.dart';
import '../widgets/suit_icon.dart';
import '../../domain/entities/card.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _nameController = TextEditingController(text: 'Игрок');
  final _roomCodeController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: DurakColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: DurakColors.goldCore.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DurakColors.goldCore, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(gameControllerProvider.notifier);
    final errorMessage = ref.watch(gameControllerProvider.select((s) => s.errorMessage));
    final displayError = _localError ?? errorMessage;

    return Scaffold(
      backgroundColor: DurakColors.feltShadow,
      body: FeltBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SuitIcon(suit: Suit.spades, color: DurakColors.goldCore, size: 22),
                        const SizedBox(width: 12),
                        const Text(
                          'Дурак',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: DurakColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SuitIcon(suit: Suit.hearts, color: DurakColors.goldCore, size: 22),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: DurakColors.textPrimary),
                      decoration: _inputDecoration('Ваше имя'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: GoldPillButton(
                        label: _isCreating ? 'Создаём...' : 'Создать комнату',
                        onPressed: _isCreating
                            ? null
                            : () async {
                                setState(() => _isCreating = true);
                                try {
                                  await controller.createRoom(_nameController.text.trim());
                                } finally {
                                  if (mounted) setState(() => _isCreating = false);
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('или', style: TextStyle(color: Colors.white54))),
                      Expanded(child: Divider(color: Colors.white24)),
                    ]),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _roomCodeController,
                      style: const TextStyle(color: DurakColors.textPrimary),
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration('Код комнаты'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: GoldOutlinedButton(
                        label: 'Войти в комнату',
                        onPressed: _isJoining
                            ? null
                            : () {
                                final code = _roomCodeController.text.trim().toUpperCase();
                                if (code.isEmpty) {
                                  setState(() => _localError = 'Введите код комнаты');
                                  return;
                                }
                                setState(() {
                                  _localError = null;
                                  _isJoining = true;
                                });
                                controller.joinRoom(code, _nameController.text.trim());
                              },
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedOpacity(
                        opacity: displayError != null ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: displayError == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: DurakColors.alertAmber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: DurakColors.alertAmber.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline, size: 16, color: DurakColors.alertAmber),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(displayError, style: const TextStyle(color: DurakColors.alertAmber))),
                                  ]),
                                ),
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
    );
  }
}
