// lib/screens/admin_billing_screen.dart
import 'package:flutter/material.dart';
import '../../services/billing_service.dart';
import '../../services/auth_service.dart';
import '../../services/tenant_admin_service.dart';

class AdminBillingScreen extends StatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  State<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends State<AdminBillingScreen> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      // FIX: Call Admin endpoint instead of Resident endpoint
      final data = await BillingService.getSocietyInvoices();
      if (mounted) setState(() => _invoices = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
/*
  Future<void> _showGenerateInvoiceDialog() async {
    final amountController = TextEditingController();
    final dueDateController = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T').first);
    final descController = TextEditingController();
    final flatIdController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Generate Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: flatIdController, decoration: const InputDecoration(labelText: 'Flat ID *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: dueDateController, decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD) *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty || flatIdController.text.isEmpty) return;
                
                final societyId = await AuthService.getSocietyId();
              // FIX: Ensure dueDate is formatted as a proper ISO 8601 UTC string for .NET DateTimeOffset parsing
                final rawDate = dueDateController.text.trim();
                final formattedDate = '${rawDate}T00:00:00Z'; 

                final success = await BillingService.generateInvoice({
                  'societyId': societyId,
                  'flatId': flatIdController.text,
                  'amount': double.parse(amountController.text),
                  'dueDate': formattedDate,
                  'description': descController.text,
                });

                if (ctx.mounted) Navigator.pop(ctx);
                if (success) {
                  _fetchInvoices();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Invoice Generated!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      }
    );
  }*/

  Future<void> _showGenerateInvoiceDialog() async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    
    // Dropdowns & Date state
    List<dynamic> blocks = [];
    List<dynamic> flats = [];
    String? selectedBlockId;
    String? selectedFlatId;
    bool isLoadingBlocks = true;
    bool isLoadingFlats = false;
    bool isBulkGeneration = false; // Toggle for all flats
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30)); // Default 30 days out
    String selectedCategory = 'Maintenance'; // Default purpose

    // Fetch blocks
    try {
      final societyId = await AuthService.getSocietyId();
      blocks = await TenantAdminService.getBlocks(societyId);
      isLoadingBlocks = false;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Generate Invoice'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category / Purpose
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: ['Maintenance', 'Water Charges', 'Parking Fee', 'Corpus Fund', 'Penalty', 'Other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      decoration: const InputDecoration(labelText: 'Category / Purpose *', border: OutlineInputBorder()),
                      onChanged: (val) => setDialogState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder(), prefixText: '₹ '),
                    ),
                    const SizedBox(height: 16),

                    // Due Date (Display + Tap to pick)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Due Date *'),
                      subtitle: Text('${selectedDueDate.day.toString().padLeft(2, '0')}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, 
                          initialDate: selectedDueDate, 
                          firstDate: DateTime.now(), 
                          lastDate: DateTime.now().add(const Duration(days: 365))
                        );
                        if (picked != null) setDialogState(() => selectedDueDate = picked);
                      },
                    ),
                    const SizedBox(height: 16),

                    // BULK TOGGLE
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Generate for ALL Flats'),
                      subtitle: const Text('Create this invoice for every flat in the society (Bulk).'),
                      value: isBulkGeneration,
                      onChanged: (val) => setDialogState(() => isBulkGeneration = val),
                    ),
                    const SizedBox(height: 16),

                    // BLOCK & FLAT DROPDOWNS (Only show if NOT Bulk)
                    if (!isBulkGeneration) ...[
                      if (isLoadingBlocks) const Center(child: CircularProgressIndicator())
                      else DropdownButtonFormField<String>(
                        value: selectedBlockId,
                        hint: const Text('Select Block *'),
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
                      if (isLoadingFlats) const Center(child: CircularProgressIndicator())
                      else if (selectedBlockId != null) DropdownButtonFormField<String>(
                        value: selectedFlatId,
                        hint: const Text('Select Flat *'),
                        items: flats.map((f) => DropdownMenuItem<String>(value: f['id'].toString(), child: Text('Flat ${f['flatNumber']}'))).toList(),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        onChanged: (val) => setDialogState(() => selectedFlatId = val),
                      ),
                    ],

                    // Description
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Note (Optional)', border: OutlineInputBorder(), hintText: 'e.g., October Monthly Maintenance'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isEmpty || (!isBulkGeneration && selectedFlatId == null)) return;
                    
                    final societyId = await AuthService.getSocietyId();
                    final dueDateStr = "${selectedDueDate.year.toString().padLeft(4, '0')}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.day.toString().padLeft(2, '0')}";

                    try {
                      if (isBulkGeneration) {
                        // BULK: Call a bulk endpoint (We will define this)
                        final success = await BillingService.bulkGenerateInvoices({
                          'societyId': societyId,
                          'amount': double.parse(amountController.text),
                          'dueDate': dueDateStr,
                          'description': '${selectedCategory} - ${descController.text.trim()}',
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (success && mounted) {
                          _fetchInvoices(); // Refresh list
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Bulk Invoices Generated!'), backgroundColor: Colors.green));
                        }
                      } else {
                        // SINGLE: Call existing single-flat endpoint
                        final success = await BillingService.generateInvoice({
                          'societyId': societyId,
                          'flatId': selectedFlatId!,
                          'amount': double.parse(amountController.text),
                          'dueDate': dueDateStr,
                          'description': '${selectedCategory} - ${descController.text.trim()}',
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (success && mounted) {
                          _fetchInvoices();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Invoice Generated!'), backgroundColor: Colors.green));
                        }
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Pending';
      case 1: return 'Paid';
      case 2: return 'Overdue';
      case 3: return 'Waived';
      case 4: return 'Partially Paid';
      default: return 'Unknown';
    }
  }
  // FIX: Added complete color logic for all invoice states
  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.orange.shade100; // Pending
      case 1: return Colors.green.shade100;  // Paid
      case 2: return Colors.red.shade100;    // Overdue
      case 3: return Colors.grey.shade200;   // Waived
      case 4: return Colors.blue.shade100;   // Partially Paid
      default: return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Invoices')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGenerateInvoiceDialog,
        tooltip: 'Generate Invoice',
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty 
              ? const Center(child: Text('No invoices found.'))
              : ListView.builder(
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final inv = _invoices[index];
                    final status = inv['status'] ?? 0;
                    final penalty = inv['penaltyAmount'] ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('₹${inv['totalAmount']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        //subtitle: Text('${inv['description'] ?? 'Maintenance'}\nDue: ${inv['dueDate']?.substring(0, 10) ?? 'N/A'}'),
                         // FIX: Show penalty amount if it exists
                        subtitle: Text(
                          '${inv['description'] ?? 'Maintenance'}\n'
                          'Due: ${inv['dueDate']?.substring(0, 10) ?? 'N/A'}'
                          '${penalty > 0 ? '\nPenalty: ₹${penalty.toStringAsFixed(2)}' : ''}'
                        ),
                        //isThreeLine: true,
                          isThreeLine: penalty > 0, // Expand card if penalty exists
                        trailing: Chip(
                          label: Text(_getStatusText(inv['status'] ?? 0), style: const TextStyle(fontSize: 12)),
                         //backgroundColor: (inv['status'] == 1) ? Colors.green.shade100 : Colors.orange.shade100,
                         backgroundColor: _getStatusColor(status), 
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}