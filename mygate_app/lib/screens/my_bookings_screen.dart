// lib/screens/my_bookings_screen.dart
import 'package:flutter/material.dart';
import '../services/amenity_service.dart';

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
    try {
      final bookings = await AmenityService.getMyBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId, String societyId) async {
    try {
      final isSuccess = await AmenityService.cancelBooking(bookingId, societyId);
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Cancelled!'), backgroundColor: Colors.orange));
        _fetchBookings(); 
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