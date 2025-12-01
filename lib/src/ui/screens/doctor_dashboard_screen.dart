import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../widgets/patient_card.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        elevation: 0,
        backgroundColor: Colors.blue[900],
      ),
      body: dbAsync.when(
        data: (db) => _buildDashboard(db, context),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading dashboard: $err'),
        ),
      ),
    );
  }

  Widget _buildDashboard(DoctorDatabase db, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeSection(context),
          const SizedBox(height: 24),

          // Alerts section
          _buildAlertsSection(),
          const SizedBox(height: 24),

          // Today's appointments
          _buildTodaysAppointments(db),
          const SizedBox(height: 24),

          // Quick actions
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // High-risk patients
          _buildHighRiskPatients(db),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900] ?? Colors.blue, Colors.blue[700] ?? Colors.blue],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Doctor!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠️  ALERTS & NOTIFICATIONS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAlertCard(
                icon: Icons.warning,
                title: 'High-Risk Patients',
                count: '2',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAlertCard(
                icon: Icons.science,
                title: 'Pending Lab Results',
                count: '3',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAlertCard(
                icon: Icons.history,
                title: 'Overdue Follow-ups',
                count: '5',
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysAppointments(DoctorDatabase db) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📅 TODAY\'S APPOINTMENTS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Appointment>>(
          future: db.getAppointmentsForDay(DateTime.now()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No appointments today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.map((apt) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            apt.appointmentDateTime.hour
                                .toString()
                                .padLeft(2, '0'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apt.reason,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${apt.appointmentDateTime.hour}:${apt.appointmentDateTime.minute.toString().padLeft(2, '0')} (${apt.durationMinutes} min)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(apt.status),
                          backgroundColor: _getStatusColor(apt.status),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ QUICK ACTIONS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionButton(
              icon: Icons.person_add,
              label: 'New Patient',
              onPressed: () => Navigator.pushNamed(context, '/patients'),
              color: Colors.blue,
            ),
            _buildActionButton(
              icon: Icons.event_note,
              label: 'New Appointment',
              onPressed: () => Navigator.pushNamed(context, '/appointments'),
              color: Colors.green,
            ),
            _buildActionButton(
              icon: Icons.medication,
              label: 'New Prescription',
              onPressed: () => Navigator.pushNamed(context, '/prescriptions'),
              color: Colors.purple,
            ),
            _buildActionButton(
              icon: Icons.favorite,
              label: 'Vital Signs',
              onPressed: () => Navigator.pushNamed(context, '/vitals'),
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighRiskPatients(DoctorDatabase db) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🚨 HIGH-RISK PATIENTS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Patient>>(
          future: db.getHighRiskPatients(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No high-risk patients',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.map((patient) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.red[50],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.warning, color: Colors.white),
                    ),
                    title: Text('${patient.firstName} ${patient.lastName}'),
                    subtitle: Text(
                        'Age: ${_calculateAge(patient.dateOfBirth)} | Risk Level: High'),
                    trailing: Icon(Icons.arrow_forward, color: Colors.red[700]),
                    onTap: () {
                      // TODO: Navigate to patient view
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Completed':
        return Colors.green[100]!;
      case 'No Show':
        return Colors.red[100]!;
      case 'Rescheduled':
        return Colors.orange[100]!;
      default:
        return Colors.blue[100]!;
    }
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}

