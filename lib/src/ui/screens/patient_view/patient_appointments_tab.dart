// Patient View - Appointments Tab
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../add_appointment_screen.dart';
import 'patient_view_widgets.dart';

class PatientAppointmentsTab extends ConsumerWidget {
  const PatientAppointmentsTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Appointment>>(
        future: _getPatientAppointments(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return PatientTabEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Appointments',
              subtitle: 'Schedule an appointment for this patient',
              actionLabel: 'Schedule Appointment',
              onAction: () => _navigateToAddAppointment(context),
            );
          }

          appointments.sort((a, b) => b.appointmentDateTime.compareTo(a.appointmentDateTime));

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: appointments.length,
            itemBuilder: (context, index) => _AppointmentCard(
              appointment: appointments[index],
              isDark: isDark,
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => PatientTabEmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading Appointments',
        subtitle: 'Please try again later',
      ),
    );
  }

  Future<List<Appointment>> _getPatientAppointments(DoctorDatabase db) async {
    final allAppointments = await db.getAllAppointments();
    return allAppointments.where((a) => a.patientId == patient.id).toList();
  }

  void _navigateToAddAppointment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(preselectedPatient: patient),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isDark,
  });

  final Appointment appointment;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    Color statusColor;
    switch (appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
      case 'cancelled':
        statusColor = AppColors.error;
      case 'no-show':
        statusColor = AppColors.warning;
      default:
        statusColor = AppColors.info;
    }

    return PatientItemCard(
      icon: Icons.event,
      iconColor: AppColors.primary,
      title: appointment.reason.isNotEmpty ? appointment.reason : 'Appointment',
      subtitle: dateFormat.format(appointment.appointmentDateTime),
      trailing: StatusBadge(
        label: appointment.status,
        color: statusColor,
      ),
    );
  }
}
