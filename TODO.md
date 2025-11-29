# Doctor App - Improvement Roadmap

## 🔴 Critical (P0)

### Testing
- [ ] Add unit tests for PatientRepository
- [ ] Add unit tests for AppointmentRepository
- [ ] Add unit tests for PrescriptionRepository
- [ ] Add unit tests for InvoiceRepository
- [ ] Add unit tests for MedicalRecordRepository
- [x] Add unit tests for DoctorSettingsService (30 tests)
- [ ] Add unit tests for AppSettingsService
- [ ] Add unit tests for BackupService
- [x] Add widget tests for PatientCard (14 tests)
- [x] Add widget tests for ErrorDisplay (19 tests)
- [ ] Add widget tests for dashboard components
- [ ] Add integration tests for patient CRUD flow
- [ ] Add integration tests for prescription flow

### Data Validation
- [x] Create InputValidator utility class (35 tests)
- [x] Add phone number validation
- [x] Add email validation
- [x] Add date validation (no future DOB, etc.)
- [x] Add medical record data sanitization
- [x] Integrate validators into add_patient_screen

### Security
- [ ] Implement SQLCipher for encrypted database
- [ ] Add biometric auth enforcement on app resume
- [ ] Encrypt sensitive fields (medical history, notes)

## 🟡 High Priority (P1)

### Error Handling
- [x] Create ErrorDisplay widget with factory constructors
- [x] Add error boundary wrapper
- [x] Implement snackbar extensions (success/error/info)
- [ ] Add error reporting/logging service

### Backup Enhancement
- [x] Add auto-scheduled backups (with frequency setting)
- [ ] Add backup to Google Drive option
- [x] Add backup integrity verification
- [ ] Add backup encryption
- [ ] Add restore confirmation dialog
- [x] Add backup metadata (timestamp, version, checksum)
- [x] Add backup listing and cleanup (old backups)

### Offline Sync
- [ ] Add sync status indicator widget
- [ ] Implement conflict resolution for calendar
- [ ] Add retry mechanism for failed syncs
- [ ] Queue operations when offline

## 🟢 Nice to Have (P2)

### Performance
- [ ] Add pagination to patient list
- [ ] Add pagination to appointments list
- [ ] Implement lazy loading for medical records
- [ ] Add image caching for patient photos
- [ ] Optimize large screen rebuilds

### Accessibility
- [ ] Audit semantic labels coverage
- [ ] Check contrast ratios (WCAG AA)
- [ ] Add screen reader announcements for actions
- [ ] Test with TalkBack/VoiceOver

### Code Quality
- [ ] Split patient_view_screen.dart into smaller widgets
- [ ] Extract common form widgets
- [ ] Add dartdoc comments to public APIs
- [ ] Standardize data access patterns

### Future Features
- [ ] Export monthly reports (PDF)
- [ ] Push notification reminders
- [ ] Patient prescription sharing via link
- [ ] Multi-doctor/clinic mode
- [ ] Audit logging for changes

---
Last Updated: 2025-02-03

## Progress Summary
- **99 tests passing** (35 unit + 30 service + 33 widget + 1 smoke)
- **0 lint issues**
- Input validation integrated into patient form
- Error handling widgets ready for use
- Auto-backup system enhanced
