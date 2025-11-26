import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBoardGameScreen extends StatefulWidget {
  // Can optionally receive a board game document to edit
  final DocumentSnapshot? boardGame;

  const AddBoardGameScreen({super.key, this.boardGame});

  @override
  State<AddBoardGameScreen> createState() => _AddBoardGameScreenState();
}

class _AddBoardGameScreenState extends State<AddBoardGameScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get _isEditing => widget.boardGame != null;

  final _nameController = TextEditingController();
  final _totalUnitsController = TextEditingController();
  final _availableUnitsController = TextEditingController(); // New controller
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If we are editing, pre-fill the form fields with the existing data
    if (_isEditing) {
      final data = widget.boardGame!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _totalUnitsController.text = (data['totalUnits'] ?? 0).toString();
      _availableUnitsController.text = (data['availableUnits'] ?? 0).toString();
      _imageUrlController.text = data['imageUrl'] ?? '';
    }
  }

  Future<void> _saveItem() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final totalUnits = int.parse(_totalUnitsController.text.trim());
    final availableUnits = int.parse(_availableUnitsController.text.trim());

    // Prepare the data map
    final gameData = {
      'name': _nameController.text.trim(),
      'totalUnits': totalUnits,
      'availableUnits': availableUnits,
      'imageUrl': _imageUrlController.text.trim(),
    };

    try {
      if (_isEditing) {
        // If editing, update the existing document
        await widget.boardGame!.reference.update(gameData);
      } else {
        // If not editing, add a new document
        await FirebaseFirestore.instance.collection('board_games').add(gameData);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save game. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalUnitsController.dispose();
    _availableUnitsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Board Game' : 'Add New Board Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // Makes the form scrollable
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Game Name'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Please enter a valid name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalUnitsController,
                  decoration: const InputDecoration(labelText: 'Total Units'),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Please enter a valid, non-negative number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Only show available units field when editing
                if (_isEditing)
                  TextFormField(
                    controller: _availableUnitsController,
                    decoration: const InputDecoration(labelText: 'Available Units'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Please enter a valid, non-negative number.';
                      }
                      if (int.parse(value) > int.parse(_totalUnitsController.text)) {
                        return 'Cannot be more than total units.';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an image URL.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(_isEditing ? 'Save Changes' : 'Save Game'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
