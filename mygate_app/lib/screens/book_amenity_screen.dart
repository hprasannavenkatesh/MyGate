// lib/screens/book_amenity_screen.dart
import 'package:flutter/material.dart';
import '../services/amenity_service.dart';
import '../services/auth_service.dart';

class BookAmenityScreen extends StatefulWidget {
  final String amenityId;
  final String amenityName;
  const BookAmenityScreen({super.key, required this.amenityId, required this.amenityName});

  @override
  State<BookAmenityScreen> createState() => _BookAmenityScreenState();
}

class _BookAmenityScreenState extends State<BookAmenityScreen> {
  DateTime? _selectedDate;
  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  
  int? _selectedSlotIndex; 

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _availableSlots = []; 
        _selectedSlotIndex = null; 
      });
      _fetchSlots(); 
    }
  }

  Future<void> _fetchSlots() async {
    if (_selectedDate == null) return;

    setState(() => _isLoadingSlots = true);
    try {
      final societyId = await AuthService.getSocietyId();
      // FIX: Corrected string interpolation syntax
      final formattedDate = "${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      
      final slots = await AmenityService.getAvailableSlots(
        widget.amenityId, 
        societyId, 
        formattedDate
      );

      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching slots: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedSlotIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a date and a time slot'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isBooking = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final userId = await AuthService.getUserId();
      final flatNumber = await AuthService.getFlatNumber(); // Fetch FlatNumber

      final formattedDate = "${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      final selectedSlot = _availableSlots[_selectedSlotIndex!];

      // FIX: Keys exactly match C# CreateBookingCommand properties
      final isSuccess = await AmenityService.createBooking({
        'amenityId': widget.amenityId,
        'societyId': societyId,
        'userId': userId,
        'flatNumber': flatNumber,          // ADDED
        'bookingDate': formattedDate,       // CHANGED from 'date'
        'startTime': selectedSlot['startTime'], 
        'endTime': selectedSlot['endTime'],     
      });

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Booking Requested!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        throw Exception('Failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateText = _selectedDate == null 
        ? 'Select a Date' 
        : "${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}";

    return Scaffold(
      appBar: AppBar(
        title: Text('Book: ${widget.amenityName}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Booking Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateText, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_selectedDate != null && _availableSlots.isEmpty)
              const Center(
                child: Text('No slots available for this date.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              )
            else if (_availableSlots.isNotEmpty)
              ...[
                const Text('Available Slots:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _availableSlots[index];
                      final isAvailable = slot['isAvailable'] == true;
                      final isSelected = _selectedSlotIndex == index; 
                      
                      return Card(
                        color: isSelected ? Colors.indigo.shade100 : (isAvailable ? Colors.white : Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          side: isSelected ? const BorderSide(color: Colors.indigo, width: 2) : BorderSide.none,
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: ListTile(
                          title: Text('${slot['startTime']} - ${slot['endTime']}'),
                          subtitle: !isAvailable ? const Text('Booked', style: TextStyle(color: Colors.red, fontSize: 12)) : null,
                          trailing: isSelected 
                            ? const Icon(Icons.check_circle, color: Colors.indigo, size: 28) 
                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 28),
                          onTap: isAvailable ? () => setState(() => _selectedSlotIndex = index) : null,
                        ),
                      );
                    },
                  ),
                ),
              ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _submitBooking,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: _isBooking 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Confirm Booking', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}