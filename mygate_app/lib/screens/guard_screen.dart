// lib/screens/guard_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/visitor_service.dart';
import 'login_screen.dart';

class GuardScreen extends StatefulWidget {
  final String token;
  const GuardScreen({super.key, required this.token});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _approvalIdController = TextEditingController();
  final _otpController = TextEditingController();
  final _exitVisitorIdController = TextEditingController();
  final _walkInNameController = TextEditingController();
  final _walkInMobileController = TextEditingController();
  final _walkInPurposeController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _approvalIdController.dispose();
    _otpController.dispose();
    _exitVisitorIdController.dispose();
    _walkInNameController.dispose();
    _walkInMobileController.dispose();
    _walkInPurposeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEntry() async {
    if (_approvalIdController.text.isEmpty || _otpController.text.isEmpty) {
      return _showError('Please enter Approval ID and OTP');
    }

    setState(() => _isLoading = true);
    try {
      final isSuccess = await VisitorService.verifyOtp(_approvalIdController.text, _otpController.text);
      
      if (isSuccess) {
        _exitVisitorIdController.text = _approvalIdController.text;
        _tabController.animateTo(1); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Visitor allowed inside! Switched to Exit tab.'), backgroundColor: Colors.green),
        );
        _approvalIdController.clear();
        _otpController.clear();
      } else {
        _showError('Invalid OTP or ID');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markExit() async {
    if (_exitVisitorIdController.text.isEmpty) {
      return _showError('Visitor ID is missing. Cannot mark exit.');
    }

    setState(() => _isLoading = true);
    try {
      final isSuccess = await VisitorService.markExit(_exitVisitorIdController.text);
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚪 Visitor marked as exited!'), backgroundColor: Colors.red),
        );
        _exitVisitorIdController.clear();
      } else {
        _showError('Failed to mark exit');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _walkInEntry() async {
    if (_walkInNameController.text.isEmpty || _walkInMobileController.text.isEmpty) {
      return _showError('Name and Mobile are required for walk-ins');
    }

    setState(() => _isLoading = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final flatId = await AuthService.getFlatId();
      final userId = await AuthService.getUserId();

      if (societyId.isEmpty || flatId.isEmpty) {
        setState(() => _isLoading = false);
        return _showError('Missing Society/Flat in token. Please log out and log back in.');
      }

      // Step 1: Pre-Approve
      final preApprovalData = await VisitorService.preApproveWalkIn(
        societyId: societyId,
        flatId: flatId,
        visitorName: _walkInNameController.text,
        visitorMobile: _walkInMobileController.text,
        purpose: _walkInPurposeController.text.isEmpty ? 'Walk-in' : _walkInPurposeController.text,
        expectedDate: DateTime.now().toIso8601String(),
        invitedByUserId: userId,
      );

      final visitorId = preApprovalData?['id'] ?? '';

      // Step 2: Manual Entry Override
      final isManualEntrySuccess = await VisitorService.manualEntry(visitorId);

      if (isManualEntrySuccess) {
        _exitVisitorIdController.text = visitorId;
        _tabController.animateTo(1); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Walk-in allowed inside! Switched to Exit tab.'), backgroundColor: Colors.green),
        );
        _walkInNameController.clear();
        _walkInMobileController.clear();
        _walkInPurposeController.clear();
      } else {
        _showError('Pre-approved, but Manual Entry failed.');
      }
    } catch (e) {
      _showError('$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Portal', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.login), text: 'Entry'),
            Tab(icon: Icon(Icons.logout), text: 'Exit'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              await AuthService.logout(); 
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              }
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ENTRY
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Verify Pre-Approval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _approvalIdController,
                  decoration: const InputDecoration(labelText: 'Visitor Approval ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'Gate OTP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.password)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyEntry,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('ALLOW ENTRY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),

                const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Divider(thickness: 2, color: Colors.grey)),
                const Text('Walk-in Entry (No OTP)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _walkInNameController,
                  decoration: const InputDecoration(labelText: 'Visitor Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _walkInMobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Visitor Mobile', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _walkInPurposeController,
                  decoration: const InputDecoration(labelText: 'Purpose (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.comment)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _walkInEntry,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('WALK-IN ENTRY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

          // TAB 2: EXIT
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.exit_to_app, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text('Mark Visitor Exit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _exitVisitorIdController,
                  decoration: const InputDecoration(labelText: 'Visitor ID (Auto-filled after entry)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.vpn_key)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _markExit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('MARK EXIT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}