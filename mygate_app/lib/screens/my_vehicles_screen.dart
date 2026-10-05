// lib/screens/my_vehicles_screen.dart
import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import 'register_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      final vehicles = await VehicleService.getMyVehicles();
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterVehicleScreen()));
          if (result == true) _fetchVehicles(); 
        },
        icon: const Icon(Icons.add), // CORRECT SYNTAX
        label: const Text('Add Vehicle'), // CORRECT SYNTAX
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text('No vehicles registered.', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final v = _vehicles[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(v['vehicleType'] == 0 ? Icons.two_wheeler : Icons.directions_car, size: 40, color: Colors.blue.shade700),
                        title: Text(v['vehicleNumber'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(v['makeModel'] ?? 'N/A'),
                      ),
                    );
                  },
                ),
    );
  }
}