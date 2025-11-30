import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Data Export Service
/// Provides comprehensive data export functionality with PDF, Excel, and CSV support
/// for patient records, appointments, billing, and analytics
class DataExportService {
  // Export format types
  static const String formatPDF = 'pdf';
  static const String formatCSV = 'csv';
  static const String formatJSON = 'json';

  // Report types
  static const String reportPatients = 'patients';
  static const String reportAppointments = 'appointments';
  static const String reportBilling = 'billing';
  static const String reportPrescriptions = 'prescriptions';
  static const String reportAnalytics = 'analytics';

  /// Generate patient report as PDF
  Future<Uint8List> generatePatientReportPDF({
    required String patientId,
    required String patientName,
    required Map<String, dynamic> patientData,
    required List<Map<String, dynamic>> medicalRecords,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Patient Report',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Header(
            level: 1,
            child: pw.Text(
              'Patient Information',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          _buildPatientInfoTable(patientName, patientData),
          pw.SizedBox(height: 20),
          pw.Header(
            level: 1,
            child: pw.Text(
              'Medical Records',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (medicalRecords.isNotEmpty)
            _buildMedicalRecordsTable(medicalRecords)
          else
            pw.Text('No medical records available'),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate appointment report as PDF
  Future<Uint8List> generateAppointmentReportPDF({
    required List<Map<String, dynamic>> appointments,
    required String dateFrom,
    required String dateTo,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Appointment Report',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Period: $dateFrom to $dateTo',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Header(
            level: 1,
            child: pw.Text(
              'Appointments Summary',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text('Total Appointments: ${appointments.length}'),
          pw.SizedBox(height: 12),
          if (appointments.isNotEmpty)
            _buildAppointmentsTable(appointments)
          else
            pw.Text('No appointments in selected period'),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate billing report as PDF
  Future<Uint8List> generateBillingReportPDF({
    required List<Map<String, dynamic>> invoices,
    required double totalAmount,
    required double paidAmount,
    required double pendingAmount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Billing Report',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Header(
            level: 1,
            child: pw.Text(
              'Financial Summary',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Total Amount',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$$totalAmount'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Paid Amount',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$$paidAmount'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Pending Amount',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$$pendingAmount'),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Header(
            level: 1,
            child: pw.Text(
              'Invoices',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (invoices.isNotEmpty)
            _buildInvoicesTable(invoices)
          else
            pw.Text('No invoices available'),
        ],
      ),
    );

    return pdf.save();
  }

  /// Export data as CSV
  String exportAsCSV({
    required String reportType,
    required List<Map<String, dynamic>> data,
  }) {
    if (data.isEmpty) {
      return 'No data to export';
    }

    // Get headers from first row
    final headers = data.first.keys.toList();
    final csv = StringBuffer();

    // Add header row
    csv.writeln(headers.map((h) => '"$h"').join(','));

    // Add data rows
    for (final row in data) {
      final values = headers.map((h) {
        final value = row[h] ?? '';
        return '"$value"';
      });
      csv.writeln(values.join(','));
    }

    return csv.toString();
  }

  /// Export data as JSON
  String exportAsJSON({
    required String reportType,
    required List<Map<String, dynamic>> data,
  }) {
    final jsonArray = data.map((item) => item).toList();
    return _prettyPrintJSON(jsonArray);
  }

  /// Generate analytics summary
  Map<String, dynamic> generateAnalyticsSummary({
    required int totalPatients,
    required int activePatients,
    required int totalAppointments,
    required int completedAppointments,
    required double totalRevenue,
    required double averagePatientRating,
  }) {
    return {
      'summary': {
        'generatedDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'totalPatients': totalPatients,
        'activePatients': activePatients,
        'totalAppointments': totalAppointments,
        'completedAppointments': completedAppointments,
        'totalRevenue': totalRevenue,
        'averagePatientRating': averagePatientRating,
      },
      'metrics': {
        'appointmentCompletionRate':
            totalAppointments > 0 ? (completedAppointments / totalAppointments) : 0,
        'activePatientPercentage':
            totalPatients > 0 ? (activePatients / totalPatients) : 0,
        'averageRevenuePerPatient':
            totalPatients > 0 ? (totalRevenue / totalPatients) : 0,
      },
    };
  }

  /// Helper: Build patient info table
  pw.Widget _buildPatientInfoTable(
    String patientName,
    Map<String, dynamic> patientData,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Patient Name',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(patientName),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Patient ID',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(patientData['patientId']?.toString() ?? 'N/A'),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Email',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(patientData['email']?.toString() ?? 'N/A'),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Phone',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(patientData['phone']?.toString() ?? 'N/A'),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper: Build medical records table
  pw.Widget _buildMedicalRecordsTable(List<Map<String, dynamic>> records) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Date',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Type',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Notes',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        ...records.map((record) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(record['date']?.toString() ?? 'N/A'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(record['type']?.toString() ?? 'N/A'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(record['notes']?.toString() ?? 'N/A'),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Helper: Build appointments table
  pw.Widget _buildAppointmentsTable(List<Map<String, dynamic>> appointments) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Patient',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Date',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Status',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        ...appointments.map((apt) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(apt['patientName']?.toString() ?? 'N/A'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(apt['dateTime']?.toString() ?? 'N/A'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(apt['status']?.toString() ?? 'N/A'),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Helper: Build invoices table
  pw.Widget _buildInvoicesTable(List<Map<String, dynamic>> invoices) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Invoice ID',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Patient',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Amount',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Status',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        ...invoices.map((inv) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(inv['invoiceId']?.toString() ?? 'N/A'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(inv['patientName']?.toString() ?? 'N/A'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('\$${inv['amount']}'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(inv['status']?.toString() ?? 'N/A'),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Pretty print JSON
  String _prettyPrintJSON(dynamic json) {
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
