import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/group_chat_repository.dart';

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'Coding';
  bool _isPublic = true;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Tech',
    'Coding',
    'AI & ML',
    'Gaming',
    'Music',
    'Sports',
    'Events',
    'Entrepreneurship',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitGroup() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final groupId = await ref.read(groupChatRepositoryProvider).createGroup(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            category: _selectedCategory,
            isPublic: _isPublic,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Community "${_nameController.text.trim()}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/group_chat/$groupId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("We couldn't create the community. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final inputFill = AppTheme.inputFillColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + safeBottom + 100),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                'Create Community Group',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                    fontFamily: 'Outfit'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Build a community space for like-minded students on campus to connect and bond.',
                style: TextStyle(
                    fontSize: 13, color: secondaryText, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Group Name
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Community Name *',
                  labelStyle: TextStyle(color: secondaryText),
                  hintText: 'e.g. MLRIT AI Developers',
                  hintStyle:
                      TextStyle(color: secondaryText.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryOrange, width: 1.5)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a community name';
                  }
                  if (val.trim().length > 40) {
                    return 'Name must be 40 characters or fewer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: TextStyle(color: primaryText, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: secondaryText),
                  hintText: 'What is this community about?',
                  hintStyle:
                      TextStyle(color: secondaryText.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryOrange, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),

              // Category Chips Selection
              Text('Select Interest Category',
                  style: TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: AppTheme.primaryOrange,
                    backgroundColor: inputFill,
                    labelStyle: TextStyle(
                        color: isSel ? Colors.white : secondaryText,
                        fontWeight:
                            isSel ? FontWeight.bold : FontWeight.normal),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Public / Private Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.primaryOrange,
                title: Text('Public Community',
                    style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                subtitle: Text(
                  _isPublic
                      ? 'Anyone on campus can discover and join.'
                      : 'Invite only.',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
                value: _isPublic,
                onChanged: (val) => setState(() => _isPublic = val),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Community Now',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
