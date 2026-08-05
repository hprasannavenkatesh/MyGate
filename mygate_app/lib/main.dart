import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
       print('🔍 DEBUG: Trying to fetch societies for User ID: $userId'); // DEBUG LINE
      final response = await http.get(
        Uri.parse('http://localhost:5104/api/societies/my-societies?userId=$userId'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
        print('🔍 DEBUG: API Status Code: ${response.statusCode}'); // DEBUG LINE
      print('🔍 DEBUG: Response Body: ${response.body}'); // DEBUG LINE
      if (response.statusCode == 200) {
        setState(() { _societies = jsonDecode(response.body); _isLoading = false; });
      } else { _showError('Failed to load societies Status: ${response.statusCode}'); }
    } catch (e) {  
      print('🔴 ERROR: $e'); // DEBUG LINE - THIS IS THE MOST IMPORTANT LINE!
    _showError('Error: $e'); setState(() => _isLoading = false); }
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
                        /*onTap: () async {
                          // Save selected flat details locally!
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('society_id', society['societyId']);
                          await prefs.setString('flat_id', society['flatId']);
                          
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                        }*/
                        onTap: () async {
                            print('🟢🟢🟢 FLAT TAPPED! NEW CODE IS RUNNING! 🟢🟢🟢');
                          final prefs = await SharedPreferences.getInstance();
                          final currentToken = prefs.getString('jwt_token') ?? '';
                          final userId = _extractUserId(currentToken); // You already have this helper!

                          try {
                  // 1. CALL THE IDENTITY SERVICE TO GET THE CONTEXT JWT
                  final response = await http.post(
                    Uri.parse('http://localhost:5103/api/auth/select-context'),
                    headers: {'Authorization': 'Bearer $currentToken', 'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'userId': userId,
                      'societyId': society['societyId'],
                      'flatId': society['flatId'],
                      'memberType': society['memberType']
                      //'role': 'Admin' // <--- TEMPORARY: Forces the Admin role for testing
                    }),
                  );

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    final newContextToken = data['token'];

                       print('🔐 NEW CONTEXT TOKEN: $newContextToken'); // <--- THIS IS WHAT WE WANT TO SEE

                    // 2. CRITICAL STEP: OVERWRITE THE OLD TOKEN WITH THE NEW ONE!
                    // This new token now has SocietyId, FlatId, and Role baked inside.
                    await prefs.setString('jwt_token', newContextToken);
                    
                    // 3. Save flat IDs locally for easy access later
                    await prefs.setString('society_id', society['societyId']);
                    await prefs.setString('flat_id', society['flatId']);
                    
                    // 4. Go to Home
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                  } else {
                     print('❌ FAILED TO GET TOKEN. STATUS: ${response.statusCode}'); // <--- ADD THIS TOO
                    _showError('Failed to generate context token');
                  }
                } catch (e) {
                    print('❌ EXCEPTION CAUGHT: $e'); // <--- ADD THIS TOO
                  _showError('Error: $e');
                }
                        }
                        ,
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
              //New: HelpDesk Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyTicketsScreen()));
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('My Support Tickets', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ),
                ),
                //New: NoticeBoard Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeBoardScreen()));
                      },
                      icon: const Icon(Icons.campaign),
                      label: const Text('Notice Board', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    ),
                  ),
                ),

                //New: Amenities Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AmenityListScreen()));
                      },
                      icon: const Icon(Icons.pool),
                      label: const Text('Book Amenities', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    ),
                  ),
                ),

              //New: My Amenity Bookings Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('My Amenity Bookings', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
                    ),
                  ),
                ),

                  //New: My Daily Help Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyDailyHelpScreen()));
                      },
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('My Daily Help', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
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

   // 1. Added this helper for Text
  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Pending';
      case 1: return 'Approved';
      case 2: return 'Rejected';
      case 3: return 'Cancelled';
      case 4: return 'Completed';
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

// ==========================================
// 7. MY TICKETS SCREEN
// ==========================================
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<dynamic> _tickets = [];
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
        Uri.parse('http://localhost:5108/api/tickets/my-tickets?flatId=$_flatId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _tickets = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 0: return Colors.grey;      // Low
      case 1: return Colors.blue;      // Medium
      case 2: return Colors.orange;    // High
      case 3: return Colors.red;       // Critical
      default: return Colors.grey;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 0: return 'Low';
      case 1: return 'Medium';
      case 2: return 'High';
      case 3: return 'Critical';
      default: return 'Unknown';
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Open';
      case 1: return 'In Progress';
      case 2: return 'Resolved';
      case 3: return 'Closed';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Support Tickets'),
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RaiseTicketScreen()));
        },
        icon: const Icon(Icons.add_circle),
        label: const Text('Raise Ticket'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(child: Text('No support tickets raised yet!', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    final status = ticket['status'] is int ? ticket['status'] as int : 0;
                    final priority = ticket['priority'] is int ? ticket['priority'] as int : 0;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.support_agent, color: Colors.blue),
                        title: Text(ticket['title'] ?? 'Ticket', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ticket['category'] != null)
                              Text(ticket['category'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('Raised: ${ticket['createdAt'].toString().substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(priority).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_getPriorityText(priority), style: TextStyle(color: _getPriorityColor(priority), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (status == 2 || status == 3) ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_getStatusText(status), style: TextStyle(color: (status == 2 || status == 3) ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context,MaterialPageRoute(
                            builder: (context) => TicketDetailScreen(ticketId: ticket['id'].toString()),
                          ));

                        }
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================================
// 8. RAISE TICKET SCREEN
// ==========================================
class RaiseTicketScreen extends StatefulWidget {
  const RaiseTicketScreen({super.key});

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  
  int _selectedPriority = 1; // Default to Medium
  bool _isLoading = false;

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final realToken = prefs.getString('jwt_token') ?? '';
      final realSocietyId = prefs.getString('society_id') ?? '';
      final realFlatId = prefs.getString('flat_id') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:5108/api/tickets/raise'),
        headers: {'Authorization': 'Bearer $realToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'societyId': realSocietyId,
          'flatId': realFlatId,
          'title': _titleController.text,
          'description': _descController.text,
          'category': _categoryController.text,
          'priority': _selectedPriority
        }),
      );
       print('🔍 DEBUG: API Status Code: ${response.statusCode}'); // DEBUG LINE
      print('🔍 DEBUG: Response Body: ${response.body}'); // DEBUG LINE

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Ticket submitted successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        _showError('Failed to submit ticket');
      }
    } catch (e) { 
       print('🔴 ERROR: $e'); // DEBUG LINE - THIS IS THE MOST IMPORTANT LINE!
       _showError('Error: $e'); } finally { setState(() => _isLoading = false); }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raise Support Ticket'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Subject / Title *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                validator: (val) => val!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe your issue in detail *',
                  
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.description),
                  hintText: "E.g., The water pressure in Block A is very low today...",
                ),
                validator: (val) => val!.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category (e.g., Plumbing, Electrical)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField(
                value: _selectedPriority,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Low Priority')),
                  DropdownMenuItem(value: 1, child: Text('Medium Priority (Default)')),
                  DropdownMenuItem(value: 2, child: Text('High Priority')),
                  DropdownMenuItem(value: 3, child: Text('Critical Priority')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Priority *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onChanged: (val) => setState(() => _selectedPriority = val!),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Ticket', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 9. TICKET DETAIL SCREEN (Chat View)
// ==========================================
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? _ticket;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5108/api/tickets/${widget.ticketId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ticket = data;
          _comments = data['comments'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    try {
      await http.post(
        Uri.parse('http://localhost:5108/api/tickets/${widget.ticketId}/comments'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'commentText': _commentController.text,
          'isAdminComment': false, // Resident is posting
        }),
      );

      _commentController.clear();
      _fetchDetails(); // Refresh screen to show new comment
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to comment: $e')));
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Open';
      case 1: return 'In Progress';
      case 2: return 'Resolved';
      case 3: return 'Closed';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket?['title'] ?? 'Ticket Details'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ticket Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${_getStatusText(_ticket?['status'] ?? 0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 8),
                      Text(_ticket?['description'] ?? '', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                
                // Comments List
                Expanded(
                  child: _comments.isEmpty
                      ? const Center(child: Text('No comments yet. Wait for admin to respond.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            bool isAdmin = c['isAdminComment'] == true;
                            
                            return Align(
                              alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isAdmin ? Colors.blue.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isAdmin ? '👨‍💼 Admin' : '👤 You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAdmin ? Colors.blue : Colors.orange)),
                                    Text(c['commentText'], style: const TextStyle(fontSize: 14)),
                                    Text(c['createdAt'].toString().substring(0, 16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Comment Input
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _postComment,
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}

// ==========================================
// 9. NOTICE BOARD SCREEN
// ==========================================
class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  List<dynamic> _notices = [];
  bool _isLoading = true;
  String? _token;
  String? _societyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
      _societyId = prefs.getString('society_id');
    });

    if (_token == null || _societyId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5109/api/notices?societyId=$_societyId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _notices = jsonDecode(response.body);
          _isLoading = false;
        });
      }else {
        // ADDED: This handles 400, 401, 404, 500 errors!
        print('❌ NoticeBoard API Error: ${response.statusCode} - ${response.body}');
        setState(() => _isLoading = false); // Stop the spinner!
      }
    } catch (e) {
          print('❌ NoticeBoard Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(int category) {
    switch (category) {
      case 1: return Icons.build; // Maintenance
      case 2: return Icons.event; // Event
      case 3: return Icons.warning; // Emergency
      case 4: return Icons.gavel; // Rules
      default: return Icons.notifications_active; // General
    }
  }

  Color _getCategoryColor(int category) {
    switch (category) {
      case 1: return Colors.orange;
      case 2: return Colors.purple;
      case 3: return Colors.red;
      case 4: return Colors.blueGrey;
      default: return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Notice Board'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? const Center(child: Text('No notices posted yet.', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _notices.length,
                  itemBuilder: (context, index) {
                    final notice = _notices[index];
                    final isPinned = notice['isPinned'] == true;
                    final category = notice['category'] is int ? notice['category'] as int : 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isPinned ? Colors.amber.shade50 : Colors.white,
                      elevation: isPinned ? 4 : 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(_getCategoryIcon(category), color: _getCategoryColor(category)),
                                const SizedBox(width: 10),
                                if (isPinned) 
                                  const Icon(Icons.push_pin, color: Colors.red, size: 18),
                                const Spacer(),
                                Text(
                                  notice['createdAt'].toString().substring(0, 10),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              notice['title'], 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notice['description'],
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================================
// 8. AMENITY LIST SCREEN
// ==========================================
class AmenityListScreen extends StatefulWidget {
  const AmenityListScreen({super.key});

  @override
  State<AmenityListScreen> createState() => _AmenityListScreenState();
}

class _AmenityListScreenState extends State<AmenityListScreen> {
  List<dynamic> _amenities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAmenities();
  }

  Future<void> _fetchAmenities() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final societyId = prefs.getString('society_id');

    if (token == null || societyId == null) {
      setState(() => _isLoading = false);
       print('❌ AMENITY DEBUG - Missing token or society ID! Did you log out and log back in?');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5110/api/Amenities/society/$societyId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
     print('🔍 AMENITY DEBUG - Calling URL: http://localhost:5110/api/Amenities/society/$societyId');

     // DEBUG 2: Check API response
      print('🔍 AMENITY DEBUG - Status Code: ${response.statusCode}');
      print('🔍 AMENITY DEBUG - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _amenities = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
       print('❌ AMENITY DEBUG - Exception caught: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Amenity'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _amenities.isEmpty
              ? const Center(child: Text('No amenities available.', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _amenities.length,
                  itemBuilder: (context, index) {
                    final a = _amenities[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.sports_tennis, color: Colors.indigo, size: 40),
                        title: Text(a['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${a['location'] ?? "No location"} • ${a['slotDurationMinutes']} mins'),
                        trailing: a['isBookable']
                            ? const Icon(Icons.arrow_forward_ios, size: 16)
                            : const Text('Not Bookable', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        onTap: a['isBookable']
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SlotSelectionScreen(
                                      amenityId: a['id'],
                                      amenityName: a['name'],
                                      advanceDays: a['advanceBookingDaysAllowed'] ?? 7,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================================
// 9. SLOT SELECTION & BOOKING SCREEN
// ==========================================
class SlotSelectionScreen extends StatefulWidget {
  final String amenityId;
  final String amenityName;
  final int advanceDays;

  const SlotSelectionScreen({
    super.key,
    required this.amenityId,
    required this.amenityName,
    required this.advanceDays,
  });

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  List<dynamic> _slots = [];
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final societyId = prefs.getString('society_id');

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await http.get(
        Uri.parse('http://localhost:5110/api/Bookings/slots/available?amenityId=${widget.amenityId}&societyId=$societyId&date=$formattedDate'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() => _slots = jsonDecode(response.body));
      }
    } catch (e) {
      // Handle error silently or show snackbar
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bookSlot(Map<String, dynamic> slot) async {
    setState(() => _isBooking = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final societyId = prefs.getString('society_id');
    final flatId = prefs.getString('flat_id');

    // Extract flat number from flatId for the payload (assuming flatId is just the number or we send flatId)
    //String flatNumber = flatId ?? 'Unknown';
     // Using a dummy value for now to bypass the DB length limit.
    String flatNumber = "B-204"; 

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await http.post(
        Uri.parse('http://localhost:5110/api/Bookings'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'amenityId': widget.amenityId,
          'societyId': societyId,
          'userId': '00000000-0000-0000-0000-000000000000', // Backend overrides this
          'flatNumber': flatNumber,
          'bookingDate': formattedDate,
          'startTime': slot['startTime'],
          'endTime': slot['endTime'],
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Amenity Booked Successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back to Amenity List
        }
      } else {
        // Extract error from FluentValidation
        final errorData = jsonDecode(response.body);
        String errorMsg = 'Failed to book';
        if (errorData['errors'] != null) {
          errorMsg = errorData['errors'].values.first.first;
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.amenityName), centerTitle: true),
      body: Column(
        children: [
          // Date Picker Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: widget.advanceDays)),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() => _selectedDate = picked);
                      _fetchSlots();
                    }
                  },
                  child: const Text('Change Date'),
                ),
              ],
            ),
          ),
          
          // Slots List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _slots.isEmpty
                    ? const Center(child: Text('No slots available for this date.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _slots.length,
                        itemBuilder: (context, index) {
                          final slot = _slots[index];
                          bool isAvailable = slot['isAvailable'] == true;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            color: isAvailable ? Colors.white : Colors.grey.shade200,
                            child: ListTile(
                              title: Text('${slot['startTime']} - ${slot['endTime']}'),
                              trailing: isAvailable
                                  ? _isBooking
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton(
                                          onPressed: () => _bookSlot(slot),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                                          child: const Text('Book'),
                                        )
                                  : const Text('Booked', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}
// ==========================================
// 10. MY AMENITY BOOKINGS SCREEN
// ==========================================
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final societyId = prefs.getString('society_id');

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5110/api/Bookings/my-bookings?societyId=$societyId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _bookings = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId, String societyId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.put(
        Uri.parse('http://localhost:5110/api/Bookings/$bookingId/cancel?societyId=$societyId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Cancelled!'), backgroundColor: Colors.orange));
        _fetchBookings(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Pending';
      case 1: return 'Approved';
      case 2: return 'Rejected';
      case 3: return 'Cancelled';
      case 4: return 'Completed';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.orange;
      case 1: return Colors.green;
      case 2: return Colors.red;
      case 3: return Colors.grey;
      case 4: return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Amenity Bookings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text('No bookings made yet.', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final b = _bookings[index];
                    final status = b['status'] is int ? b['status'] as int : 0;
                    bool canCancel = (status == 0 || status == 1);

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
                                      Text(b['amenityName'] ?? 'Amenity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('${b['bookingDate']} • ${b['startTime']} - ${b['endTime']}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                      if (b['rejectionReason'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text('Reason: ${b['rejectionReason']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
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
                                ),
                              ],
                            ),
                            if (canCancel)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _cancelBooking(b['id'], b['societyId']),
                                  child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================================
// 11. MY DAILY HELP SCREEN
// ==========================================
class MyDailyHelpScreen extends StatefulWidget {
  const MyDailyHelpScreen({super.key});

  @override
  State<MyDailyHelpScreen> createState() => _MyDailyHelpScreenState();
}

class _MyDailyHelpScreenState extends State<MyDailyHelpScreen> {
  List<dynamic> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final flatId = prefs.getString('flat_id');

    if (token == null || flatId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5111/api/Assignments/my-help?flatId=$flatId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _assignments = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Helper to format the working days nicely
  String _formatDays(String days) {
    if (days.isEmpty) return 'No days set';
    // Just capitalize the first letter of each day for now
    return days.split(',').map((d) => d.trim()).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Daily Help'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? const Center(
                  child: Text(
                    'No daily help assigned to your flat yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final a = _assignments[index];
                    final isActive = a['isActive'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isActive ? Colors.white : Colors.grey.shade200,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left Side: Type & Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.lightGreen.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              a['helpTypeName'] ?? 'Help',
                                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            a['staffName'] ?? 'Unknown',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Mobile Number
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(a['staffMobile'] ?? 'No number', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Right Side: Status
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Bottom Section: Days & Timings
                            Row(
                              children: [
                                // Working Days
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Working Days', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(_formatDays(a['workingDays'] ?? ''), style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                // Timings
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Timings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${a['inTime'] ?? '--:--'} - ${a['outTime'] ?? '--:--'}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}