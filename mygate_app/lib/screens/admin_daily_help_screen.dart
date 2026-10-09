// lib/screens/admin_daily_help_screen.dart
import 'package:flutter/material.dart';
import '../../services/daily_help_service.dart';
import '../../services/auth_service.dart';

class AdminDailyHelpScreen extends StatefulWidget {
  const AdminDailyHelpScreen({super.key});

  @override
  State<AdminDailyHelpScreen> createState() => _AdminDailyHelpScreenState();
}

class _AdminDailyHelpScreenState extends State<AdminDailyHelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- State for Help Types ---
  List<dynamic> _helpTypes = [];
  bool _isLoadingTypes = true;

  // --- State for Staff ---
  List<dynamic> _staff = [];
  bool _isLoadingStaff = true;

  // --- State for Assignments ---
  final _staffIdController = TextEditingController();
  final _flatIdController = TextEditingController();
  final _workingDaysController = TextEditingController(text: 'Mon,Tue,Wed,Thu,Fri');
  final _inTimeController = TextEditingController(text: '08:00');
  final _outTimeController = TextEditingController(text: '18:00');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchHelpTypes();
    _fetchStaff();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // HELP TYPES LOGIC
  // ==========================================
  Future<void> _fetchHelpTypes() async {
    setState(() => _isLoadingTypes = true);
    try {
      final data = await DailyHelpService.getHelpTypes();
      if (mounted) setState(() => _helpTypes = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingTypes = false);
    }
  }

  Future<void> _showCreateHelpTypeDialog() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Help Type'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name (e.g., Maid, Driver)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final success = await DailyHelpService.createHelpType(nameController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (success) {
                _fetchHelpTypes();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help Type Added!'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STAFF LOGIC
  // ==========================================
  Future<void> _fetchStaff() async {
    setState(() => _isLoadingStaff = true);
    try {
      final data = await DailyHelpService.getStaff();
      if (mounted) setState(() => _staff = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _showCreateStaffDialog() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final agencyController = TextEditingController();
    String? selectedHelpTypeId;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Staff Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedHelpTypeId,
                      hint: const Text('Select Help Type *'),
                      items: _helpTypes.map((ht) => DropdownMenuItem(value: ht['id'].toString(), child: Text(ht['name']))).toList(),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      onChanged: (val) => setDialogState(() => selectedHelpTypeId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: agencyController, decoration: const InputDecoration(labelText: 'Agency Name (Optional)', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || mobileController.text.isEmpty || selectedHelpTypeId == null) return;
                    
                    final societyId = await AuthService.getSocietyId();
                    final success = await DailyHelpService.createStaff({
                      'societyId': societyId,
                      'name': nameController.text.trim(),
                      'mobileNumber': mobileController.text.trim(),
                      'helpTypeId': selectedHelpTypeId!,
                      'agencyName': agencyController.text.trim().isEmpty ? null : agencyController.text.trim(),
                    });

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (success) {
                      _fetchStaff();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff Added!'), backgroundColor: Colors.green));
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // ASSIGNMENTS LOGIC
  // ==========================================
  Future<void> _showAssignStaffDialog() async {
    _staffIdController.clear();
    _flatIdController.clear();
    _workingDaysController.text = 'Mon,Tue,Wed,Thu,Fri';
    _inTimeController.text = '08:00';
    _outTimeController.text = '18:00';
    String? selectedStaffId;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Staff to Flat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedStaffId,
                      hint: const Text('Select Staff Member *'),
                      items: _staff.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text('${s['name']} (${s['helpTypeName']})'))).toList(),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      onChanged: (val) => setDialogState(() => selectedStaffId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _flatIdController, decoration: const InputDecoration(labelText: 'Flat ID (GUID) *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _workingDaysController, decoration: const InputDecoration(labelText: 'Working Days (comma sep)', border: OutlineInputBorder())),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _inTimeController, decoration: const InputDecoration(labelText: 'In Time', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _outTimeController, decoration: const InputDecoration(labelText: 'Out Time', border: OutlineInputBorder()))),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedStaffId == null || _flatIdController.text.isEmpty) return;
                    
                    final societyId = await AuthService.getSocietyId();
                    final success = await DailyHelpService.assignStaff({
                      'staffId': selectedStaffId!,
                      'flatId': _flatIdController.text.trim(),
                      'societyId': societyId,
                      'workingDays': _workingDaysController.text.trim(),
                      'inTime': _inTimeController.text.trim(),
                      'outTime': _outTimeController.text.trim(),
                    });

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Staff Assigned!'), backgroundColor: Colors.green));
                    }
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Help Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Help Types'),
            Tab(icon: Icon(Icons.people), text: 'Staff'),
            Tab(icon: Icon(Icons.assignment_ind), text: 'Assign'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: HELP TYPES
          _isLoadingTypes
              ? const Center(child: CircularProgressIndicator())
              : _helpTypes.isEmpty
                  ? const Center(child: Text('No help types found.'))
                  : ListView.builder(
                      itemCount: _helpTypes.length,
                      itemBuilder: (context, index) {
                        final ht = _helpTypes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.label, color: Colors.indigo),
                            title: Text(ht['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),

          // TAB 2: STAFF
          _isLoadingStaff
              ? const Center(child: CircularProgressIndicator())
              : _staff.isEmpty
                  ? const Center(child: Text('No staff members found.'))
                  : ListView.builder(
                      itemCount: _staff.length,
                      itemBuilder: (context, index) {
                        final s = _staff[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(s['mobileNumber'] ?? 'N/A'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(s['helpTypeName'] ?? 'N/A', style: const TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.blue.shade50,
                                    ),
                                    if (s['agencyName'] != null) ...[
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(s['agencyName'], style: const TextStyle(fontSize: 11)),
                                        backgroundColor: Colors.orange.shade50,
                                      ),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

          // TAB 3: ASSIGNMENTS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Assign Staff to Flats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                const Text('To assign a daily help staff member to a specific flat, click the button below and provide the Staff Member and target Flat ID.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _showAssignStaffDialog,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Assign Staff to Flat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton(
              onPressed: _showCreateHelpTypeDialog,
              tooltip: 'Add Help Type',
              child: const Icon(Icons.add),
            )
          : _tabController.index == 1 
              ? FloatingActionButton(
                  onPressed: _showCreateStaffDialog,
                  tooltip: 'Add Staff',
                  child: const Icon(Icons.person_add),
                )
              : null,
    );
  }
}