import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../providers/settings_provider.dart';
import '../providers/model_provider.dart';
import '../../domain/entities/model_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _promptController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSystemPromptChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(settingsProvider.notifier).setSystemPrompt(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final modelState = ref.watch(modelStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      body: settings.when(
        data: (s) {
          if (_promptController.text != s.systemPrompt) {
            _promptController.text = s.systemPrompt;
          }
          return ScrollConfiguration(
            behavior: _GlowScrollBehavior(),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
              _SectionHeader(title: 'AI Model'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.model_training_rounded),
                      title: const Text('Model File'),
                      subtitle: Text(s.modelPath.isEmpty ? 'Not selected' : s.modelPath.split('/').last),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            modelState.status == ModelStatus.ready
                                ? Icons.check_circle_rounded
                                : modelState.status == ModelStatus.error
                                    ? Icons.error_rounded
                                    : modelState.status == ModelStatus.generating
                                        ? Icons.auto_awesome_rounded
                                        : Icons.hourglass_empty_rounded,
                            size: 16,
                            color: _getStatusColor(modelState.status, theme.colorScheme),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(modelState.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(modelState.status, theme.colorScheme),
                            ),
                          ),
                          const Spacer(),
                          if (modelState.status == ModelStatus.generating)
                            TextButton.icon(
                              onPressed: () => _cancelGeneration(ref),
                              icon: const Icon(Icons.stop_rounded, size: 16),
                              label: const Text('Stop'),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async { 
                                await _pickModelFile(context, ref); 
                              },
                              icon: const Icon(Icons.folder_open_rounded),
                              label: const Text('Select Model'),
                            ),
                          ),
                          if (s.modelPath.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: modelState.status == ModelStatus.loading || modelState.status == ModelStatus.generating
                                    ? null
                                    : () async {
                                        final init = ref.read(initializeModelProvider);
                                        await init();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Model reloaded')),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reload Model'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              _SectionHeader(title: 'System Prompt'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promptController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter system prompt...',
                              ),
                              maxLines: 4,
                              onChanged: _onSystemPromptChanged,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded),
                            tooltip: 'System Prompt: Defines the AI\'s personality and behavior. This sets the initial context for all conversations.',
                            onPressed: () => _showInfoDialog(
                              'System Prompt',
                              'System Prompt defines the AI\'s personality and behavior. It sets the initial context and instructions for all conversations.\n\nDefault: "You are a helpful AI assistant."',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              _SectionHeader(
                title: 'Generation Settings',
                trailing: TextButton.icon(
                  onPressed: () => ref.read(settingsProvider.notifier).resetGenerationSettings(),
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Reset'),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Temperature'),
                          Text('${s.temperature.toStringAsFixed(1)}'),
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 20),
                            tooltip: 'Controls randomness. Lower = more focused, Higher = more creative.',
                            onPressed: () => _showInfoDialog(
                              'Temperature',
                              'Controls randomness in generation.\n\n• Low (0.1-0.4): Focused, deterministic responses\n• Medium (0.5-0.8): Balanced\n• High (0.9-2.0): Creative, varied responses\n\nRecommended: 0.5-0.7 for general use.',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.temperature,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        onChanged: (v) => ref.read(settingsProvider.notifier).setTemperature(v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Max Tokens'),
                          Text('${s.maxTokens}'),
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 20),
                            tooltip: 'Maximum length of the AI response.',
                            onPressed: () => _showInfoDialog(
                              'Max Tokens',
                              'Maximum number of tokens (words/word parts) the AI can generate in a single response.\n\n• Higher = longer responses, more memory\n• Lower = shorter responses\n\nRecommended: 256-512 for chat.',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.maxTokens.toDouble(),
                        min: 64,
                        max: 4096,
                        divisions: 63,
                        onChanged: (v) => ref.read(settingsProvider.notifier).setMaxTokens(v.toInt()),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Repeat Penalty'),
                          Text('${s.repeatPenalty.toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 20),
                            tooltip: 'Penalizes repetitive tokens.',
                            onPressed: () => _showInfoDialog(
                              'Repeat Penalty',
                              'Penalizes the model for repeating the same tokens.\n\n• 1.0: No penalty\n• 1.1-1.2: Light penalty\n• 1.5+: Strong penalty\n\nRecommended: 1.1-1.2 to prevent repetition.',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.repeatPenalty,
                        min: 1.0,
                        max: 2.0,
                        divisions: 20,
                        onChanged: (v) => ref.read(settingsProvider.notifier).setRepeatPenalty(v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Context Window'),
                          Text('${s.contextWindow}'),
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 20),
                            tooltip: 'Number of previous tokens to consider.',
                            onPressed: () => _showInfoDialog(
                              'Context Window',
                              'Number of previous tokens the model considers when generating a response.\n\n• Higher = more context, more memory usage\n• Lower = less memory, less conversation history\n\nNote: Must be within model\'s supported context size.',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.contextWindow.toDouble(),
                        min: 512,
                        max: 8192,
                        divisions: 15,
                        onChanged: (v) => ref.read(settingsProvider.notifier).setContextWindow(v.toInt()),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Top P'),
                          Text('${s.topP.toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 20),
                            tooltip: 'Nucleus sampling threshold.',
                            onPressed: () => _showInfoDialog(
                              'Top P (Nucleus Sampling)',
                              'Controls vocabulary selection based on cumulative probability.\n\n• Lower (0.1-0.5): Only most probable tokens\n• Higher (0.7-1.0): More diverse vocabulary\n\nRecommended: 0.8-0.95.\n\nNote: Use either Top P or Top K, not both.',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.topP,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (v) => ref.read(settingsProvider.notifier).setTopP(v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Top K'),
                          Text('${s.topK}'),
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 20),
                            tooltip: 'Number of top tokens to consider.',
                            onPressed: () => _showInfoDialog(
                              'Top K',
                              'Limits vocabulary to the top K most probable tokens.\n\n• Lower (1-10): Very focused\n• Medium (20-40): Balanced\n• Higher (50-100): More diverse\n\nRecommended: 20-40.\n\nNote: Use either Top K or Top P, not both.',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.topK.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        onChanged: (v) => ref.read(settingsProvider.notifier).setTopK(v.toInt()),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Repeat Last N'),
                          Text('${s.repeatLastN}'),
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 20),
                            tooltip: 'Number of recent tokens to check for repetition.',
                            onPressed: () => _showInfoDialog(
                              'Repeat Last N',
                              'Number of recent tokens to consider when applying repeat penalty.\n\n• Lower: Only checks recent tokens\n• Higher: Checks more context\n\nRecommended: 32-64 for conversation.',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.repeatLastN.toDouble(),
                        min: 0,
                        max: 128,
                        divisions: 128,
                        onChanged: (v) => ref.read(settingsProvider.notifier).setRepeatLastN(v.toInt()),
                      ),
                    ],
                  ),
                ),
              ),
              
              _SectionHeader(title: 'Appearance'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.palette_rounded),
                  title: const Text('Theme'),
                  trailing: DropdownButton<String>(
                    value: s.theme,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (v) {
                      if (v != null) ref.read(settingsProvider.notifier).setTheme(v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _getStatusText(ModelStatus status) {
    switch (status) {
      case ModelStatus.idle:
        return 'Not loaded';
      case ModelStatus.loading:
        return 'Loading model...';
      case ModelStatus.ready:
        return 'Ready';
      case ModelStatus.generating:
        return 'Generating...';
      case ModelStatus.error:
        return 'Error';
    }
  }

  Color _getStatusColor(ModelStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ModelStatus.idle:
        return colorScheme.outline;
      case ModelStatus.loading:
        return colorScheme.tertiary;
      case ModelStatus.ready:
        return colorScheme.primary;
      case ModelStatus.generating:
        return colorScheme.secondary;
      case ModelStatus.error:
        return colorScheme.error;
    }
  }

  Future<void> _pickModelFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null && file.path!.isNotEmpty) {
          await ref.read(settingsProvider.notifier).setModelPath(file.path!);
          
          final init = ref.read(initializeModelProvider);
          await init();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Model loaded: ${file.name}')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking model file: $e');
    }
  }

  Future<void> _cancelGeneration(WidgetRef ref) async {
    final service = ref.read(llamaServiceProvider);
    await service.stop();
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _GlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}
