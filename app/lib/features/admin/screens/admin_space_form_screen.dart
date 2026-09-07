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
    _descController =
        TextEditingController(text: widget.initialData?['description']);
    _coverUrlController =
        TextEditingController(text: widget.initialData?['coverImageUrl']);
    _iconUrlController =
        TextEditingController(text: widget.initialData?['iconUrl']);
    _selectedTechnologyId = widget.initialData?['technologyId'];

    _loadTechnologies();
  }

  Future<void> _loadTechnologies() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('technologies').get();
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a technology')));
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
        await FirebaseFirestore.instance
            .collection('spaces')
            .doc(widget.spaceId)
            .update(data);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("We couldn't save this space. Please try again.")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[500], fontFamily: 'Inter'),
      filled: true,
      fillColor: const Color(0xFF13131C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF5A1F)),
      ),
    );
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
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Inter'),
                      decoration: _buildInputDecoration('Space Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Inter'),
                      decoration: _buildInputDecoration('Description'),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _buildInputDecoration('Technology'),
                      dropdownColor: const Color(0xFF1C1C28),
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Inter'),
                      initialValue: _selectedTechnologyId,
                      items: _technologies.map((tech) {
                        return DropdownMenuItem<String>(
                          value: tech['id'],
                          child: Text(tech['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedTechnologyId = val),
                      hint: Text('Select a technology',
                          style: TextStyle(
                              color: Colors.grey[600], fontFamily: 'Inter')),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _iconUrlController,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Inter'),
                      decoration: _buildInputDecoration('Icon URL'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coverUrlController,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Inter'),
                      decoration: _buildInputDecoration('Cover Image URL'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFFF5A1F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        widget.spaceId == null
                            ? 'CREATE SPACE'
                            : 'SAVE CHANGES',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
