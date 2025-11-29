import '../db/doctor_db.dart';

class SearchResult {

  SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.date,
    this.data,
  });
  final String type; // 'patient', 'appointment', 'prescription', 'invoice'
  final int id;
  final String title;
  final String subtitle;
  final DateTime? date;
  final dynamic data;
}

class SearchService {

  SearchService(this.db);
  final DoctorDatabase db;

  Future<List<SearchResult>> search(String query) async {
    if (query.isEmpty) return [];

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    // Search patients
    final patients = await db.getAllPatients();
    for (final patient in patients) {
      final fullName = '${patient.firstName} ${patient.lastName}'.toLowerCase();
      if (fullName.contains(lowerQuery) ||
          patient.phone.toLowerCase().contains(lowerQuery) ||
          patient.email.toLowerCase().contains(lowerQuery) ||
          patient.address.toLowerCase().contains(lowerQuery) ||
          patient.tags.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          type: 'patient',
          id: patient.id,
          title: '${patient.firstName} ${patient.lastName}',
          subtitle: patient.phone.isNotEmpty ? patient.phone : patient.email,
          data: patient,
        ),);
      }
    }

    // Search appointments
    final appointments = await db.select(db.appointments).get();
    for (final appt in appointments) {
      if (appt.reason.toLowerCase().contains(lowerQuery) ||
          appt.notes.toLowerCase().contains(lowerQuery)) {
        final patient = await db.getPatientById(appt.patientId);
        results.add(SearchResult(
          type: 'appointment',
          id: appt.id,
          title: patient != null 
              ? '${patient.firstName} ${patient.lastName}' 
              : 'Appointment #${appt.id}',
          subtitle: appt.reason.isNotEmpty ? appt.reason : 'General Checkup',
          date: appt.appointmentDateTime,
          data: appt,
        ),);
      }
    }

    // Search prescriptions
    final prescriptions = await db.select(db.prescriptions).get();
    for (final rx in prescriptions) {
      if (rx.itemsJson.toLowerCase().contains(lowerQuery) ||
          rx.instructions.toLowerCase().contains(lowerQuery)) {
        final patient = await db.getPatientById(rx.patientId);
        results.add(SearchResult(
          type: 'prescription',
          id: rx.id,
          title: patient != null 
              ? '${patient.firstName} ${patient.lastName}' 
              : 'Prescription #${rx.id}',
          subtitle: 'Rx #${rx.id}',
          date: rx.createdAt,
          data: rx,
        ),);
      }
    }

    // Search invoices
    final invoices = await db.getAllInvoices();
    for (final inv in invoices) {
      if (inv.invoiceNumber.toLowerCase().contains(lowerQuery) ||
          inv.itemsJson.toLowerCase().contains(lowerQuery)) {
        final patient = await db.getPatientById(inv.patientId);
        results.add(SearchResult(
          type: 'invoice',
          id: inv.id,
          title: inv.invoiceNumber,
          subtitle: patient != null 
              ? '${patient.firstName} ${patient.lastName}' 
              : 'Rs. ${inv.grandTotal.toStringAsFixed(0)}',
          date: inv.invoiceDate,
          data: inv,
        ),);
      }
    }

    // Sort by relevance (exact matches first)
    results.sort((a, b) {
      final aExact = a.title.toLowerCase().startsWith(lowerQuery) ? 0 : 1;
      final bExact = b.title.toLowerCase().startsWith(lowerQuery) ? 0 : 1;
      return aExact.compareTo(bExact);
    });

    return results.take(20).toList();
  }
}
