import 'package:flutter/material.dart';
import '../../services/amenity_service.dart';
import '../../services/auth_service.dart';

class AdminAmenityScreen extends StatefulWidget {
  const AdminAmenityScreen({super.key});

  @override
  State<AdminAmenityScreen> createState() => _AdminAmenityScreenState();
}

class _AdminAmenityScreenState extends State<AdminAmenityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _amenities = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _slotDurationController = TextEditingController(text: '60');
  final _startTimeController = TextEditingController(text: '06:00');
  final _endTimeController = TextEditingController(text: '22:00');

  List<dynamic> _pendingBookings = [];
  bool _isLoadingBookings = true;

  @override
  void initState() {
   _tabController = TabController(length: 2, vsync: this);
    _fetchAmenities();
    _fetchPendingBookings();
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAmenities() async {
    setState(() => _isLoading = true);
    // setState(() => _isLoadingAmenities = true);
    try {
      final data = await AmenityService.getAmenities();
      if (mounted) setState(() => _amenities = data);
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

  Future<void> _showCreateAmenityDialog() async {
    _nameController.clear();
    _locationController.clear();
    _slotDurationController.text = '60';
    _startTimeController.text = '06:00';
    _endTimeController.text = '22:00';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Amenity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _slotDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Slot Duration (mins)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(labelText: 'Start (HH:mm)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(labelText: 'End (HH:mm)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) return;

                final societyId = await AuthService.getSocietyId();

                final payload = {
                  'societyId': societyId,
                  'name': _nameController.text.trim(),
                  'location': _locationController.text.trim(),
                  'isBookable': true,
                  'slotDurationMinutes': int.tryParse(_slotDurationController.text) ?? 60,
                  'maxBookingsPerDayPerUser': 1,
                  'advanceBookingDaysAllowed': 7,
                  'operatingHoursStart': _startTimeController.text,
                  'operatingHoursEnd': _endTimeController.text,
                };

                final success = await AmenityService.createAmenity(payload);

                if (ctx.mounted) Navigator.pop(ctx);
                
                if (success) {
                  _fetchAmenities();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Amenity Created!'), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create amenity.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

   // ==========================================
  // NEW: PENDING BOOKINGS LOGIC
  // ==========================================
  Future<void> _fetchPendingBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      final data = await AmenityService.getPendingBookings();
      if (mounted) setState(() => _pendingBookings = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingBookings = false);
    }
  }

  Future<void> _handleApproval(String bookingId, bool isApprove, {String? reason}) async {
    try {
      final societyId = await AuthService.getSocietyId();
      bool success;

      if (isApprove) {
        success = await AmenityService.approveBooking(bookingId, societyId);
      } else {
        success = await AmenityService.rejectBooking(bookingId, societyId, reason ?? 'Rejected by Admin');
      }

      if (success) {
        _fetchPendingBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isApprove ? '✅ Booking Approved!' : '❌ Booking Rejected!'), 
              backgroundColor: isApprove ? Colors.green : Colors.red
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRejectDialog(String bookingId) async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for rejection', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleApproval(bookingId, false, reason: reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD METHOD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amenity Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pool), text: 'Amenities'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending Approvals'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton(
        onPressed: _showCreateAmenityDialog,
        tooltip: 'Create Amenity',
        child: const Icon(Icons.add),
      ) : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: EXISTING AMENITY CONFIG LIST
          //_isLoadingAmenities
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _amenities.isEmpty
                  ? const Center(child: Text('No amenities found.'))
                  : ListView.builder(
                      itemCount: _amenities.length,
                      itemBuilder: (context, index) {
                        final a = _amenities[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        a['name'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    if (a['isBookable'] == true)
                                      const Icon(Icons.book_online, color: Colors.blue, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (a['location'] != null) Text('Location: ${a['location']}'),
                                Text('Slot Duration: ${a['slotDurationMinutes'] ?? 'N/A'} mins'),
                                Text('Hours: ${a['operatingHoursStart'] ?? 'N/A'} - ${a['operatingHoursEnd'] ?? 'N/A'}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

          // TAB 2: NEW PENDING BOOKINGS LIST
          _isLoadingBookings
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchPendingBookings,
                  child: _pendingBookings.isEmpty
                      ? const Center(child: Text('No pending booking requests.'))
                      : ListView.builder(
                          itemCount: _pendingBookings.length,
                          itemBuilder: (context, index) {
                            final b = _pendingBookings[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b['amenityName'] ?? 'Amenity',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Resident Flat: ${b['flatNumber'] ?? 'N/A'}'),
                                    Text('Date: ${b['bookingDate'] ?? 'N/A'} | ${b['startTime'] ?? ''} - ${b['endTime'] ?? ''}'),
                                    if (b['notes'] != null && (b['notes'] as String).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text('Note: ${b['notes']}', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                                      ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showRejectDialog(b['id']),
                                          icon: const Icon(Icons.cancel, size: 18),
                                          label: const Text('Reject'),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _handleApproval(b['id'], true),
                                          icon: const Icon(Icons.check_circle, size: 18),
                                          label: const Text('Approve'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        ),
                                      ],
                                    )
                                  ],
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