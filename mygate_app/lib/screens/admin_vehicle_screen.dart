import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../services/auth_service.dart';
import '../services/tenant_admin_service.dart';

class AdminVehicleScreen extends StatefulWidget {
  const AdminVehicleScreen({super.key});

  @override
  State<AdminVehicleScreen> createState() => _AdminVehicleScreenState();
}

class _AdminVehicleScreenState extends State<AdminVehicleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _vehicles = [];
  List<dynamic> _slots = [];
  List<dynamic> _blocks = [];
  bool _isLoadingVehicles = true;
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // FETCH DATA
  // ==========================================
  Future<void> _fetchInitialData() async {
    await _fetchBlocks();
    _fetchVehicles();
    _fetchSlots();
  }

  Future<void> _fetchBlocks() async {
    try {
      final societyId = await AuthService.getSocietyId();
      final data = await TenantAdminService.getBlocks(societyId);
      if (mounted) setState(() => _blocks = data);
    } catch (e) {
      debugPrint('Error fetching blocks: $e');
    }
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoadingVehicles = true);
    try {
      final data = await VehicleService.getSocietyVehicles();
      if (mounted) setState(() => _vehicles = data);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final data = await VehicleService.getSocietyParkingSlots();
      if (mounted) setState(() => _slots = data);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  // FIX: Helper to resolve Block Guid to Name
  String _getBlockName(String? blockId) {
    if (blockId == null || blockId.isEmpty || blockId == '00000000-0000-0000-0000-000000000000') return '';
    final block = _blocks.firstWhere(
      (b) => b['id'].toString() == blockId.toString(),
      orElse: () => null,
    );
    return block != null ? 'Block ${block['name']}' : '';
  }

  // FIX: Helper to treat Empty GUIDs as null for safe comparison
  String? _safeId(dynamic id) {
    if (id == null) return null;
    final str = id.toString();
    if (str.isEmpty || str == '00000000-0000-0000-0000-000000000000') return null;
    return str;
  }
    // Helper to get Flat Number from ID using block fetch
  Future<String> _getFlatNumber(String blockId, String flatId) async {
    try {
      final flats = await TenantAdminService.getFlats(blockId);
      final flat = flats.firstWhere(
        (f) => f['id'].toString() == flatId,
        orElse: () => null,
      );
      return flat != null ? flat['flatNumber'].toString() : '';
    } catch (e) {
      return '';
    }
  }

  // Helper to resolve flat info reliably
  Future<String> _resolveFlatInfo(Map<String, dynamic> vehicle) async {
    final String? vBlockId = _safeId(vehicle['blockId']);
    final String? vFlatId = _safeId(vehicle['flatId']);

    // Strategy 1: If vehicle has blockId and flatId, fetch directly
    if (vBlockId != null && vFlatId != null) {
      final blockName = _getBlockName(vBlockId);
      final flatNum = await _getFlatNumber(vBlockId, vFlatId);
      if (flatNum.isNotEmpty) {
        return blockName.isEmpty ? 'Flat $flatNum' : '$blockName - $flatNum';
      }
    }

    // Strategy 2: Fallback - Reverse lookup from cached Slots list
    if (vFlatId != null) {
      for (var slot in _slots) {
        if (_safeId(slot['flatId']) == vFlatId) {
          final sBlockName = slot['blockName']?.toString() ?? _getBlockName(slot['blockId']?.toString());
          // Try to find flat number from slot's blockId
          if (_safeId(slot['blockId']) != null) {
             final flatNum = await _getFlatNumber(slot['blockId'].toString(), vFlatId);
             if (flatNum.isNotEmpty) {
               return sBlockName.isEmpty ? 'Flat $flatNum' : '$sBlockName - $flatNum';
             }
          }
          return sBlockName.isEmpty ? 'Flat ID: ${vFlatId.substring(0,8)}...' : '$sBlockName - ${vFlatId.substring(0,8)}...';
        }
      }
    }

    // Strategy 3: Ultimate Fallback
    return vFlatId != null ? 'Flat ID: ${vFlatId.substring(0,8)}...' : 'No Flat Info';
  }

  // ==========================================
  // VEHICLE DIALOGS
  // ==========================================
  Future<void> _showRegisterVehicleDialog() async {
    final numberController = TextEditingController();
    final makeModelController = TextEditingController();
    int selectedType = 0;
    String? selectedBlockId;
    String? selectedFlatId;

    List<dynamic> blocks = _blocks;
    List<dynamic> flats = [];
    bool isLoadingFlats = false;

    if (blocks.isEmpty) {
      await _fetchBlocks();
      blocks = _blocks;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Register Vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('2-Wheeler')),
                    DropdownMenuItem(value: 1, child: Text('4-Wheeler'))
                  ],
                  decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Number *', border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: makeModelController,
                  decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                ),
                const Divider(height: 30),
                const Text('Allocate to Flat', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedBlockId,
                  hint: const Text('Block *'),
                  items: blocks.map((b) => DropdownMenuItem<String>(
                    value: b['id'].toString(),
                    child: Text('Block ${b['name']}')
                  )).toList(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (val) async {
                    setDialogState(() {
                      selectedBlockId = val;
                      selectedFlatId = null;
                      isLoadingFlats = true;
                    });
                    try {
                      final f = await TenantAdminService.getFlats(val!);
                      setDialogState(() { flats = f; isLoadingFlats = false; });
                    } catch (e) {
                      setDialogState(() => isLoadingFlats = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (isLoadingFlats)
                  const Center(child: CircularProgressIndicator())
                else if (selectedBlockId != null)
                  DropdownButtonFormField<String>(
                    value: selectedFlatId,
                    hint: const Text('Flat *'),
                    items: flats.map((f) => DropdownMenuItem<String>(
                      value: f['id'].toString(),
                      child: Text('Flat ${f['flatNumber']}')
                    )).toList(),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    onChanged: (val) => setDialogState(() => selectedFlatId = val),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (numberController.text.trim().isEmpty || selectedFlatId == null) return;
                final societyId = await AuthService.getSocietyId();
                final userId = await AuthService.getUserId();
                
                try {
                  final success = await VehicleService.registerVehicle({
                    'societyId': societyId,
                    'flatId': selectedFlatId!,
                    'ownerId': userId,
                    'vehicleNumber': numberController.text.trim().toUpperCase(),
                    'vehicleType': selectedType,
                    'makeModel': makeModelController.text.trim().isEmpty ? null : makeModelController.text.trim(),
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success) {
                    _fetchVehicles();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vehicle Registered!'), backgroundColor: Colors.green),
                      );
                    }
                  }
                } catch (e) {
                  String errorMessage = e.toString().replaceAll('Exception: ', '');
                  if (errorMessage.contains('Validation failed:')) {
                    errorMessage = errorMessage.split('Validation failed:').last.trim();
                  }
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
/*
  Future<void> _showAssignSlotDialog(Map<String, dynamic> vehicle) async {
    final vehicleId = vehicle['id'].toString();
    final vehicleType = vehicle['vehicleType'] is int ? vehicle['vehicleType'] : 0;
    final vehicleFlatId = _safeId(vehicle['flatId']); 
    final vehicleNumber = vehicle['vehicleNumber'] ?? 'Vehicle';

    // FIX: Safe ID comparison
    final availableSlots = _slots.where((s) {
      bool isOccupied = (s['isOccupied'] == true || s['isOccupied'] == 'true');
      bool belongsToFlat = _safeId(s['flatId']) == vehicleFlatId;
      int slotType = s['slotType'] is int ? s['slotType'] : 0;
      return !isOccupied && belongsToFlat && slotType == vehicleType;
    }).toList();

    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available slots for this flat/vehicle type. Please create slots first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedSlotId;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Slot to $vehicleNumber'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available ${vehicleType == 0 ? '2-Wheeler' : '4-Wheeler'} slots for this flat.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSlotId,
                hint: const Text('Select Slot *'),
                items: availableSlots.map((s) {
                  final bName = s['blockName']?.toString() ?? _getBlockName(s['blockId']?.toString());
                  return DropdownMenuItem<String>(
                    value: s['id'].toString(),
                    child: Text('${bName.isNotEmpty ? bName : "Block"} - ${s['slotNumber']}'),
                  );
                }).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (val) => setDialogState(() => selectedSlotId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedSlotId == null) return;
                final societyId = await AuthService.getSocietyId();
                final success = await VehicleService.assignParkingSlot(
                  slotId: selectedSlotId!,
                  vehicleId: vehicleId,
                  societyId: societyId,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (success) {
                  _fetchSlots();
                  _fetchVehicles();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Slot Assigned!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }*/
    Future<void> _showAssignSlotDialog(Map<String, dynamic> vehicle) async {
    final vehicleId = vehicle['id'].toString();
    final vehicleType = vehicle['vehicleType'] is int ? vehicle['vehicleType'] : 0;
    final vehicleFlatId = _safeId(vehicle['flatId']); 
    final vehicleNumber = vehicle['vehicleNumber'] ?? 'Vehicle';

    // STEP 1: Try to find slots that EXACTLY match the Vehicle's FlatId
    var availableSlots = _slots.where((s) {
      bool isOccupied = (s['isOccupied'] == true || s['isOccupied'] == 'true');
      bool belongsToFlat = _safeId(s['flatId']) == vehicleFlatId;
      int slotType = s['slotType'] is int ? s['slotType'] : 0;
      return !isOccupied && belongsToFlat && slotType == vehicleType;
    }).toList();

    // STEP 2: If no exact match found, fall back to ANY available slot of the correct Type in the society
    // (This handles cases where auto-generate created slots with different ID formats or un-allotted slots)
    if (availableSlots.isEmpty) {
      availableSlots = _slots.where((s) {
        bool isOccupied = (s['isOccupied'] == true || s['isOccupied'] == 'true');
        int slotType = s['slotType'] is int ? s['slotType'] : 0;
        return !isOccupied && slotType == vehicleType;
      }).toList();
    }

    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available slots for this vehicle type. Please create slots first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedSlotId;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Slot to $vehicleNumber'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available ${vehicleType == 0 ? '2-Wheeler' : '4-Wheeler'} slots.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSlotId,
                hint: const Text('Select Slot *'),
                items: availableSlots.map((s) {
                  final bName = s['blockName']?.toString() ?? _getBlockName(s['blockId']?.toString());
                  return DropdownMenuItem<String>(
                    value: s['id'].toString(),
                    child: Text('${bName.isNotEmpty ? bName : "Block"} - ${s['slotNumber']}'),
                  );
                }).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (val) => setDialogState(() => selectedSlotId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedSlotId == null) return;
                final societyId = await AuthService.getSocietyId();
                final success = await VehicleService.assignParkingSlot(
                  slotId: selectedSlotId!,
                  vehicleId: vehicleId,
                  societyId: societyId,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (success) {
                  _fetchSlots();
                  _fetchVehicles();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Slot Assigned!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SLOT DIALOGS (Create & Edit)
  // ==========================================
  Future<void> _showCreateSlotDialog({Map<String, dynamic>? existingSlot}) async {
    final isEdit = existingSlot != null;
    final slotNumberController = TextEditingController(text: isEdit ? existingSlot!['slotNumber'] : '');
    int selectedType = isEdit ? (existingSlot!['slotType'] is int ? existingSlot!['slotType'] : 1) : 0;
    String? selectedBlockId = isEdit ? _safeId(existingSlot!['blockId']) : null;
    String? selectedFlatId = isEdit ? _safeId(existingSlot!['flatId']) : null;
    String? selectedBlockName = isEdit ? existingSlot!['blockName']?.toString() : null;

    List<dynamic> blocks = _blocks;
    List<dynamic> flats = [];
    bool isLoadingFlats = false;

    // If editing, pre-fetch flats for the block
    if (isEdit && selectedBlockId != null) {
      try {
        flats = await TenantAdminService.getFlats(selectedBlockId!);
      } catch (_) {}
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Slot' : 'Create Slot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('2-Wheeler')),
                    DropdownMenuItem(value: 1, child: Text('4-Wheeler'))
                  ],
                  decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: slotNumberController,
                  decoration: const InputDecoration(labelText: 'Slot Number *', border: OutlineInputBorder()),
                ),
                const Divider(height: 20),
                const Text('Allocate to Flat', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedBlockId,
                  hint: const Text('Block *'),
                  items: blocks.map((b) => DropdownMenuItem<String>(
                    value: b['id'].toString(),
                    child: Text('Block ${b['name']}')
                  )).toList(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (val) async {
                    final block = blocks.firstWhere((b) => b['id'].toString() == val);
                    setDialogState(() {
                      selectedBlockId = val;
                      selectedBlockName = block['name'];
                      selectedFlatId = null;
                      isLoadingFlats = true;
                    });
                    try {
                      final f = await TenantAdminService.getFlats(val!);
                      setDialogState(() { flats = f; isLoadingFlats = false; });
                    } catch (e) {
                      setDialogState(() => isLoadingFlats = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (isLoadingFlats)
                  const Center(child: CircularProgressIndicator())
                else if (selectedBlockId != null)
                  DropdownButtonFormField<String>(
                    value: selectedFlatId,
                    hint: const Text('Flat *'),
                    items: flats.map((f) => DropdownMenuItem<String>(
                      value: f['id'].toString(),
                      child: Text('Flat ${f['flatNumber']}')
                    )).toList(),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    onChanged: (val) => setDialogState(() => selectedFlatId = val),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (slotNumberController.text.trim().isEmpty || selectedFlatId == null) return;
                
                if (!isEdit) {
                  // Client-side enforcement of max 3 slots per flat (Only on Create)
                  final existingSlotsForFlat = _slots.where((s) => _safeId(s['flatId']) == selectedFlatId).toList();
                  final existingOfType = existingSlotsForFlat.where((s) => (s['slotType'] is int ? s['slotType'] : 0) == selectedType).toList();
                  int maxLimit = selectedType == 1 ? 1 : 2; // 1 for 4W, 2 for 2W
                  if (existingOfType.length >= maxLimit) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Limit reached! A flat can only have $maxLimit ${selectedType == 1 ? "4-Wheeler" : "2-Wheeler"} slots.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                final societyId = await AuthService.getSocietyId();
                final payload = {
                  if (isEdit) 'id': existingSlot!['id'], // Add ID for update
                  'societyId': societyId,
                  'slotNumber': slotNumberController.text.trim().toUpperCase(),
                  'slotType': selectedType,
                  'blockId': selectedBlockId,
                  'flatId': selectedFlatId,
                  'blockName': selectedBlockName,
                };

                bool success;
                if (isEdit) {
                  success = await VehicleService.updateParkingSlot(payload);
                } else {
                  success = await VehicleService.createParkingSlot(payload);
                }

                if (ctx.mounted) Navigator.pop(ctx);
                if (success) {
                  _fetchSlots();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Slot Updated!' : 'Slot Created!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle & Parking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'Fleet'),
            Tab(icon: Icon(Icons.local_parking), text: 'Parking Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFleetTab(),
          _buildParkingMapTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: FLEET (VEHICLES)
  // ==========================================
  /*
  Widget _buildFleetTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRegisterVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Register New Vehicle'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingVehicles
              ? const Center(child: CircularProgressIndicator())
              : _vehicles.isEmpty
                  ? const Center(child: Text('No vehicles registered.'))
                  : ListView.builder(
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final v = _vehicles[index];
                        final bool hasSlot = v['hasParkingSlot'] == true || v['hasParkingSlot'] == 'true';
                        final String blockName = _getBlockName(v['blockId']?.toString());
                        final String flatNumber = v['flatNumber']?.toString() ?? 'N/A';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  v['vehicleType'] == 0 ? Icons.two_wheeler : Icons.directions_car,
                                  color: Colors.indigo, size: 36,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v['vehicleNumber'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(blockName.isEmpty ? flatNumber : '$blockName - $flatNumber', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (hasSlot) ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Slot: ${v['assignedSlotNumber'] ?? 'N/A'}', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () async {
                                          final occupiedSlot = _slots.firstWhere(
                                            (s) => s['parkedVehicle']?['id']?.toString() == v['id'].toString(),
                                            orElse: () => {},
                                          );
                                          if (occupiedSlot.isNotEmpty) {
                                            final societyId = await AuthService.getSocietyId();
                                            final success = await VehicleService.unassignParkingSlot(
                                              slotId: occupiedSlot['id'].toString(), societyId: societyId,
                                            );
                                            if (success) { _fetchSlots(); _fetchVehicles(); }
                                          }
                                        },
                                        child: const Text('Unassign', style: TextStyle(color: Colors.red, fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Unassigned', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () => _showAssignSlotDialog(v),
                                        child: const Text('Assign Slot', style: TextStyle(color: Colors.indigo, fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }*/
    // ==========================================
  // TAB 1: FLEET (VEHICLES)
  // ==========================================
  /*
  Widget _buildFleetTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRegisterVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Register New Vehicle'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingVehicles
              ? const Center(child: CircularProgressIndicator())
              : _vehicles.isEmpty
                  ? const Center(child: Text('No vehicles registered.'))
                  : ListView.builder(
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final v = _vehicles[index];
                        final bool hasSlot = v['hasParkingSlot'] == true || v['hasParkingSlot'] == 'true';
                        final String blockName = _getBlockName(v['blockId']?.toString());
                        final String flatNumber = v['flatNumber']?.toString() ?? 'N/A';
                        final String? assignedSlotNumber = v['assignedSlotNumber']?.toString();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  v['vehicleType'] == 0 ? Icons.two_wheeler : Icons.directions_car,
                                  color: Colors.indigo, size: 36,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v['vehicleNumber'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(blockName.isEmpty ? flatNumber : '$blockName - $flatNumber', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (hasSlot && assignedSlotNumber != null) ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Slot: $assignedSlotNumber', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () async {
                                          // FIX: Find the slot ID by matching the Slot Number instead of relying on nested ParkedVehicle object
                                          final occupiedSlot = _slots.firstWhere(
                                            (s) => s['slotNumber']?.toString() == assignedSlotNumber,
                                            orElse: () => {},
                                          );
                                          
                                          if (occupiedSlot.isNotEmpty) {
                                            final societyId = await AuthService.getSocietyId();
                                            final success = await VehicleService.unassignParkingSlot(
                                              slotId: occupiedSlot['id'].toString(), 
                                              societyId: societyId,
                                            );
                                            if (success) { 
                                              _fetchSlots(); 
                                              _fetchVehicles(); 
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Error: Could not find slot ID to unassign.'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                        child: const Text('Unassign', style: TextStyle(color: Colors.red, fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Unassigned', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () => _showAssignSlotDialog(v),
                                        child: const Text('Assign Slot', style: TextStyle(color: Colors.indigo, fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }*/
  
  /*
  // ==========================================
  // TAB 1: FLEET (VEHICLES)
  // ==========================================
  Widget _buildFleetTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRegisterVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Register New Vehicle'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingVehicles
              ? const Center(child: CircularProgressIndicator())
              : _vehicles.isEmpty
                  ? const Center(child: Text('No vehicles registered.'))
                  : ListView.builder(
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final v = _vehicles[index];
                        final bool hasSlot = v['hasParkingSlot'] == true || v['hasParkingSlot'] == 'true';
                        final String? assignedSlotNumber = v['assignedSlotNumber']?.toString();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  v['vehicleType'] == 0 ? Icons.two_wheeler : Icons.directions_car,
                                  color: Colors.indigo, size: 36,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v['vehicleNumber'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      FutureBuilder<String>(
                                        future: _resolveFlatInfo(v), // Pass whole vehicle object
                                        builder: (context, snapshot) {
                                          return Text(
                                            snapshot.data ?? 'Loading...',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          );
                                        }
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasSlot && assignedSlotNumber != null) ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Slot: $assignedSlotNumber', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () async {
                                          final occupiedSlot = _slots.firstWhere(
                                            (s) => s['slotNumber']?.toString() == assignedSlotNumber,
                                            orElse: () => {},
                                          );
                                          
                                          if (occupiedSlot.isNotEmpty) {
                                            final societyId = await AuthService.getSocietyId();
                                            final success = await VehicleService.unassignParkingSlot(
                                              slotId: occupiedSlot['id'].toString(), 
                                              societyId: societyId,
                                            );
                                            if (success) { 
                                              _fetchSlots(); 
                                              _fetchVehicles(); 
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Error: Could not find slot ID to unassign.'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                        child: const Text('Unassign', style: TextStyle(color: Colors.red, fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Unassigned', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () => _showAssignSlotDialog(v),
                                        child: const Text('Assign Slot', style: TextStyle(color: Colors.indigo, fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
  */
  // ==========================================
  // TAB 1: FLEET (VEHICLES)
  // ==========================================
  Widget _buildFleetTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRegisterVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Register New Vehicle'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingVehicles
              ? const Center(child: CircularProgressIndicator())
              : _vehicles.isEmpty
                  ? const Center(child: Text('No vehicles registered.'))
                  : ListView.builder(
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final v = _vehicles[index];
                        final bool hasSlot = v['hasParkingSlot'] == true || v['hasParkingSlot'] == 'true';
                        final String? assignedSlotNumber = v['assignedSlotNumber']?.toString();

                        // Read directly from the enriched backend payload
                        final String blockName = v['blockName']?.toString() ?? '';
                        final String flatNumber = v['flatNumber']?.toString() ?? '';
                        final String ownerName = v['ownerName']?.toString() ?? '';
                        final String ownerMobile = v['ownerMobile']?.toString() ?? '';

                        // Format Block - Flat
                        final String locationInfo = [
                          if (blockName.isNotEmpty) 'Block $blockName',
                          if (flatNumber.isNotEmpty) flatNumber,
                        ].join(' - ');

                        // Format Name | Mobile
                        final String userInfo = [
                          if (ownerName.isNotEmpty) ownerName,
                          if (ownerMobile.isNotEmpty) ownerMobile,
                        ].join(' | ');

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  v['vehicleType'] == 0 ? Icons.two_wheeler : Icons.directions_car,
                                  color: Colors.indigo, size: 36,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1. Vehicle Number
                                      Text(v['vehicleNumber'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      
                                      // 2. Block - Flat
                                      if (locationInfo.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(locationInfo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                      
                                      // 3. Name | Mobile
                                      if (userInfo.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(userInfo, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                                      ],
                                    ],
                                  ),
                                ),
                                if (hasSlot && assignedSlotNumber != null) ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Slot: $assignedSlotNumber', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () async {
                                          final occupiedSlot = _slots.firstWhere(
                                            (s) => s['slotNumber']?.toString() == assignedSlotNumber,
                                            orElse: () => {},
                                          );
                                          
                                          if (occupiedSlot.isNotEmpty) {
                                            final societyId = await AuthService.getSocietyId();
                                            final success = await VehicleService.unassignParkingSlot(
                                              slotId: occupiedSlot['id'].toString(), 
                                              societyId: societyId,
                                            );
                                            if (success) { 
                                              _fetchSlots(); 
                                              _fetchVehicles(); 
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Error: Could not find slot ID to unassign.'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                        child: const Text('Unassign', style: TextStyle(color: Colors.red, fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Unassigned', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () => _showAssignSlotDialog(v),
                                        child: const Text('Assign Slot', style: TextStyle(color: Colors.indigo, fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: PARKING MAP (SLOTS)
  // ==========================================
  Widget _buildParkingMapTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateSlotDialog(),
                  icon: const Icon(Icons.add_road),
                  label: const Text('Create Slot'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final societyId = await AuthService.getSocietyId();
                    try {
                      final success = await VehicleService.generateDefaultSlots(societyId);
                      if (success) _fetchSlots();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Slots Generated!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Auto-Gen'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingSlots
              ? const Center(child: CircularProgressIndicator())
              : _slots.isEmpty
                  ? const Center(child: Text('No slots created.'))
                  : ListView.builder(
                      itemCount: _slots.length,
                      itemBuilder: (context, index) {
                        final s = _slots[index];
                        final bool isOccupied = s['isOccupied'] == true || s['isOccupied'] == 'true';
                        final bool isAllotted = _safeId(s['flatId']) != null; // Fix
                        final String blockName = s['blockName']?.toString() ?? _getBlockName(s['blockId']?.toString());
                        
                        Color statusColor = Colors.grey;
                        String statusText = 'Unallotted (Guest Pool)';
                        
                        if (isAllotted && !isOccupied) {
                          statusColor = Colors.green;
                          statusText = 'Available (Allotted)';
                        } else if (isOccupied) {
                          statusColor = Colors.red;
                          statusText = 'Occupied';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Icon(s['slotType'] == 0 ? Icons.two_wheeler : Icons.directions_car, color: statusColor),
                            title: Text('Slot: ${s['slotNumber']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${blockName.isEmpty ? "No Block" : blockName} | ${s['slotType'] == 0 ? "2W" : "4W"}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(statusText, style: const TextStyle(fontSize: 10)),
                                  backgroundColor: statusColor.withOpacity(0.1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                  onPressed: () => _showCreateSlotDialog(existingSlot: s),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}