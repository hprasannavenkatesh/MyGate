import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Required for shared_preferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyGateApp());
}

class MyGateApp extends StatelessWidget {
  const MyGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyGate Clone',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Check if user is permanently logged in, skip Login screen!
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // If token exists, go to Home. If not, go to Login.
          return snapshot.data == true ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return token != null;
  }
}

// ==========================================
// 1. LOGIN SCREEN (Now with Guard Mode!)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGuardMode = false; // Toggle for Guard Mode
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _jwtToken;

  Future<void> _requestOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5103/api/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': _mobileController.text}),
      );
      if (response.statusCode == 200) setState(() => _isOtpSent = true);
      else _showError('Failed to send OTP');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5103/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': _mobileController.text, 'otp': _otpController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _jwtToken = data['token']);
        
        // PERMANENT SAVE: Save token locally!
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _jwtToken!);

        if (_isGuardMode) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GuardScreen(token: '')));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SocietySelectionScreen(token: _jwtToken!)));
        }
      } else {
        _showError('Invalid OTP');
      }
    } catch (e) {
      _showError('Error: $e');
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isGuardMode ? Icons.security : Icons.lock_person, size: 80, color: _isGuardMode ? Colors.orange : Colors.blue),
            const SizedBox(height: 20),
            Text(_isGuardMode ? 'Guard Portal' : 'Welcome to MyGate', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            
            // GUARD MODE TOGGLE
            TextButton.icon(
              onPressed: () => setState(() => _isGuardMode = !_isGuardMode),
              icon: Icon(_isGuardMode ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.orange),
              label: const Text('Login as Security Guard', style: TextStyle(color: Colors.orange)),
            ),
            const SizedBox(height: 40),
            
            if (!_isOtpSent) ...[
              TextField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _requestOtp, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send OTP', style: TextStyle(fontSize: 18)))),
            ] else ...[
              TextField(controller: _otpController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: '4-Digit OTP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.password))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _verifyOtp, style: ElevatedButton.styleFrom(backgroundColor: _isGuardMode ? Colors.orange : Colors.green), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify & Login', style: TextStyle(fontSize: 18)))),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. SOCIETY SELECTION SCREEN
// ==========================================
class SocietySelectionScreen extends StatefulWidget {
  final String token;
  const SocietySelectionScreen({super.key, required this.token});

  @override
  State<SocietySelectionScreen> createState() => _SocietySelectionScreenState();
}

