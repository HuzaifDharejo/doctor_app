# Doctor App - Quick Reference Guide

**Quick lookup for common tasks and patterns**

---

## 🚀 Common Tasks

### Adding a New Screen

1. **Create screen file**: `lib/src/ui/screens/my_new_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';

class MyNewScreen extends ConsumerWidget {
  const MyNewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My New Screen')),
      body: const Center(child: Text('Content')),
    );
  }
}
```

2. **Add route**: `lib/src/core/routing/app_router.dart`
```dart
// In AppRoutes class
static const String myNewScreen = '/my-new-screen';

// In AppRouter.generateRoute()
case AppRoutes.myNewScreen:
  return _buildRoute(const MyNewScreen(), settings);
```

3. **Add navigation helper** (optional): `lib/src/core/routing/app_router.dart`
```dart
// In NavigationHelper extension
Future<void> goToMyNewScreen() => pushNamed(AppRoutes.myNewScreen);
```

### Adding a New Service

1. **Create service file**: `lib/src/services/my_new_service.dart`
```dart
import '../db/doctor_db.dart';
import 'logger_service.dart';

class MyNewService {
  final DoctorDb _db;
  
  MyNewService(this._db);
  
  Future<List<MyModel>> getItems() async {
    log.d('SERVICE', 'Getting items');
    // Implementation
    return [];
  }
}
```

2. **Create provider**: `lib/src/providers/my_new_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import '../services/my_new_service.dart';

final myNewServiceProvider = Provider<MyNewService>((ref) {
  final db = ref.watch(doctorDbProvider).value!;
  return MyNewService(db);
});
```

3. **Use in widget**:
```dart
final service = ref.watch(myNewServiceProvider);
```

### Adding a New Database Table

1. **Add table definition**: `lib/src/db/doctor_db.dart`
```dart
class MyNewTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

2. **Add to database class**:
```dart
@DriftDatabase(tables: [
  Patients,
  Appointments,
  MyNewTable, // Add here
])
class DoctorDb extends _$DoctorDb {
  // ...
}
```

3. **Generate code**:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Adding a New Model

1. **Create model file**: `lib/src/models/my_model.dart`
```dart
class MyModel {
  final int id;
  final String name;
  final DateTime createdAt;

  MyModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  // From database row
  factory MyModel.fromData(Map<String, dynamic> data) {
    return MyModel(
      id: data['id'] as int,
      name: data['name'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

2. **Export in models.dart**: `lib/src/models/models.dart`
```dart
export 'my_model.dart';
```

---

## 📋 Common Patterns

### Reading from Database

```dart
final db = ref.watch(doctorDbProvider).value;
if (db == null) return LoadingWidget();

final patients = await db.getAllPatients();
```

### Writing to Database

```dart
final db = ref.watch(doctorDbProvider).value!;

await db.into(db.patients).insert(
  PatientsCompanion.insert(
    firstName: 'John',
    lastName: 'Doe',
  ),
);
```

### Error Handling with Result Type

```dart
import '../core/utils/result.dart';

Future<Result<List<Patient>, String>> getPatients() async {
  try {
    final patients = await db.getAllPatients();
    return Result.success(patients);
  } catch (e) {
    return Result.failure('Failed to load patients: $e');
  }
}

// Usage
final result = await getPatients();
result.when(
  success: (patients) => print('Got ${patients.length} patients'),
  failure: (error) => print('Error: $error'),
);
```

### Logging

```dart
import '../services/logger_service.dart';

// Info log
log.i('CATEGORY', 'Message');

// Debug log
log.d('CATEGORY', 'Message', extra: {'key': 'value'});

// Error log
log.e('CATEGORY', 'Error message', 
  error: exception,
  stackTrace: stackTrace,
);
```

### Navigation

```dart
// Using helper methods
context.goToPatientView(patient);
context.goToAddAppointment(patient: patient);

// Using named routes
context.pushNamed(
  AppRoutes.patientView,
  arguments: PatientViewArgs(patient: patient),
);

// Direct navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const MyScreen()),
);
```

### Form Validation

```dart
import '../core/utils/validators.dart';

final nameValidator = Validators.compose([
  Validators.required('Name is required'),
  Validators.minLength(2, 'Name must be at least 2 characters'),
]);

// In TextFormField
TextFormField(
  validator: nameValidator,
  // ...
)
```

### Loading States

```dart
final dbAsync = ref.watch(doctorDbProvider);

dbAsync.when(
  data: (db) => MyContentWidget(db: db),
  loading: () => const LoadingWidget(),
  error: (error, stack) => ErrorWidget(error: error),
);
```

### Dark Mode Detection

```dart
import '../core/extensions/context_extensions.dart';

final isDark = context.isDarkMode;
final colorScheme = context.colorScheme;
```

---

## 🔍 Finding Things

### Where is...?

| What | Location |
|------|----------|
| All screens | `lib/src/ui/screens/` |
| All services | `lib/src/services/` |
| All models | `lib/src/models/` |
| All providers | `lib/src/providers/` |
| Database schema | `lib/src/db/doctor_db.dart` |
| Routes | `lib/src/core/routing/app_router.dart` |
| Constants | `lib/src/core/constants/` |
| Widgets | `lib/src/core/widgets/` or `lib/src/ui/widgets/` |
| Theme | `lib/src/theme/app_theme.dart` |
| Design tokens | `lib/src/core/theme/design_tokens.dart` |

### Common Imports

```dart
// Core utilities
import 'package:doctor_app/src/core/core.dart';

// Models
import 'package:doctor_app/src/models/models.dart';

// Database
import 'package:doctor_app/src/db/doctor_db.dart';

// Routing
import 'package:doctor_app/src/core/routing/app_router.dart';

// Services
import 'package:doctor_app/src/services/logger_service.dart';
```

---

## 🎨 UI Components

### AppButton

```dart
AppButton(
  onPressed: () {},
  label: 'Save',
  variant: ButtonVariant.primary,
)
```

### AppInput

```dart
AppInput(
  label: 'Name',
  hint: 'Enter name',
  validator: nameValidator,
  onChanged: (value) {},
)
```

### AppCard

```dart
AppCard(
  child: Text('Content'),
  padding: EdgeInsets.all(16),
)
```

### LoadingButton

```dart
LoadingButton(
  onPressed: () async {
    // Async operation
  },
  label: 'Submit',
)
```

### SearchField

```dart
SearchField(
  hint: 'Search patients...',
  onChanged: (query) {},
)
```

---

## 🗄️ Database Queries

### Get All Patients

```dart
final patients = await db.getAllPatients();
```

### Get Patient by ID

```dart
final patient = await db.getPatientById(patientId);
```

### Get Appointments for Date

```dart
final appointments = await db.getAppointmentsForDay(DateTime.now());
```

### Insert Patient

```dart
await db.into(db.patients).insert(
  PatientsCompanion.insert(
    firstName: 'John',
    lastName: 'Doe',
    phone: '1234567890',
  ),
);
```

### Update Patient

```dart
await (db.update(db.patients)
  ..where((p) => p.id.equals(patientId)))
  .write(PatientsCompanion(
    firstName: const Value('Updated Name'),
  ));
```

### Delete Patient

```dart
await (db.delete(db.patients)
  ..where((p) => p.id.equals(patientId)))
  .go();
```

---

## 🧪 Testing Patterns

### Unit Test

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyService', () {
    test('should do something', () {
      // Arrange
      final service = MyService();
      
      // Act
      final result = service.doSomething();
      
      // Assert
      expect(result, equals(expected));
    });
  });
}
```

### Widget Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('MyWidget displays correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MyWidget(),
        ),
      ),
    );
    
    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

---

## 🔐 Security Patterns

### App Lock

```dart
final appLockService = ref.watch(appLockServiceProvider);

if (appLockService.isLocked) {
  return LockScreen(
    appLockService: appLockService,
    onUnlocked: () {},
  );
}
```

### Audit Logging

```dart
final auditService = ref.watch(auditServiceProvider);

await auditService.logPatientViewed(patientId);
await auditService.logRecordModified(recordId, before, after);
```

---

## 📱 Common Screen Patterns

### List Screen

```dart
class MyListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends ConsumerState<MyListScreen> {
  List<MyModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final db = ref.read(doctorDbProvider).value!;
    final items = await db.getItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return LoadingWidget();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) => ItemCard(item: _items[index]),
      ),
    );
  }
}
```

### Form Screen

```dart
class MyFormScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyFormScreen> createState() => _MyFormScreenState();
}

class _MyFormScreenState extends ConsumerState<MyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final db = ref.read(doctorDbProvider).value!;
    await db.insertItem(_nameController.text);
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              validator: Validators.required('Name is required'),
            ),
            AppButton(
              onPressed: _save,
              label: 'Save',
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🐛 Debugging Tips

### Check Database

```dart
final db = ref.read(doctorDbProvider).value!;
final patients = await db.getAllPatients();
print('Patients count: ${patients.length}');
```

### Check Logs

```dart
log.d('DEBUG', 'Variable value: $variable', extra: {'key': 'value'});
```

### Check Navigation

```dart
// Log navigation events
log.d('NAV', 'Navigating to: ${route.name}');
```

---

*For more detailed information, see `CODEBASE_CONTEXT.md`*

