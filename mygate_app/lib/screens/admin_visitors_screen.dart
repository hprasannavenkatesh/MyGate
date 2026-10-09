// lib/screens4/admin_visitors_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/visitor_service.dart';
import '../../services/auth_service.dart';
import '../../services/tenant_admin_service.dart';
import '../../services/api_config.dart';

class AdminVisitorsScreen extends StatefulWidget {
  const AdminVisitorsScreen({super.key});

  @override
  State<AdminVisitorsScreen> createState() => _AdminVisitorsScreenState();
}

class _AdminVisitorsScreenState extends State<AdminVisitorsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _visitors = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchVisitors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchVisitors() async {
    setState(() => _isLoading = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final data = await VisitorService.getSocietyVisitors(societyId);
      if (mounted) setState(() => _visitors = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // FILTERS
  // ==========================================
  List<dynamic> get _pendingVisitors => _visitors.where((v) => v['status'] == 0 || v['status'] == 'Pending').toList();
  List<dynamic> get _insideVisitors => _visitors.where((v) => v['status'] == 1 || v['status'] == 'Inside').toList();
  List<dynamic> get _exitedVisitors => _visitors.where((v) => v['status'] == 2 || v['status'] == 'Exited').toList();

  // ==========================================
  // ACTIONS
  // ==========================================
  Future<void> _markExit(String visitorId) async {
    try {
      await VisitorService.guardMarkExit(visitorId);
      _fetchVisitors(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exit Marked!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

   Future<void> _regenerateOtp(String visitorId) async {
    try {
      final result = await VisitorService.regenerateOtp(visitorId);
      final newOtp = result['otp'] ?? 'N/A';
      _fetchVisitors(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New OTP: $newOtp'), 
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showVerifyOtpDialog(String visitorId, String visitorName) async {
    final otpController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Verify Entry: $visitorName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the 4-digit OTP provided by the visitor at the gate.'),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(labelText: 'Gate OTP', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (otpController.text.isEmpty) return;
                
                try {
                  final success = await VisitorService.guardVerifyOtp(visitorId, otpController.text);
                  if (ctx.mounted) Navigator.pop(ctx);

                  if (success) {
                    _fetchVisitors();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Entry Approved! Visitor is Inside.'), backgroundColor: Colors.green),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ Invalid OTP'), backgroundColor: Colors.red),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Verify & Allow Entry'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPreApproveDialog() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final purposeController = TextEditingController();

    List<dynamic> blocks = [];
    List<dynamic> flats = [];
    String? selectedBlockId;
    String? selectedFlatId;
    bool isLoadingBlocks = true;
    bool isLoadingFlats = false;

    try {
      final societyId = await AuthService.getSocietyId();
      blocks = await TenantAdminService.getBlocks(societyId);
      isLoadingBlocks = false;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading blocks: $e'), backgroundColor: Colors.red));
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pre-Approve Visitor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Visitor Name *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    
                    if (isLoadingBlocks)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        value: selectedBlockId,
                        hint: const Text('Select Block *'),
                        items: blocks.map((b) => DropdownMenuItem<String>(value: b['id'].toString(), child: Text('Block ${b['name']}'))).toList(),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        onChanged: (val) async {
                          if (val == null) return;
                          setDialogState(() { selectedBlockId = val; selectedFlatId = null; flats = []; isLoadingFlats = true; });
                          try {
                            final fetchedFlats = await TenantAdminService.getFlats(val);
                            setDialogState(() { flats = fetchedFlats; isLoadingFlats = false; });
                          } catch (e) {
                            setDialogState(() => isLoadingFlats = false);
                          }
                        },
                      ),
                    const SizedBox(height: 12),

                    if (isLoadingFlats)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Center(child: CircularProgressIndicator()))
                    else if (selectedBlockId != null)
                      DropdownButtonFormField<String>(
                        value: selectedFlatId,
                        hint: const Text('Select Flat *'),
                        items: flats.map((f) => DropdownMenuItem<String>(value: f['id'].toString(), child: Text('Flat ${f['flatNumber']}'))).toList(),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        onChanged: (val) => setDialogState(() => selectedFlatId = val),
                      ),
                    const SizedBox(height: 12),
                    TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || mobileController.text.isEmpty || selectedFlatId == null) return;
                    final societyId = await AuthService.getSocietyId();
                    final userId = await AuthService.getUserId();

                    final payload = {
                      'societyId': societyId, 'flatId': selectedFlatId!, 
                      'visitorName': nameController.text.trim(), 'visitorMobile': mobileController.text.trim(),
                      'expectedDate': DateTime.now().toUtc().toIso8601String().split('T').first,
                      'purpose': purposeController.text.trim().isEmpty ? 'Admin Pre-Approved' : purposeController.text.trim(),
                      'invitedByUserId': userId,
                    };

                    try {
                      final result = await VisitorService.preApproveVisitor(payload);
                      if (ctx.mounted) Navigator.pop(ctx);
                      final otp = result['otp'] ?? 'N/A';
                      _fetchVisitors();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Pre-Approved! Gate OTP: $otp'), backgroundColor: Colors.green, duration: const Duration(seconds: 5)));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Pre-Approve'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showWalkInDialog() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final purposeController = TextEditingController();

    List<dynamic> blocks = [];
    List<dynamic> flats = [];
    String? selectedBlockId;
    String? selectedFlatId;
    bool isLoadingBlocks = true;
    bool isLoadingFlats = false;

    try {
      final societyId = await AuthService.getSocietyId();
      blocks = await TenantAdminService.getBlocks(societyId);
      isLoadingBlocks = false;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading blocks: $e'), backgroundColor: Colors.red));
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Walk-in Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Visitor Name *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    
                    if (isLoadingBlocks) const Center(child: CircularProgressIndicator())
                    else DropdownButtonFormField<String>(
                      value: selectedBlockId, hint: const Text('Select Block *'),
                      items: blocks.map((b) => DropdownMenuItem<String>(value: b['id'].toString(), child: Text('Block ${b['name']}'))).toList(),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      onChanged: (val) async {
                        if (val == null) return;
                        setDialogState(() { selectedBlockId = val; selectedFlatId = null; flats = []; isLoadingFlats = true; });
                        try { final fetchedFlats = await TenantAdminService.getFlats(val); setDialogState(() { flats = fetchedFlats; isLoadingFlats = false; }); } 
                        catch (e) { setDialogState(() => isLoadingFlats = false); }
                      },
                    ),
                    const SizedBox(height: 12),

                    if (isLoadingFlats) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Center(child: CircularProgressIndicator()))
                    else if (selectedBlockId != null) DropdownButtonFormField<String>(
                      value: selectedFlatId, hint: const Text('Select Flat *'),
                      items: flats.map((f) => DropdownMenuItem<String>(value: f['id'].toString(), child: Text('Flat ${f['flatNumber']}'))).toList(),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      onChanged: (val) => setDialogState(() => selectedFlatId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || selectedFlatId == null) return;
                    final societyId = await AuthService.getSocietyId();
                    final userId = await AuthService.getUserId();

                    final payload = {
                      'societyId': societyId, 'flatId': selectedFlatId!, 
                      'visitorName': nameController.text.trim(), 
                      'visitorMobile': mobileController.text.trim().isEmpty ? 'N/A' : mobileController.text.trim(),
                      'expectedDate': DateTime.now().toUtc().toIso8601String().split('T').first,
                      'purpose': purposeController.text.trim().isEmpty ? 'Admin Walk-in' : purposeController.text.trim(),
                      'invitedByUserId': userId,
                    };

                    try {
                      final result = await VisitorService.preApproveVisitor(payload);
                      final visitorId = result['id']; 

                      if (visitorId != null) {
                        await VisitorService.manualWalkIn({ 'preApprovalId': visitorId, 'reason': 'Walk-in entry by Admin' });
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchVisitors(); 
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Walk-in Logged & Entry Marked!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Log Walk-in'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getStatusText(dynamic status) {
    if (status == 0 || status == 'Pending') return 'Pending';
    if (status == 1 || status == 'Inside') return 'Inside';
    if (status == 2 || status == 'Exited') return 'Exited';
    if (status == 3 || status == 'Expired') return 'Expired';
    return 'Unknown';
  }

  Color _getStatusColor(dynamic status) {
    if (status == 0 || status == 'Pending') return Colors.orange.shade100;
    if (status == 1 || status == 'Inside') return Colors.green.shade100;
    if (status == 2 || status == 'Exited') return Colors.grey.shade200;
    return Colors.red.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Pending'),
            Tab(icon: Icon(Icons.directions_walk), text: 'Inside'),
            Tab(icon: Icon(Icons.history), text: 'Exited'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVisitorList(_pendingVisitors),
                _buildVisitorList(_insideVisitors),
                _buildVisitorList(_exitedVisitors),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'walkIn',
            onPressed: _showWalkInDialog,
            icon: const Icon(Icons.directions_walk),
            label: const Text('Walk-in'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'preApprove',
            onPressed: _showPreApproveDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Pre-Approve'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorList(List<dynamic> visitors) {
    if (visitors.isEmpty) {
      return const Center(child: Text('No visitors in this category.'));
    }

    return ListView.builder(
      itemCount: visitors.length,
      itemBuilder: (context, index) {
        final v = visitors[index];
        final status = v['status'];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(v['visitorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Chip(label: Text(_getStatusText(status), style: const TextStyle(fontSize: 12)), backgroundColor: _getStatusColor(status)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Mobile: ${v['visitorMobile'] ?? 'N/A'}'),
                Text('Purpose: ${v['purpose'] ?? 'N/A'}'),
                Text('Date: ${v['expectedDate']?.substring(0, 10) ?? 'N/A'}'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 0 || status == 'Pending') ...[
                      Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        onPressed: () => _showVerifyOtpDialog(v['id'], v['visitorName'] ?? 'Visitor'),
                        avatar: const Icon(Icons.password, size: 16),
                        label: const Text('Verify OTP'),
                      ),
                    ),
                    ActionChip(
                      onPressed:() => _regenerateOtp(v['id']),
                      avatar: const Icon(Icons.refresh, size: 16),
                      label: const Text('New OTP'),
                    ),
                  ],
               // ),//
                if (status == 1 || status == 'Inside') 
                  ActionChip(
                    onPressed: () => _markExit(v['id']),
                    avatar: const Icon(Icons.logout, size: 16),
                    label: const Text('Mark Exit'),
                  ),
              ],
            )
            ],
          ),),
        );
      },
    );
  }
}