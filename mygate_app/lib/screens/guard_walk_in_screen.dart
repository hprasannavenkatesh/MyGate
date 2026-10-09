import 'package:flutter/material.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';
import '../services/tenant_admin_service.dart'; // Required for Block/Flat fetching

class GuardWalkInScreen extends StatefulWidget {
  const GuardWalkInScreen({super.key});
  @override
  State<GuardWalkInScreen> createState() => _GuardWalkInScreenState();
}

class _GuardWalkInScreenState extends State<GuardWalkInScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  // State for dropdowns
  List<dynamic> _blocks = [];
  List<dynamic> _flats = [];
  String? _selectedBlockId;
  String? _selectedFlatId;
  bool _isLoadingBlocks = true;
  bool _isLoadingFlats = false;

  @override
  void initState() {
    super.initState();
    _fetchBlocks();
  }

  Future<void> _fetchBlocks() async {
    try {
      final societyId = await AuthService.getSocietyId();
      final blocks = await TenantAdminService.getBlocks(societyId);
      if (mounted) {
        setState(() {
          _blocks = blocks;
          _isLoadingBlocks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBlocks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blocks: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchFlats(String blockId) async {
    setState(() {
      _isLoadingFlats = true;
      _flats = [];
      _selectedFlatId = null;
    });
    
    try {
      final flats = await TenantAdminService.getFlats(blockId);
      if (mounted) {
        setState(() {
          _flats = flats;
          _isLoadingFlats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFlats = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading flats: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _walkIn() async {
    if (_nameController.text.isEmpty || _selectedFlatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Flat are required.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final userId = await AuthService.getUserId();

      // STEP 1: Create the visitor record (Pre-Approve)
      final payload = {
        'societyId': societyId,
        'flatId': _selectedFlatId!, 
        'visitorName': _nameController.text.trim(),
        'visitorMobile': _mobileController.text.trim().isEmpty ? 'N/A' : _mobileController.text.trim(),
        'expectedDate': DateTime.now().toUtc().toIso8601String().split('T').first,
        'purpose': _purposeController.text.trim().isEmpty ? 'Guard Walk-in' : _purposeController.text.trim(),
        'invitedByUserId': userId, 
      };

      final result = await VisitorService.preApproveVisitor(payload);
      final visitorId = result['id']; // Get the ID of the newly created visitor

      // STEP 2: Immediately mark them as entered (Manual Entry Override - No OTP needed!)
      if (visitorId != null) {
        await VisitorService.manualWalkIn({
          'preApprovalId': visitorId,
          'reason': 'Walk-in entry at gate by Guard',
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Walk-in Logged & Entry Marked!'), 
            backgroundColor: Colors.green,
          ),
        );
        // Reset form
        _nameController.clear();
        _mobileController.clear();
        _purposeController.clear();
        setState(() {
          _selectedBlockId = null;
          _selectedFlatId = null;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk-in Entry'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Visitor Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Mobile
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // BLOCK DROPDOWN
              if (_isLoadingBlocks)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: _selectedBlockId,
                  hint: const Text('Select Block *'),
                  items: _blocks.map((b) => DropdownMenuItem<String>(
                    value: b['id'].toString(), 
                    child: Text('Block ${b['name']}')
                  )).toList(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.apartment),
                  ),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedBlockId = val);
                    _fetchFlats(val);
                  },
                ),
              const SizedBox(height: 16),

              // FLAT DROPDOWN
              if (_isLoadingFlats)
                const Center(child: CircularProgressIndicator())
              else if (_selectedBlockId != null)
                DropdownButtonFormField<String>(
                  value: _selectedFlatId,
                  hint: const Text('Select Flat *'),
                  items: _flats.map((f) => DropdownMenuItem<String>(
                    value: f['id'].toString(), 
                    child: Text('Flat ${f['flatNumber']}')
                  )).toList(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                  onChanged: (val) => setState(() => _selectedFlatId = val),
                ),
              const SizedBox(height: 16),

              // Purpose
              TextField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Visit',
                  prefixIcon: Icon(Icons.question_mark),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _walkIn,
                  icon: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Icon(Icons.login),
                  label: const Text('Log Walk-in', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}