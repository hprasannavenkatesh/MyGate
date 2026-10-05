// lib/screens/register_vehicle_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _makeModelController = TextEditingController();
  int _selectedType = 0; 
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final flatId = await AuthService.getFlatId();

      final isSuccess = await VehicleService.registerVehicle({
        'societyId': societyId,
        'flatId': flatId,
        'vehicleNumber': _vehicleNumberController.text.trim().toUpperCase(),
        'vehicleType': _selectedType,
        'makeModel': _makeModelController.text.trim(),
      });

      if (isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Vehicle Registered!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); 
        }
      } else {
        _showError('Failed to register vehicle.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _makeModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Vehicle'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('2-Wheeler (Bike/Scooter)')),
                      DropdownMenuItem(value: 1, child: Text('4-Wheeler (Car)')),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'e.g., KA-01-M-1234',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _makeModelController,
                decoration: const InputDecoration(
                  labelText: 'Make & Model (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                  hintText: 'e.g., Honda City',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register Vehicle', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}