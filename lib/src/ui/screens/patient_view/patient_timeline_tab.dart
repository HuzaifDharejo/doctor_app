import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../encounter_screen.dart';
import '../prescriptions_screen.dart';
import '../medical_record_detail_screen.dart';
import '../invoice_detail_screen.dart';

/// Unified timeline view showing all patient activities
class PatientTimelineTab extends ConsumerStatefulWidget {
  const PatientTimelineTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  ConsumerState<PatientTimelineTab> createState() => _PatientTimelineTabState();
}

class _PatientTimelineTabState extends ConsumerState<PatientTimelineTab> {
  String _filter = 'all'; // 'all', 'appointments', 'prescriptions', 'records', 'vitals', 'invoices'
  
  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return dbAsync.when(
      data: (db) => _buildTimeline(context, db, isDark),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
  
  Widget _buildTimeline(BuildContext context, DoctorDatabase db, bool isDark) {
    return FutureBuilder<List<_TimelineEvent>>(
      future: _loadTimelineEvents(db),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        var events = snapshot.data!;
        
        // Apply filter
        if (_filter != 'all') {
          events = events.where((e) => e.type == _filter).toList();
        }
        
        if (events.isEmpty) {
          return _buildEmptyState(isDark);
        }
        
        return Column(
          children: [
            // Filter chips
            _buildFilterChips(isDark),
            
            // Timeline list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isFirst = index == 0;
                  final isLast = index == events.length - 1;
                  
                  // Group header for date changes
                  Widget? dateHeader;
                  if (isFirst || !_isSameDay(events[index - 1].dateTime, event.dateTime)) {
                    dateHeader = _buildDateHeader(event.dateTime, isDark);
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dateHeader != null) dateHeader,
                      _buildTimelineItem(context, db, event, isFirst, isLast, isDark),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildFilterChips(bool isDark) {
    final filters = [
      ('all', 'All', Icons.timeline),
      ('appointments', 'Appointments', Icons.event),
      ('encounters', 'Visits', Icons.medical_services),
      ('prescriptions', 'Prescriptions', Icons.medication),
      ('records', 'Records', Icons.folder),
      ('vitals', 'Vitals', Icons.favorite),
      ('invoices', 'Invoices', Icons.receipt),
    ];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.$3, size: 16),
                  const SizedBox(width: 4),
                  Text(f.$2),
                ],
              ),
              onSelected: (_) => setState(() => _filter = f.$1),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildDateHeader(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    
    String label;
    if (eventDate == today) {
      label = 'Today';
    } else if (eventDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else if (date.year == now.year) {
      label = DateFormat('EEEE, MMMM d').format(date);
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
  
  Widget _buildTimelineItem(
    BuildContext context,
    DoctorDatabase db,
    _TimelineEvent event,
    bool isFirst,
    bool isLast,
    bool isDark,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  DateFormat('h:mm').format(event.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  DateFormat('a').format(event.dateTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          
          // Line and dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: event.color.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Content card
          Expanded(
            child: GestureDetector(
              onTap: () => _onEventTap(context, db, event),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: event.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: event.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(event.icon, size: 16, color: event.color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                event.typeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: event.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                      ],
                    ),
                    if (event.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (event.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: event.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: event.color,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patient history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<List<_TimelineEvent>> _loadTimelineEvents(DoctorDatabase db) async {
    final events = <_TimelineEvent>[];
    final patientId = widget.patient.id;
    
    // Load appointments
    final appointments = await db.getAppointmentsForPatient(patientId);
    for (final appt in appointments) {
      events.add(_TimelineEvent(
        type: 'appointments',
        typeLabel: 'Appointment',
        dateTime: appt.appointmentDateTime,
        title: appt.reason.isNotEmpty ? appt.reason : 'General Checkup',
        subtitle: '${appt.durationMinutes} min • ${appt.status}',
        icon: Icons.event,
        color: AppColors.appointments,
        tags: [appt.status],
        id: appt.id,
        data: appt,
      ));
    }
    
    // Load encounters (shown as visits)
    final encounters = await db.getEncountersForPatient(patientId);
    for (final enc in encounters) {
      events.add(_TimelineEvent(
        type: 'encounters',
        typeLabel: 'Visit',
        dateTime: enc.encounterDate,
        title: enc.chiefComplaint.isNotEmpty ? enc.chiefComplaint : 'Clinical Visit',
        subtitle: '${enc.encounterType} • ${enc.status}',
        icon: Icons.medical_services,
        color: const Color(0xFFEC4899),
        tags: [enc.encounterType, enc.status],
        id: enc.id,
        data: enc,
      ));
    }
    
    // Load prescriptions
    final prescriptions = await db.getPrescriptionsForPatient(patientId);
    for (final rx in prescriptions) {
      events.add(_TimelineEvent(
        type: 'prescriptions',
        typeLabel: 'Prescription',
        dateTime: rx.createdAt,
        title: 'Prescription #${rx.id}',
        subtitle: rx.instructions.isNotEmpty ? rx.instructions : 'View medications',
        icon: Icons.medication,
        color: AppColors.prescriptions,
        tags: rx.isRefillable ? ['Refillable'] : [],
        id: rx.id,
        data: rx,
      ));
    }
    
    // Load medical records
    final records = await db.getMedicalRecordsForPatient(patientId);
    for (final rec in records) {
      events.add(_TimelineEvent(
        type: 'records',
        typeLabel: rec.recordType.replaceAll('_', ' ').toUpperCase(),
        dateTime: rec.recordDate,
        title: rec.title,
        subtitle: rec.description.isNotEmpty ? rec.description : rec.diagnosis,
        icon: _getRecordIcon(rec.recordType),
        color: _getRecordColor(rec.recordType),
        tags: [rec.recordType],
        id: rec.id,
        data: rec,
      ));
    }
    
    // Load vitals
    final vitals = await db.getVitalSignsForPatient(patientId);
    for (final vital in vitals) {
      final vitalSummary = <String>[];
      if (vital.systolicBp != null && vital.diastolicBp != null) {
        vitalSummary.add('BP: ${vital.systolicBp!.toInt()}/${vital.diastolicBp!.toInt()}');
      }
      if (vital.heartRate != null) {
        vitalSummary.add('HR: ${vital.heartRate} bpm');
      }
      if (vital.temperature != null) {
        vitalSummary.add('Temp: ${vital.temperature}°C');
      }
      
      events.add(_TimelineEvent(
        type: 'vitals',
        typeLabel: 'Vital Signs',
        dateTime: vital.recordedAt,
        title: 'Vitals Recorded',
        subtitle: vitalSummary.join(' • '),
        icon: Icons.favorite,
        color: AppColors.error,
        tags: [],
        id: vital.id,
        data: vital,
      ));
    }
    
    // Load invoices
    final invoices = await db.getInvoicesForPatient(patientId);
    for (final inv in invoices) {
      events.add(_TimelineEvent(
        type: 'invoices',
        typeLabel: 'Invoice',
        dateTime: inv.invoiceDate,
        title: 'Invoice ${inv.invoiceNumber}',
        subtitle: 'Rs. ${inv.grandTotal.toStringAsFixed(0)} • ${inv.paymentStatus}',
        icon: Icons.receipt,
        color: AppColors.billing,
        tags: [inv.paymentStatus],
        id: inv.id,
        data: inv,
      ));
    }
    
    // Sort by date descending (newest first)
    events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    return events;
  }
  
  IconData _getRecordIcon(String recordType) {
    switch (recordType) {
      case 'lab_result':
        return Icons.science;
      case 'imaging':
        return Icons.image;
      case 'procedure':
        return Icons.healing;
      case 'psychiatric_assessment':
        return Icons.psychology;
      default:
        return Icons.folder;
    }
  }
  
  Color _getRecordColor(String recordType) {
    switch (recordType) {
      case 'lab_result':
        return const Color(0xFF0EA5E9);
      case 'imaging':
        return const Color(0xFF8B5CF6);
      case 'procedure':
        return const Color(0xFFEF4444);
      case 'psychiatric_assessment':
        return const Color(0xFF6366F1);
      default:
        return AppColors.primary;
    }
  }
  
  void _onEventTap(BuildContext context, DoctorDatabase db, _TimelineEvent event) {
    switch (event.type) {
      case 'encounters':
        final encounter = event.data as Encounter;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EncounterScreen(
              encounterId: encounter.id,
              patient: widget.patient,
            ),
          ),
        );
        break;
      case 'prescriptions':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PrescriptionsScreen(),
          ),
        );
        break;
      case 'records':
        final record = event.data as MedicalRecord;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicalRecordDetailScreen(
              record: record,
              patient: widget.patient,
            ),
          ),
        );
        break;
      case 'invoices':
        final invoice = event.data as Invoice;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoice: invoice),
          ),
        );
        break;
      default:
        // Show details in a bottom sheet
        _showEventDetails(context, event);
    }
  }
  
  void _showEventDetails(BuildContext context, _TimelineEvent event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(event.icon, color: event.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        event.typeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: event.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(event.dateTime)}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              'Time: ${DateFormat('h:mm a').format(event.dateTime)}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            if (event.subtitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                event.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _TimelineEvent {
  final String type;
  final String typeLabel;
  final DateTime dateTime;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> tags;
  final int id;
  final dynamic data;
  
  _TimelineEvent({
    required this.type,
    required this.typeLabel,
    required this.dateTime,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tags,
    required this.id,
    required this.data,
  });
}
