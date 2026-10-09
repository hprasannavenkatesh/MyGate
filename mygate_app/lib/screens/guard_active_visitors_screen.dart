// lib/screens/guard_active_visitors_screen.dart
/*
import 'package:flutter/material.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';

class GuardActiveVisitorsScreen extends StatefulWidget {
  const GuardActiveVisitorsScreen({super.key});

  @override
  State<GuardActiveVisitorsScreen> createState() => _GuardActiveVisitorsScreenState();
}

class _GuardActiveVisitorsScreenState extends State<GuardActiveVisitorsScreen> {
  List<dynamic> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
  }

  Future<void> _fetchVisitors() async {
    try {
      final societyId = await AuthService.getSocietyId();
      final allVisitors = await VisitorService.getSocietyVisitors(societyId);
      
      // Filter for only those currently Inside (Adjust logic based on your backend enum response)
      // If backend returns string: v['status'] == 'Inside'
      // If backend returns int: v['status'] == 1
      final insideVisitors = allVisitors.where((v) => v['status'] == 1 || v['status'] == 'Inside').toList();
      
      if (mounted) setState(() { _visitors = insideVisitors; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currently Inside Society')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _visitors.isEmpty 
              ? const Center(child: Text('No visitors currently inside.'))
              : ListView.builder(
                  itemCount: _visitors.length,
                  itemBuilder: (context, index) {
                    final v = _visitors[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.directions_walk, color: Colors.green),
                        title: Text(v['visitorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Mobile: ${v['visitorMobile'] ?? 'N/A'}\nFlat: ${v['flatId'] ?? 'N/A'}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          tooltip: 'Quick Exit',
                          onPressed: () async {
                            await VisitorService.markExit(v['id']);
                            _fetchVisitors(); // Refresh list
                          }
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}*/

// lib/screens/guard_active_visitors_screen.dart
import 'package:flutter/material.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';

class GuardActiveVisitorsScreen extends StatefulWidget {
  const GuardActiveVisitorsScreen({super.key});

  @override
  State<GuardActiveVisitorsScreen> createState() => _GuardActiveVisitorsScreenState();
}

class _GuardActiveVisitorsScreenState extends State<GuardActiveVisitorsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _visitors = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Verify OTP State
  final _searchController = TextEditingController();
  final _otpController = TextEditingController();
  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedVisitor;
  bool _isSearching = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchVisitors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _fetchVisitors() async {
    setState(() => _isLoading = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final allVisitors = await VisitorService.getSocietyVisitors(societyId);
      if (mounted) setState(() { _visitors = allVisitors; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filters
  List<dynamic> get _pendingVisitors => _visitors.where((v) => v['status'] == 0 || v['status'] == 'Pending').toList();
  List<dynamic> get _insideVisitors => _visitors.where((v) => v['status'] == 1 || v['status'] == 'Inside').toList();
  List<dynamic> get _exitedVisitors => _visitors.where((v) => v['status'] == 2 || v['status'] == 'Exited').toList();

  // ==========================================
  // VERIFY OTP LOGIC (Moved here for 1-stop-shop)
  // ==========================================
  Future<void> _searchVisitors() async {
    if (_searchController.text.isEmpty) return;
    setState(() { _isSearching = true; _selectedVisitor = null; });
    
    try {
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
          _fetchVisitors(); // Refresh all tabs
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
      appBar: AppBar(
        title: const Text('Gate Management'),
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
                _buildPendingTab(), // Special tab with Search & Verify
                _buildVisitorList(_insideVisitors, showMarkExit: true),
                _buildVisitorList(_exitedVisitors, showMarkExit: false),
              ],
            ),
    );
  }

  // ==========================================
  // PENDING TAB (Inline Verify OTP)
  // ==========================================
  Widget _buildPendingTab() {
    return Column(
      children: [
        // Quick Verify OTP Section
        Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.orange.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Verify OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Mobile or Name',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _searchVisitors),
                ),
                onSubmitted: (_) => _searchVisitors(),
              ),
              if (_isSearching) const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator())),
              
              if (_selectedVisitor != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Visitor: ${_selectedVisitor!['visitorName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Mobile: ${_selectedVisitor!['visitorMobile']}'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, letterSpacing: 8),
                        decoration: const InputDecoration(labelText: 'Enter 4-Digit OTP', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: _isVerifying ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify'),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedVisitor = null), 
                  child: const Text('← Search Again')
                ),
              ]
              else if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final v = _searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(v['visitorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Mobile: ${v['visitorMobile']}'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => setState(() => _selectedVisitor = v),
                      );
                    },
                  ),
                ),
              ]
            ],
          ),
        ),

        // List of Pending Visitors (Read-only context)
        Expanded(
          child: _buildVisitorList(_pendingVisitors, showMarkExit: false),
        ),
      ],
    );
  }

  // ==========================================
  // REUSABLE LIST BUILDER
  // ==========================================
  Widget _buildVisitorList(List<dynamic> visitors, {required bool showMarkExit}) {
    if (visitors.isEmpty) {
      return const Center(child: Text('No visitors in this category.'));
    }

    return ListView.builder(
      itemCount: visitors.length,
      itemBuilder: (context, index) {
        final v = visitors[index];
        final status = v['status'];
        
        return Card(
          child: ListTile(
            leading: Icon(
              status == 1 || status == 'Inside' ? Icons.directions_walk : Icons.history, 
              color: status == 1 || status == 'Inside' ? Colors.green : Colors.grey
            ),
            title: Text(v['visitorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Mobile: ${v['visitorMobile'] ?? 'N/A'}\nPurpose: ${v['purpose'] ?? 'N/A'}'),
            isThreeLine: true,
            trailing: showMarkExit ? ElevatedButton.icon(
              onPressed: () async {
                await VisitorService.guardMarkExit(v['id']);
                _fetchVisitors(); // Refresh all tabs
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Exit'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            ) : null,
          ),
        );
      },
    );
  }
}