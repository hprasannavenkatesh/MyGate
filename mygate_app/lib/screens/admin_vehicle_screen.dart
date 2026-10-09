// lib/screens/admin_vehicle_screen.dart
import 'package:flutter/material.dart';
import '../../services/vehicle_service.dart';
import '../../services/auth_service.dart';

class AdminVehicleScreen extends StatefulWidget {
  const AdminVehicleScreen({super.key});

  @override
  State<AdminVehicleScreen> createState() => _AdminVehicleScreenState();
}

class _AdminVehicleScreenState extends State<AdminVehicleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Vehicles State ---
  List<dynamic> _vehicles = [];
  bool _isLoadingVehicles = true;

  // --- Parking Slots State ---
  List<dynamic> _parkingSlots = [];
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchVehicles();
    _fetchParkingSlots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // VEHICLES LOGIC
  // ==========================================
  Future<void> _fetchVehicles() async {
    setState(() => _isLoadingVehicles = true);
    try {
      final data = await VehicleService.getSocietyVehicles();
      if (mounted) setState(() => _vehicles = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  // ==========================================
  // PARKING SLOTS LOGIC
  // ==========================================
  Future<void> _fetchParkingSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final data = await VehicleService.getSocietyParkingSlots();
      if (mounted) setState(() => _parkingSlots = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _showAssignSlotDialog(String slotId) async {
    final vehicleIdController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Vehicle to Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste the Vehicle ID you want to park here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: vehicleIdController, 
              decoration: const InputDecoration(labelText: 'Vehicle ID (GUID) *', border: OutlineInputBorder())
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (vehicleIdController.text.isEmpty) return;
              
              final societyId = await AuthService.getSocietyId();
              final success = await VehicleService.assignParkingSlot(
                slotId: slotId, 
                vehicleId: vehicleIdController.text.trim(), 
                societyId: societyId
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (success) {
                _fetchParkingSlots();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Vehicle Parked!'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _unassignSlot(String slotId) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Vehicle?'),
        content: const Text('Are you sure you want to unassign the vehicle from this slot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Remove')),
        ],
      ),
    );

    if (confirm == true) {
      final societyId = await AuthService.getSocietyId();
      final success = await VehicleService.unassignParkingSlot(slotId: slotId, societyId: societyId);
      if (success && mounted) {
        _fetchParkingSlots();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot Unassigned'), backgroundColor: Colors.orange));
      }
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle & Parking Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),
            Tab(icon: Icon(Icons.local_parking), text: 'Parking Slots'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: VEHICLES LIST
          _isLoadingVehicles
              ? const Center(child: CircularProgressIndicator())
              : _vehicles.isEmpty
                  ? const Center(child: Text('No vehicles registered in this society.'))
                  : ListView.builder(
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final v = _vehicles[index];
                        final hasSlot = v['parkingSlotId'] != null;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              v['vehicleType'] == 0 ? Icons.two_wheeler : Icons.directions_car, 
                              size: 36, 
                              color: hasSlot ? Colors.green : Colors.grey
                            ),
                            title: Text(v['vehicleNumber'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${v['makeModel'] ?? 'N/A'}\nSlot: ${hasSlot ? v['parkingSlotId'].toString().substring(0, 8) + '...' : 'Unassigned'}'),
                            isThreeLine: true,
                            trailing: Chip(
                              label: Text(hasSlot ? 'Parked' : 'Active', style: const TextStyle(fontSize: 11)),
                              backgroundColor: hasSlot ? Colors.green.shade100 : Colors.blue.shade100,
                            ),
                          ),
                        );
                      },
                    ),

          // TAB 2: 2D PARKING SLOT VISUALIZER
          _isLoadingSlots
              ? const Center(child: CircularProgressIndicator())
              : _parkingSlots.isEmpty
                  ? const Center(child: Text('No parking slots configured.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _parkingSlots.length,
                      itemBuilder: (context, index) {
                        final s = _parkingSlots[index];
                        final isOccupied = s['isOccupied'] == true;

                        return Card(
                          color: isOccupied ? Colors.red.shade50 : Colors.green.shade50,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: isOccupied ? Colors.red : Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: InkWell(
                            onTap: () {
                              if (isOccupied) {
                                _unassignSlot(s['id']);
                              } else {
                                _showAssignSlotDialog(s['id']);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isOccupied ? Icons.block : Icons.local_parking,
                                    color: isOccupied ? Colors.red : Colors.green,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s['slotNumber'] ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isOccupied ? 'Occupied' : 'Available',
                                    style: TextStyle(fontSize: 10, color: isOccupied ? Colors.red : Colors.green),
                                  ),
                                  if (isOccupied && s['parkedVehicle'] != null)
                                    Text(
                                      (s['parkedVehicle']['vehicleNumber'] ?? '').substring(0, 4),
                                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                                    )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}