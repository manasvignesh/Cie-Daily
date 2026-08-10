import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSpaceFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? spaceId;

  const AdminSpaceFormScreen({super.key, this.initialData, this.spaceId});

  @override
  State<AdminSpaceFormScreen> createState() => _AdminSpaceFormScreenState();
}

class _AdminSpaceFormScreenState extends State<AdminSpaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _coverUrlController;
  late TextEditingController _iconUrlController;
  String? _selectedTechnologyId;

  List<Map<String, dynamic>> _technologies = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name']);
    _descController = TextEditingController(text: widget.initialData?['description']);
    _coverUrlController = TextEditingController(text: widget.initialData?['coverImageUrl']);
    _iconUrlController = TextEditingController(text: widget.initialData?['iconUrl']);
    _selectedTechnologyId = widget.initialData?['technologyId'];

    _loadTechnologies();
  }

  Future<void> _loadTechnologies() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('technologies').get();
      setState(() {
        _technologies = snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Failed to load technologies: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _coverUrlController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTechnologyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a technology')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'coverImageUrl': _coverUrlController.text.trim(),
        'iconUrl': _iconUrlController.text.trim(),
        'technologyId': _selectedTechnologyId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.spaceId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['memberCount'] = 0;
        data['moderatorIds'] = [];
        await FirebaseFirestore.instance.collection('spaces').add(data);
      } else {
        await FirebaseFirestore.instance.collection('spaces').doc(widget.spaceId).update(data);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving space: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spaceId == null ? 'Create Space' : 'Edit Space'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Space Name', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Technology', border: OutlineInputBorder()),
                      value: _selectedTechnologyId,
                      items: _technologies.map((tech) {
                        return DropdownMenuItem<String>(
                          value: tech['id'],
                          child: Text(tech['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTechnologyId = val),
                      hint: const Text('Select a technology'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _iconUrlController,
                      decoration: const InputDecoration(labelText: 'Icon URL', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coverUrlController,
                      decoration: const InputDecoration(labelText: 'Cover Image URL', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _submit,
                      child: Text(widget.spaceId == null ? 'CREATE SPACE' : 'SAVE CHANGES'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
