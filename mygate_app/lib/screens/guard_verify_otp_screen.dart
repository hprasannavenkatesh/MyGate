import 'package:flutter/material.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';

class GuardVerifyOtpScreen extends StatefulWidget {
  const GuardVerifyOtpScreen({super.key});

  @override
  State<GuardVerifyOtpScreen> createState() => _GuardVerifyOtpScreenState();
}

class _GuardVerifyOtpScreenState extends State<GuardVerifyOtpScreen> {
  final _searchController = TextEditingController();
  final _otpController = TextEditingController();
  
  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedVisitor;
  bool _isSearching = false;
  bool _isVerifying = false;

  Future<void> _searchVisitors() async {
    if (_searchController.text.isEmpty) return;
    setState(() { _isSearching = true; _selectedVisitor = null; });
    
    try {
      // Fetch all society visitors and filter locally by Mobile or Name
      final societyId = await AuthService.getSocietyId();
      final allVisitors = await VisitorService.getSocietyVisitors(societyId);
      
      final query = _searchController.text.toLowerCase();
      final results = allVisitors.where((v) => 
        (v['visitorMobile']?.toString().toLowerCase().contains(query) ?? false) ||
        (v['visitorName']?.toString().toLowerCase().contains(query) ?? false)
      ).toList();

      setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_selectedVisitor == null || _otpController.text.isEmpty) return;
    setState(() => _isVerifying = true);
    
    try {
      final success = await VisitorService.guardVerifyOtp(_selectedVisitor!['id'], _otpController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? '✅ Entry Approved!' : '❌ Invalid OTP'), 
          backgroundColor: success ? Colors.green : Colors.red
        ));
        if (success) {
          _otpController.clear();
          setState(() => _selectedVisitor = null);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Pre-Approval OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // SEARCH BOX
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Mobile or Name',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _searchVisitors),
              ),
              onSubmitted: (_) => _searchVisitors(),
            ),
            const SizedBox(height: 16),

            // SEARCH RESULTS LIST
            if (_isSearching) const CircularProgressIndicator(),
            if (!_isSearching && _selectedVisitor == null)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final v = _searchResults[index];
                    return Card(
                      child: ListTile(
                        title: Text(v['visitorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Mobile: ${v['visitorMobile']} | Date: ${v['expectedDate']?.substring(0, 10)}'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => setState(() => _selectedVisitor = v),
                      ),
                    );
                  },
                ),
              ),

            // SELECTED VISITOR & OTP ENTRY
            if (_selectedVisitor != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visitor: ${_selectedVisitor!['visitorName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Mobile: ${_selectedVisitor!['visitorMobile']}'),
                    Text('Meeting Flat: ${_selectedVisitor!['flatId']?.substring(0, 8)}...'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(labelText: 'Enter 4-Digit OTP from Visitor', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: _isVerifying ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify & Allow Entry', style: TextStyle(fontSize: 18)),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedVisitor = null), 
                child: const Text('← Search Again')
              ),
            ]
          ],
        ),
      ),
    );
  }
}