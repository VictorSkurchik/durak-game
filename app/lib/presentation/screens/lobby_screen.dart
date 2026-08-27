import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _nameController = TextEditingController(text: 'Игрок');
  final _roomCodeController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(gameControllerProvider.notifier);
    final errorMessage = ref.watch(gameControllerProvider.select((s) => s.errorMessage));

    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Дурак', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Ваше имя', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
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
                    child: Text(_isCreating ? 'Создаём...' : 'Создать комнату'),
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
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration:
                      const InputDecoration(labelText: 'Код комнаты', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    onPressed: () {
                      final code = _roomCodeController.text.trim().toUpperCase();
                      if (code.isEmpty) return;
                      controller.joinRoom(code, _nameController.text.trim());
                    },
                    child: const Text('Войти в комнату'),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(errorMessage, style: const TextStyle(color: Colors.orangeAccent)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