class _SocietySelectionScreenState extends State<SocietySelectionScreen> {
  List<dynamic> _societies = [];
  bool _isLoading = true;
  String _extractUserId(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return '';
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded)['sub'];
  }

  Future<void> _fetchSocieties() async {
    try {
      final userId = _extractUserId(widget.token);
      final response = await http.get(
        Uri.parse('http://localhost:5104/api/societies/my-societies?userId=$userId'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() { _societies = jsonDecode(response.body); _isLoading = false; });
      } else { _showError('Failed to load societies'); }
    } catch (e) { _showError('Error: $e'); setState(() => _isLoading = false); }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() { super.initState(); _fetchSocieties(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Flat'), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('jwt_token'); // LOGOUT!
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        })
      ]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _societies.length,
        itemBuilder: (context, index) {
          final society = _societies[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.apartment, color: Colors.blue, size: 40),
              title: Text(society['societyName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Block: ${society['blockName']} - Flat: ${society['flatNumber']}'),
              trailing: Chip(label: Text(society['memberType']), backgroundColor: Colors.blue.withOpacity(0.1)),
              /*onTap: () {
                // Save Flat selection permanently too!
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
              },*/
                                      onTap: () async {
                          // Save selected flat details locally!
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('society_id', society['societyId']);
                          await prefs.setString('flat_id', society['flatId']);
                          
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                        },
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. HOME SCREEN (My Visitors List)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _visitors = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      setState(() => _token = token);
      _fetchVisitors(token);
    }
  }

  String _extractUserId(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return '';
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded)['sub'];
  }

  Future<void> _fetchVisitors(String token) async {
    try {
      final userId = _extractUserId(token);
      final response = await http.get(
        Uri.parse('http://localhost:5105/api/visitors/my-visitors?inviterId=$userId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() { _visitors = jsonDecode(response.body); _isLoading = false; });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

/*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Visitors'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('jwt_token');
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          })
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final realSocietyId = prefs.getString('society_id') ?? '';
          final realFlatId = prefs.getString('flat_id') ?? '';
          // Navigate to Add Visitor (using dummy IDs for now, in real app pull from saved state)
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVisitorScreen(token: 'dummy', societyId: 'dummy', flatId: 'dummy')));
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Visitor'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _visitors.isEmpty 
              ? const Center(child: Text('No visitors pre-approved yet.', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _visitors.length,
                  itemBuilder: (context, index) {
                    final v = _visitors[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, size: 40),
                        title: Text(v['visitorName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mobile: ${v['visitorMobile']}'),
                            Text('Date: ${v['expectedDate'].toString().substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(v['status'] == 0 ? 'Pending' : 'Expired'),
                          backgroundColor: v['status'] == 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    );
                  },
                ),
    );
  }*/
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Visitors'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('jwt_token');
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          })
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final prefs = SharedPreferences.getInstance();
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVisitorScreen(token: 'dummy', societyId: 'dummy', flatId: 'dummy')));
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Visitor'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // NEW: Quick Access Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyDuesScreen()));
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('View My Maintenance Dues', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    ),
                  ),
                ),
                // Existing Visitor List
                Expanded(
                  child: _visitors.isEmpty 
                      ? const Center(child: Text('No visitors pre-approved yet.', style: TextStyle(fontSize: 18, color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _visitors.length,
                          itemBuilder: (context, index) {
                            final v = _visitors[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.person_outline, size: 40),
                                title: Text(v['visitorName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Mobile: ${v['visitorMobile']}'),
                                    Text('Date: ${v['expectedDate'].toString().substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(v['status'] == 0 ? 'Pending' : 'Expired'),
                                  backgroundColor: v['status'] == 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ==========================================
// 4. ADD VISITOR SCREEN
// ==========================================
class AddVisitorScreen extends StatefulWidget {
  final String token;
  final String societyId;
  final String flatId;
  const AddVisitorScreen({super.key, required this.token, required this.societyId, required this.flatId});

  @override
  State<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  DateTime? _expectedDate;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (picked != null) setState(() => _expectedDate = picked);
  }

  /*Future<void> _submitVisitor() async {
    if (!_formKey.currentState!.validate() || _expectedDate == null) return _showError('Please fill all fields');
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final realToken = prefs.getString('jwt_token') ?? widget.token; // Use saved token!
      
      final response = await http.post(
        Uri.parse('http://localhost:5105/api/visitors/pre-approve'),
        headers: {'Authorization': 'Bearer $realToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'societyId': widget.societyId, 'flatId': widget.flatId, 'visitorName': _nameController.text, 'visitorMobile': _mobileController.text, 'expectedDate': _expectedDate!.toIso8601String(), 'purpose': _purposeController.text}),
      );
      if (response.statusCode == 201) {
        _showError('🎉 Visitor Pre-Approved!');
        Navigator.pop(context); // Go back to refresh list
      } else {
        _showError('Failed: ${response.body}');
      }
    } catch (e) { _showError('Error: $e'); } finally { setState(() => _isLoading = false); }
  }*/
     Future<void> _submitVisitor() async {
    if (!_formKey.currentState!.validate() || _expectedDate == null) {
      return _showError('Please fill all fields and select a date.');
    }

    // 1. ALWAYS get the latest saved IDs from local storage!
    final prefs = await SharedPreferences.getInstance();
    final realSocietyId = prefs.getString('society_id');
    final realFlatId = prefs.getString('flat_id');
    
    // 2. Safety Check: Did we actually save the flat IDs?
    if (realSocietyId == null || realFlatId == null) {
      return _showError('Error: Flat selection lost. Please log out and log back in.');
    }

    setState(() => _isLoading = true);
    try {
      final realToken = prefs.getString('jwt_token') ?? widget.token; 

      // 3. Use jsonEncode safely! It automatically adds the perfect quotes.
      final response = await http.post(
        Uri.parse('http://localhost:5105/api/visitors/pre-approve'),
        headers: {'Authorization': 'Bearer $realToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'societyId': realSocietyId, // Real GUID, properly quoted by jsonEncode
          'flatId': realFlatId,       // Real GUID, properly quoted by jsonEncode
          'visitorName': _nameController.text,
          'visitorMobile': _mobileController.text,
          'expectedDate': _expectedDate!.toIso8601String(),
          'purpose': _purposeController.text
        }),
      );

      if (response.statusCode == 201) {
        _showError('🎉 Visitor Pre-Approved! Check .NET terminal for OTP.');
        Navigator.pop(context); 
      } else {
        _showError('Failed: ${response.body}');
      }
    } catch (e) { 
      _showError('Error: $e'); 
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
      appBar: AppBar(title: const Text('Pre-Approve Visitor'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Visitor Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (val) => val!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Visitor Mobile', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), validator: (val) => val!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _purposeController, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder(), prefixIcon: Icon(Icons.comment))),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _pickDate,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.grey)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_expectedDate == null ? 'Select Expected Date' : 'Date: ${_expectedDate!.day}/${_expectedDate!.month}/${_expectedDate!.year}', style: TextStyle(color: _expectedDate == null ? Colors.grey : Colors.black)),
                  const Icon(Icons.calendar_today),
                ]),
              ),
              const Spacer(),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _submitVisitor, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Pre-Approve Visitor', style: TextStyle(fontSize: 18)))),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. GUARD MODE SCREEN
// ==========================================
/*class GuardScreen extends StatefulWidget {
  final String token;
  const GuardScreen({super.key, required this.token});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  final _approvalIdController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyEntry() async {
    setState(() => _isLoading = true);
    try {
      // Using the saved token for authentication
      final prefs = await SharedPreferences.getInstance();
      final realToken = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:5105/api/visitors/verify-otp'),
        headers: {'Authorization': 'Bearer $realToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'preApprovalId': _approvalIdController.text,
          'otp': _otpController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Visitor allowed inside!'), backgroundColor: Colors.green));
        _approvalIdController.clear();
        _otpController.clear();
      } else {
        _showError('Invalid OTP or ID');
      }
    } catch (e) { _showError('Error: $e'); } finally { setState(() => _isLoading = false); }
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
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('jwt_token');
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, size: 100, color: Colors.orange),
            const SizedBox(height: 30),
            const Text('Verify Visitor Entry', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _approvalIdController, decoration: const InputDecoration(labelText: 'Visitor Approval ID (Guid)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code))),
            const SizedBox(height: 20),
            TextField(controller: _otpController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'Gate OTP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.password))),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyEntry,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ALLOW ENTRY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            )),
          ],
        ),
      ),
    );
  }
}*/

// ==========================================
// 5. GUARD MODE SCREEN (UPDATED WITH EXIT!)
// ==========================================
class GuardScreen extends StatefulWidget {
  final String token;
  const GuardScreen({super.key, required this.token});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  final _approvalIdController = TextEditingController();
  final _otpController = TextEditingController();
  final _exitLogIdController = TextEditingController(); // NEW!
  bool _isLoading = false;

  Future<void> _verifyEntry() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final realToken = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:5105/api/visitors/verify-otp'),
        headers: {'Authorization': 'Bearer $realToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'preApprovalId': _approvalIdController.text,
          'otp': _otpController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Extract the Log ID from the response and auto-fill the exit box!
        final data = jsonDecode(response.body);
        setState(() {
          _exitLogIdController.text = data['visitorId'].toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Visitor allowed inside! (Log ID copied below)'),
          backgroundColor: Colors.green,
        ));
        _approvalIdController.clear();
        _otpController.clear();
      } else {
        _showError('Invalid OTP or ID');
      }
    } catch (e) { _showError('Error: $e'); } finally { setState(() => _isLoading = false); }
  }

  // NEW: Mark Exit Method
  Future<void> _markExit() async {
    if (_exitLogIdController.text.isEmpty) return _showError('Please enter the Log ID');
    
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final realToken = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:5105/api/visitors/mark-exit'),
        headers: {'Authorization': 'Bearer $realToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'logId': _exitLogIdController.text, // The ID we got from the Entry step
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🚪 Visitor marked as exited!'),
          backgroundColor: Colors.red,
        ));
        _exitLogIdController.clear();
      } else {
        _showError('Failed to mark exit');
      }
    } catch (e) { _showError('Error: $e'); } finally { setState(() => _isLoading = false); }
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
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('jwt_token');
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          })
        ],
      ),
      body: SingleChildScrollView( // Added scrollview in case keyboard covers buttons
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Changed to start so we can scroll
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.shield, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text('Verify Visitor Entry', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _approvalIdController, decoration: const InputDecoration(labelText: 'Visitor Approval ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code))),
            const SizedBox(height: 16),
            TextField(controller: _otpController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'Gate OTP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.password))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyEntry,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ALLOW ENTRY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            )),
            
            // ==========================================
            // NEW: MARK EXIT SECTION
            // ==========================================
            const Padding(
              padding: EdgeInsets.only(top: 40, bottom: 20),
              child: Divider(thickness: 2, color: Colors.grey),
            ),
            const Text('Mark Visitor Exit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _exitLogIdController, 
              decoration: const InputDecoration(
                labelText: 'Log ID (Auto-filled after entry)',
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.exit_to_app)
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: _isLoading ? null : _markExit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('MARK EXIT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            )),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. MY DUES SCREEN
// ==========================================
class MyDuesScreen extends StatefulWidget {
  const MyDuesScreen({super.key});

  @override
  State<MyDuesScreen> createState() => _MyDuesScreenState();
}

class _MyDuesScreenState extends State<MyDuesScreen> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;
  String? _token;
  String? _flatId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
      _flatId = prefs.getString('flat_id');
    });

    if (_token == null || _flatId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5107/api/invoices/my-dues?flatId=$_flatId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _invoices = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Helper to format the money nicely
  String _formatAmount(dynamic amount) {
    double amt = double.tryParse(amount.toString()) ?? 0.0;
    return '\₹ ${amt.toStringAsFixed(2)}'; // Rupee symbol
  }

  // Helper to format the status
  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Pending';
      case 1: return 'Paid';
      case 2: return 'Overdue';
      case 3: return 'Waived';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.orange;
      case 1: return Colors.green;
      case 2: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Maintenance Dues'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('jwt_token');
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          })
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(child: Text('No dues found. You are all clear!', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _invoices[index];
                    final status = invoice['status'] is int ? invoice['status'] as int : 0;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(invoice['description'] ?? 'Maintenance', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Due: ${invoice['dueDate'].toString().substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatAmount(invoice['totalAmount']),
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(status),
                                        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                  )],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}