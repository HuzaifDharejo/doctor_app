import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/design_tokens.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/logger_service.dart';
import '../../services/search_cache_service.dart';
import 'patient_view/patient_view_screen.dart';
import 'invoice_detail_screen.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/empty_state.dart';

/// Global search screen that searches across patients, appointments, prescriptions, and invoices
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Timer? _debounceTimer;
  
  // Search results
  List<Patient> _patients = [];
  List<_AppointmentWithPatient> _appointments = [];
  List<_PrescriptionWithPatient> _prescriptions = [];
  List<_InvoiceWithPatient> _invoices = [];
  bool _isLoading = false;
  
  final List<String> _categories = ['All', 'Patients', 'Appointments', 'Prescriptions', 'Invoices'];

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
      if (query.length >= 2) {
        _performSearch(query);
      } else {
        setState(() {
          _patients = [];
          _appointments = [];
          _prescriptions = [];
          _invoices = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    final cacheService = SearchCacheService();
    final cacheParams = {
      'query': query,
      'category': _selectedCategory,
    };
    
    // Try to get cached results first for instant feedback
    final cachedPatients = cacheService.getCached<Patient>(
      cacheType: 'global_search_patients',
      params: cacheParams,
    );
    
    if (cachedPatients != null) {
      setState(() {
        _patients = cachedPatients;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true);
    }
    
    try {
      final db = await ref.read(doctorDbProvider.future);
      
      // Search patients using optimized database query
      if (_selectedCategory == 'All' || _selectedCategory == 'Patients') {
        final patients = await db.searchPatientsLimited(query, limit: 10);
        cacheService.setCached<Patient>(
          cacheType: 'global_search_patients',
          params: cacheParams,
          data: patients,
        );
        setState(() {
          _patients = patients;
        });
      } else {
        setState(() {
          _patients = [];
        });
      }
      
      // Search appointments using optimized database query
      if (_selectedCategory == 'All' || _selectedCategory == 'Appointments') {
        final appointments = await db.searchAppointmentsLimited(query, limit: 10);
        final appointmentsWithPatients = <_AppointmentWithPatient>[];
        
        // Batch load patients to avoid N+1 queries
        final patientIds = appointments.map((a) => a.patientId).toSet();
        final patientsMap = <int, Patient>{};
        for (final id in patientIds) {
          final patient = await db.getPatientById(id);
          if (patient != null) {
            patientsMap[id] = patient;
          }
        }
        
        // Also search by patient name if query matches
        if (query.length >= 2) {
          final matchingPatients = await db.searchPatientsLimited(query, limit: 5);
          for (final patient in matchingPatients) {
            patientsMap[patient.id] = patient;
          }
          
          // Get appointments for matching patients
          final patientIdsList = matchingPatients.map((p) => p.id).toList();
          if (patientIdsList.isNotEmpty) {
            final patientAppointments = await (db.select(db.appointments)
              ..where((a) => a.patientId.isIn(patientIdsList))
              ..orderBy([(a) => drift.OrderingTerm.desc(a.appointmentDateTime)])
              ..limit(10))
              .get();
            
            for (final appt in patientAppointments) {
              if (appointmentsWithPatients.length >= 10) break;
              final patient = patientsMap[appt.patientId];
              if (patient != null && !appointments.any((a) => a.id == appt.id)) {
                appointments.add(appt);
              }
            }
          }
        }
        
        // Combine results
        for (final appt in appointments) {
          final patient = patientsMap[appt.patientId];
          if (patient != null) {
            appointmentsWithPatients.add(_AppointmentWithPatient(appt, patient));
            if (appointmentsWithPatients.length >= 10) break;
          }
        }
        
        _appointments = appointmentsWithPatients;
      } else {
        _appointments = [];
      }
      
      // Search prescriptions using optimized database query
      if (_selectedCategory == 'All' || _selectedCategory == 'Prescriptions') {
        final prescriptions = await db.searchPrescriptionsLimited(query, limit: 10);
        final prescriptionsWithPatients = <_PrescriptionWithPatient>[];
        
        // Batch load patients
        final patientIds = prescriptions.map((rx) => rx.patientId).toSet();
        final patientsMap = <int, Patient>{};
        for (final id in patientIds) {
          final patient = await db.getPatientById(id);
          if (patient != null) {
            patientsMap[id] = patient;
          }
        }
        
        // Also search by patient name
        if (query.length >= 2) {
          final matchingPatients = await db.searchPatientsLimited(query, limit: 5);
          for (final patient in matchingPatients) {
            patientsMap[patient.id] = patient;
          }
          
          // Get prescriptions for matching patients
          final patientIdsList = matchingPatients.map((p) => p.id).toList();
          if (patientIdsList.isNotEmpty) {
            final patientPrescriptions = await (db.select(db.prescriptions)
              ..where((p) => p.patientId.isIn(patientIdsList))
              ..orderBy([(p) => drift.OrderingTerm.desc(p.createdAt)])
              ..limit(10))
              .get();
            
            for (final rx in patientPrescriptions) {
              if (prescriptionsWithPatients.length >= 10) break;
              final patient = patientsMap[rx.patientId];
              if (patient != null && !prescriptions.any((p) => p.id == rx.id)) {
                prescriptions.add(rx);
              }
            }
          }
        }
        
        // Combine results
        for (final rx in prescriptions) {
          final patient = patientsMap[rx.patientId];
          if (patient != null) {
            prescriptionsWithPatients.add(_PrescriptionWithPatient(rx, patient));
            if (prescriptionsWithPatients.length >= 10) break;
          }
        }
        
        _prescriptions = prescriptionsWithPatients;
      } else {
        _prescriptions = [];
      }
      
      // Search invoices using optimized database query
      if (_selectedCategory == 'All' || _selectedCategory == 'Invoices') {
        // Check cache first
        final cachedInvoices = cacheService.getCached<_InvoiceWithPatient>(
          cacheType: 'global_search_invoices',
          params: cacheParams,
        );
        
        if (cachedInvoices != null) {
          setState(() {
            _invoices = cachedInvoices;
          });
        }
        final invoiceList = await db.searchInvoicesLimited(query, limit: 10);
        final invoicesWithPatients = <_InvoiceWithPatient>[];
        final invoiceListMutable = List<Invoice>.from(invoiceList);
        
        // Batch load patients
        final patientIds = invoiceListMutable.map((inv) => inv.patientId).toSet();
        final patientsMap = <int, Patient>{};
        for (final id in patientIds) {
          final patient = await db.getPatientById(id);
          if (patient != null) {
            patientsMap[id] = patient;
          }
        }
        
        // Also search by patient name
        if (query.length >= 2) {
          final matchingPatients = await db.searchPatientsLimited(query, limit: 5);
          for (final patient in matchingPatients) {
            patientsMap[patient.id] = patient;
          }
          
          // Get invoices for matching patients
          final patientIdsList = matchingPatients.map((p) => p.id).toList();
          if (patientIdsList.isNotEmpty) {
            final patientInvoices = await (db.select(db.invoices)
              ..where((i) => i.patientId.isIn(patientIdsList))
              ..orderBy([(i) => drift.OrderingTerm.desc(i.invoiceDate)])
              ..limit(10))
              .get();
            
            for (final inv in patientInvoices) {
              if (invoicesWithPatients.length >= 10) break;
              final patient = patientsMap[inv.patientId];
              if (patient != null && !invoiceListMutable.any((i) => i.id == inv.id)) {
                invoiceListMutable.add(inv);
              }
            }
          }
        }
        
        // Combine results
        for (final inv in invoiceListMutable) {
          final patient = patientsMap[inv.patientId];
          if (patient != null) {
            invoicesWithPatients.add(_InvoiceWithPatient(inv, patient));
            if (invoicesWithPatients.length >= 10) break;
          }
        }
        
        cacheService.setCached<_InvoiceWithPatient>(
          cacheType: 'global_search_invoices',
          params: cacheParams,
          data: invoicesWithPatients,
        );
        
        setState(() {
          _invoices = invoicesWithPatients;
        });
      } else {
        setState(() {
          _invoices = [];
        });
      }
      
    } catch (e, stackTrace) {
      log.e('SEARCH', 'Global search failed', error: e, stackTrace: stackTrace);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int get _totalResults => _patients.length + _appointments.length + _prescriptions.length + _invoices.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Modern Search Header
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: surfaceColor,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkTextPrimary.withValues(alpha: 0.1)
                      : AppColors.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkSurfaceMid, AppColors.darkSurfaceAccent]
                        : [AppColors.background, surfaceColor],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xxxxxl + 2,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.md + 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: AppShadow.medium,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppColors.surface,
                            size: AppIconSize.lg,
                          ),
                        ),
                        SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Global Search',
                                style: TextStyle(
                                  fontSize: AppFontSize.displayMedium,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Find anything in your clinic',
                                style: TextStyle(
                                  fontSize: AppFontSize.bodyLarge,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search patients, appointments, prescriptions...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded, 
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),
          
          // Category filter chips
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                          if (_searchQuery.length >= 2) {
                            _performSearch(_searchQuery);
                          }
                        },
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.5) 
                                : Colors.transparent,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected 
                              ? AppColors.primary 
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Results
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              : _searchQuery.length < 2
                  ? SliverFillRemaining(
                      child: EmptySearchResults(
                        query: null,
                      ),
                    )
                  : _totalResults == 0
                      ? SliverFillRemaining(
                          child: EmptySearchResults(
                            query: _searchQuery,
                          ),
                        )
                      : SliverToBoxAdapter(child: _buildResults(isDark)),
                      
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 56,
                color: const Color(0xFF6366F1).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Patients section
        if (_patients.isNotEmpty) ...[
          _buildSectionHeader('Patients', Icons.people_rounded, AppColors.patients, _patients.length, isDark),
          ..._patients.map((p) => _buildPatientTile(p, isDark)),
          const SizedBox(height: 16),
        ],
        
        // Appointments section
        if (_appointments.isNotEmpty) ...[
          _buildSectionHeader('Appointments', Icons.calendar_month_rounded, AppColors.appointments, _appointments.length, isDark),
          ..._appointments.map((a) => _buildAppointmentTile(a, isDark)),
          const SizedBox(height: 16),
        ],
        
        // Prescriptions section
        if (_prescriptions.isNotEmpty) ...[
          _buildSectionHeader('Prescriptions', Icons.medication_rounded, AppColors.warning, _prescriptions.length, isDark),
          ..._prescriptions.map((p) => _buildPrescriptionTile(p, isDark)),
          const SizedBox(height: 16),
        ],
        
        // Invoices section
        if (_invoices.isNotEmpty) ...[
          _buildSectionHeader('Invoices', Icons.receipt_long_rounded, AppColors.success, _invoices.length, isDark),
          ..._invoices.map((i) => _buildInvoiceTile(i, isDark)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTile(Patient patient, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.patients.withValues(alpha: 0.1),
          child: Text(
            patient.firstName[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.patients,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${patient.firstName} ${patient.lastName}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          patient.phone.isNotEmpty ? patient.phone : patient.email,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientViewScreen(patient: patient),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentTile(_AppointmentWithPatient appt, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    Color statusColor;
    switch (appt.appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
      case 'cancelled':
        statusColor = AppColors.error;
      case 'scheduled':
      case 'confirmed':
        statusColor = AppColors.primary;
      default:
        statusColor = AppColors.warning;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.appointments.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event, color: AppColors.appointments, size: 20),
        ),
        title: Text(
          '${appt.patient.firstName} ${appt.patient.lastName}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(appt.appointment.appointmentDateTime),
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            if (appt.appointment.reason.isNotEmpty)
              Text(
                appt.appointment.reason,
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            appt.appointment.status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionTile(_PrescriptionWithPatient rx, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.medication, color: AppColors.warning, size: 20),
        ),
        title: Text(
          '${rx.patient.firstName} ${rx.patient.lastName}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(rx.prescription.createdAt),
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            if (rx.prescription.diagnosis.isNotEmpty)
              Text(
                rx.prescription.diagnosis,
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientViewScreen(patient: rx.patient),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceTile(_InvoiceWithPatient inv, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isPaid = inv.invoice.paymentStatus == 'Paid';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_long, color: AppColors.success, size: 20),
        ),
        title: Text(
          inv.invoice.invoiceNumber,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${inv.patient.firstName} ${inv.patient.lastName}',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            Text(
              '${dateFormat.format(inv.invoice.invoiceDate)} • Rs. ${inv.invoice.grandTotal.toStringAsFixed(0)}',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPaid ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            inv.invoice.paymentStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPaid ? AppColors.success : AppColors.warning,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(
                invoice: inv.invoice,
                patient: inv.patient,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper classes
class _AppointmentWithPatient {
  final Appointment appointment;
  final Patient patient;
  _AppointmentWithPatient(this.appointment, this.patient);
}

class _PrescriptionWithPatient {
  final Prescription prescription;
  final Patient patient;
  _PrescriptionWithPatient(this.prescription, this.patient);
}

class _InvoiceWithPatient {
  final Invoice invoice;
  final Patient patient;
  _InvoiceWithPatient(this.invoice, this.patient);
}
