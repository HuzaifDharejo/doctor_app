# Doctor App Design Standards Document

> **Version:** 2.0  
> **Last Updated:** December 3, 2025  
> **Platform:** Flutter (iOS, Android, Web, Desktop)

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Spacing System](#spacing-system)
5. [Border Radius](#border-radius)
6. [Shadows & Elevation](#shadows--elevation)
7. [Component Standards](#component-standards)
8. [Screen Templates](#screen-templates)
9. [Icons](#icons)
10. [Animations](#animations)
11. [Accessibility](#accessibility)
12. [Dark Mode](#dark-mode)
13. [Responsive Design](#responsive-design)
14. [Code Examples](#code-examples)

---

## 1. Design Philosophy

### Core Principles

1. **Clarity First** - Medical apps require clear, readable interfaces
2. **Consistency** - Same patterns across all screens
3. **Efficiency** - Minimize taps to complete tasks
4. **Trust** - Professional appearance builds confidence
5. **Accessibility** - Usable by all users

### Visual Style

- **Modern & Clean** - Minimal clutter, generous whitespace
- **Soft Gradients** - Professional, not flashy
- **Rounded Corners** - Friendly, approachable feel
- **Subtle Shadows** - Depth without heaviness
- **Color-Coded Sections** - Easy visual scanning

---

## 2. Color System

### Primary Colors

```dart
// Primary Blue
static const Color primary = Color(0xFF3B82F6);
static const Color primaryDark = Color(0xFF1D4ED8);
static const Color primaryLight = Color(0xFF60A5FA);

// Primary Gradient
static const LinearGradient primaryGradient = LinearGradient(
  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

### Semantic Colors

```dart
// Success - Green (Confirmations, Active, Healthy)
static const Color success = Color(0xFF10B981);
static const Color successDark = Color(0xFF059669);

// Warning - Amber (Alerts, Pending, Caution)
static const Color warning = Color(0xFFF59E0B);
static const Color warningDark = Color(0xFFD97706);

// Error - Red (Errors, Critical, Urgent)
static const Color error = Color(0xFFEF4444);
static const Color errorDark = Color(0xFFDC2626);

// Info - Cyan (Information, Tips)
static const Color info = Color(0xFF06B6D4);
static const Color infoDark = Color(0xFF0891B2);
```

### Section Colors (For Cards & Icons)

```dart
// Patient Section - Indigo
static const Color patientColor = Color(0xFF6366F1);
static const Color patientColorLight = Color(0xFF8B5CF6);

// Appointment/Calendar - Blue
static const Color appointmentColor = Color(0xFF3B82F6);
static const Color appointmentColorDark = Color(0xFF1D4ED8);

// Medical/Clinical - Green
static const Color clinicalColor = Color(0xFF10B981);
static const Color clinicalColorDark = Color(0xFF059669);

// Notes/Documentation - Amber
static const Color notesColor = Color(0xFFF59E0B);
static const Color notesColorDark = Color(0xFFD97706);

// Billing/Finance - Purple
static const Color billingColor = Color(0xFF8B5CF6);
static const Color billingColorDark = Color(0xFF7C3AED);

// Medication/Prescription - Pink
static const Color medicationColor = Color(0xFFEC4899);
static const Color medicationColorDark = Color(0xFFDB2777);

// Lab Results - Teal
static const Color labColor = Color(0xFF14B8A6);
static const Color labColorDark = Color(0xFF0D9488);

// Emergency/Critical - Red
static const Color emergencyColor = Color(0xFFEF4444);
static const Color emergencyColorDark = Color(0xFFDC2626);
```

### Background Colors

```dart
// Light Mode
static const Color background = Color(0xFFF8F9FA);
static const Color surface = Color(0xFFFFFFFF);
static const Color cardBackground = Color(0xFFFFFFFF);

// Dark Mode
static const Color darkBackground = Color(0xFF0F0F0F);
static const Color darkSurface = Color(0xFF1A1A1A);
static const Color darkCardBackground = Color(0xFF1A1A1A);
```

### Text Colors

```dart
// Light Mode
static const Color textPrimary = Color(0xFF111827);    // Black87
static const Color textSecondary = Color(0xFF6B7280);  // Grey[600]
static const Color textHint = Color(0xFF9CA3AF);       // Grey[400]

// Dark Mode
static const Color darkTextPrimary = Color(0xFFFFFFFF);
static const Color darkTextSecondary = Color(0xFF9CA3AF);
static const Color darkTextHint = Color(0xFF6B7280);
```

---

## 3. Typography

### Font Family

```dart
// Primary: System Default (San Francisco on iOS, Roboto on Android)
// No custom fonts needed - ensures native feel
```

### Text Styles

```dart
// Headlines
TextStyle headline1 = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.5,
  height: 1.2,
);

TextStyle headline2 = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
  height: 1.3,
);

TextStyle headline3 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
  height: 1.3,
);

// Titles
TextStyle title1 = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.2,
);

TextStyle title2 = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
);

TextStyle title3 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
);

// Body Text
TextStyle body1 = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.5,
);

TextStyle body2 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.5,
);

// Captions & Labels
TextStyle caption = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.2,
);

TextStyle label = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
);

// Buttons
TextStyle button = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

TextStyle buttonSmall = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
);
```

---

## 4. Spacing System

### Base Unit: 4px

```dart
class AppSpacing {
  static const double xs = 4;    // Extra small
  static const double sm = 8;    // Small
  static const double md = 12;   // Medium
  static const double lg = 16;   // Large
  static const double xl = 20;   // Extra large
  static const double xxl = 24;  // 2X large
  static const double xxxl = 32; // 3X large
}
```

### Common Spacing Patterns

```dart
// Screen Padding
EdgeInsets screenPadding = EdgeInsets.all(20); // Compact: 16

// Card Padding
EdgeInsets cardPadding = EdgeInsets.all(18);

// Section Spacing (between cards)
SizedBox sectionSpacing = SizedBox(height: 16);

// Item Spacing (within lists)
SizedBox itemSpacing = SizedBox(height: 12);

// Inline Spacing (between elements)
SizedBox inlineSpacing = SizedBox(width: 12);
```

---

## 5. Border Radius

### Standard Values

```dart
class AppRadius {
  static const double xs = 8;    // Chips, small buttons
  static const double sm = 10;   // Input fields
  static const double md = 12;   // Buttons, small cards
  static const double lg = 14;   // Input containers
  static const double xl = 16;   // Cards, dialogs
  static const double xxl = 20;  // Section cards
  static const double round = 100; // Circular (pills, avatars)
}
```

### Usage Guidelines

| Component | Border Radius |
|-----------|---------------|
| Section Cards | 20px |
| Dialog/Modal | 20px |
| Input Fields | 14px |
| Buttons | 16px |
| Chips | 10-12px |
| Avatars | Circular |
| Icon Containers | 12-16px |
| Bottom Sheets | 24px (top only) |

---

## 6. Shadows & Elevation

### Shadow Levels

```dart
// Level 1 - Subtle (Cards, Buttons)
BoxShadow shadowLevel1 = BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 10,
  offset: Offset(0, 2),
);

// Level 2 - Medium (Elevated Cards, Dropdowns)
BoxShadow shadowLevel2 = BoxShadow(
  color: Colors.black.withOpacity(0.08),
  blurRadius: 16,
  offset: Offset(0, 4),
);

// Level 3 - High (Modals, FABs)
BoxShadow shadowLevel3 = BoxShadow(
  color: Colors.black.withOpacity(0.12),
  blurRadius: 24,
  offset: Offset(0, 8),
);

// Colored Shadow (Primary buttons, Icons)
BoxShadow primaryShadow = BoxShadow(
  color: Color(0xFF3B82F6).withOpacity(0.3),
  blurRadius: 12,
  offset: Offset(0, 4),
);

// Success Shadow
BoxShadow successShadow = BoxShadow(
  color: Color(0xFF10B981).withOpacity(0.3),
  blurRadius: 8,
  offset: Offset(0, 2),
);
```

---

## 7. Component Standards

### 7.1 App Bar

#### Modern SliverAppBar

```dart
SliverAppBar(
  expandedHeight: 140,
  pinned: true,
  elevation: 0,
  scrolledUnderElevation: 1,
  backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
  leading: _buildBackButton(),
  flexibleSpace: FlexibleSpaceBar(
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [Color(0xFF1A1A1A), Color(0xFF0F0F0F)]
              : [Colors.white, Color(0xFFF8F9FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _buildHeaderContent(),
    ),
  ),
);
```

#### Back Button Style

```dart
Widget _buildBackButton() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : Colors.black87,
          size: 22,
        ),
      ),
    ),
  );
}
```

### 7.2 Section Card

```dart
Widget buildSectionCard({
  required String title,
  required IconData icon,
  required Color iconColor,
  required bool isDark,
  required Widget child,
  Widget? trailing,
}) {
  return Container(
    decoration: BoxDecoration(
      color: isDark ? Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
```

### 7.3 Header Icon

```dart
Widget buildHeaderIcon({
  required IconData icon,
  required List<Color> gradientColors,
}) {
  return Container(
    padding: EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: gradientColors[0].withOpacity(0.3),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: 28),
  );
}
```

### 7.4 Primary Button

```dart
Widget buildPrimaryButton({
  required String label,
  required VoidCallback onTap,
  required bool isDark,
  IconData? icon,
  bool isLoading = false,
}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: isLoading ? null : LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      color: isLoading ? (isDark ? Colors.grey[700] : Colors.grey[400]) : null,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isLoading ? null : [
        BoxShadow(
          color: Color(0xFF3B82F6).withOpacity(0.4),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, 
                    color: Colors.white,
                  ),
                )
              else if (icon != null)
                Icon(icon, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

### 7.5 Selection Chip

```dart
Widget buildSelectionChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
  required bool isDark,
  Color? selectedColor,
}) {
  final color = selectedColor ?? Color(0xFF3B82F6);
  
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected 
            ? LinearGradient(colors: [color, color.withBlue(color.blue - 30)])
            : null,
        color: isSelected 
            ? null 
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.transparent : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ] : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );
}
```

### 7.6 Input Field

```dart
Widget buildInputField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required bool isDark,
  IconData? prefixIcon,
  int maxLines = 1,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: isDark ? Colors.grey[400] : Colors.grey[500], size: 20)
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    ],
  );
}
```

### 7.7 Empty State

```dart
Widget buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
  required bool isDark,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 24),
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(Icons.add_rounded),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF3B82F6),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
```

### 7.8 List Item Card

```dart
Widget buildListItemCard({
  required String title,
  required String subtitle,
  required IconData leadingIcon,
  required Color iconColor,
  required bool isDark,
  VoidCallback? onTap,
  Widget? trailing,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: iconColor, size: 22),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

### 7.9 Status Badge

```dart
Widget buildStatusBadge({
  required String label,
  required Color color,
  bool filled = false,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: filled ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: filled ? null : Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: filled ? Colors.white : color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
```

---

## 8. Screen Templates

### 8.1 List Screen Template

```
┌─────────────────────────────────┐
│ SliverAppBar                    │
│ ┌─────────────────────────────┐ │
│ │ Back │ Title + Icon         │ │
│ │      │ Subtitle             │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Search Bar (optional)           │
├─────────────────────────────────┤
│ Filter Chips (optional)         │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ List Item Card 1            │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ List Item Card 2            │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ List Item Card 3            │ │
│ └─────────────────────────────┘ │
│ ...                             │
├─────────────────────────────────┤
│              [FAB]              │
└─────────────────────────────────┘
```

### 8.2 Form Screen Template

```
┌─────────────────────────────────┐
│ SliverAppBar                    │
│ ┌─────────────────────────────┐ │
│ │ Back │ Title + Icon         │ │
│ │      │ Subtitle             │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Section Card 1              │ │
│ │ • Form Fields               │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Section Card 2              │ │
│ │ • Form Fields               │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Section Card 3              │ │
│ │ • Form Fields               │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │     Primary Save Button     │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 8.3 Detail Screen Template

```
┌─────────────────────────────────┐
│ SliverAppBar                    │
│ ┌─────────────────────────────┐ │
│ │ Back │ Title                │ │
│ │      │ ID/Status            │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Summary Card (optional)     │ │
│ │ Key Info at a glance        │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Detail Section 1            │ │
│ │ • Label: Value              │ │
│ │ • Label: Value              │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Detail Section 2            │ │
│ │ • Label: Value              │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Action Buttons Row          │ │
│ │ [Edit] [Share] [Print]      │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

---

## 9. Icons

### Icon Guidelines

1. **Use Rounded Variants** - Prefer `Icons.xxx_rounded` over default
2. **Consistent Sizing** - 
   - In headers: 28px
   - In section titles: 20px
   - In list items: 22px
   - In buttons: 20-22px
   - In chips/badges: 14-16px
3. **Color Usage** - Always use semantic colors
4. **Icon Containers** - Wrap in containers with background

### Common Icons

```dart
// Navigation
Icons.arrow_back_rounded
Icons.close_rounded
Icons.menu_rounded
Icons.more_vert_rounded

// Actions
Icons.add_rounded
Icons.edit_rounded
Icons.delete_rounded
Icons.save_rounded
Icons.share_rounded
Icons.print_rounded
Icons.check_circle_rounded

// Medical
Icons.person_rounded          // Patient
Icons.calendar_month_rounded  // Appointment
Icons.medication_rounded      // Prescription
Icons.medical_services_rounded // Medical record
Icons.monitor_heart_rounded   // Vital signs
Icons.science_rounded         // Lab results
Icons.receipt_rounded         // Invoice
Icons.note_alt_rounded        // Notes

// Status
Icons.check_circle_rounded    // Success
Icons.warning_rounded         // Warning
Icons.error_rounded           // Error
Icons.info_rounded            // Info

// UI Elements
Icons.search_rounded
Icons.filter_list_rounded
Icons.sort_rounded
Icons.keyboard_arrow_down_rounded
Icons.chevron_right_rounded
Icons.notifications_rounded
```

---

## 10. Animations

### Duration Guidelines

```dart
// Quick feedback (buttons, switches)
Duration quick = Duration(milliseconds: 150);

// Standard transitions
Duration standard = Duration(milliseconds: 200);

// Elaborate animations
Duration slow = Duration(milliseconds: 300);

// Page transitions
Duration page = Duration(milliseconds: 250);
```

### Common Animations

```dart
// Container size change
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  // properties...
)

// Fade in/out
AnimatedOpacity(
  duration: Duration(milliseconds: 200),
  opacity: isVisible ? 1.0 : 0.0,
  child: widget,
)

// Size transition
AnimatedSize(
  duration: Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  child: widget,
)

// Cross fade between widgets
AnimatedSwitcher(
  duration: Duration(milliseconds: 200),
  child: currentWidget,
)
```

---

## 11. Accessibility

### Guidelines

1. **Minimum Touch Target** - 48x48 logical pixels
2. **Color Contrast** - WCAG AA minimum (4.5:1 for text)
3. **Text Scaling** - Support up to 2x text scale
4. **Semantic Labels** - Add labels for screen readers

### Implementation

```dart
// Touch targets
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: () {},
  ),
)

// Semantic labels
Semantics(
  label: 'Add new patient',
  button: true,
  child: FloatingActionButton(
    onPressed: () {},
    child: Icon(Icons.add),
  ),
)

// Exclude decorative elements
Semantics(
  excludeSemantics: true,
  child: decorativeImage,
)
```

---

## 12. Dark Mode

### Color Mapping

| Element | Light Mode | Dark Mode |
|---------|------------|-----------|
| Background | #F8F9FA | #0F0F0F |
| Surface | #FFFFFF | #1A1A1A |
| Text Primary | #111827 | #FFFFFF |
| Text Secondary | #6B7280 | #9CA3AF |
| Dividers | #E5E7EB | #374151 |
| Card Shadow | 5% black | 0% (none) |

### Implementation Pattern

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    color: isDark ? Color(0xFF1A1A1A) : Colors.white,
    child: Text(
      'Hello',
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
    ),
  );
}
```

---

## 13. Responsive Design

### Breakpoints

```dart
class AppBreakpoint {
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1440;
}

// Usage
final screenWidth = MediaQuery.of(context).size.width;
final isCompact = screenWidth < 400;
final isTablet = screenWidth >= 600;
final isDesktop = screenWidth >= 1024;
```

### Responsive Patterns

```dart
// Responsive padding
final padding = isCompact ? 16.0 : 20.0;

// Responsive grid
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  // ...
)

// Responsive layout
Row/Column switching
isTablet
    ? Row(children: [widget1, widget2])
    : Column(children: [widget1, widget2])
```

---

## 14. Code Examples

### Complete Section Card Example

```dart
Widget _buildPatientSection(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          _buildPatientSelector(),
        ],
      ),
    ),
  );
}
```

### Complete Screen Structure Example

```dart
class ExampleScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends ConsumerState<ExampleScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            leading: _buildBackButton(isDark),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(isDark),
            ),
          ),
          // Content
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection1(isDark),
                const SizedBox(height: 16),
                _buildSection2(isDark),
                const SizedBox(height: 16),
                _buildSection3(isDark),
                const SizedBox(height: 24),
                _buildSaveButton(isDark),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 22,
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
              : [Colors.white, const Color(0xFFF8F9FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Screen Title',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Subtitle or description',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Quick Reference Card

### Colors (Hex)

| Name | Light | Dark |
|------|-------|------|
| Primary | #3B82F6 | #3B82F6 |
| Success | #10B981 | #10B981 |
| Warning | #F59E0B | #F59E0B |
| Error | #EF4444 | #EF4444 |
| Background | #F8F9FA | #0F0F0F |
| Surface | #FFFFFF | #1A1A1A |
| Text | #111827 | #FFFFFF |

### Spacing (px)

| Name | Value |
|------|-------|
| xs | 4 |
| sm | 8 |
| md | 12 |
| lg | 16 |
| xl | 20 |
| xxl | 24 |

### Border Radius (px)

| Component | Value |
|-----------|-------|
| Chips | 10-12 |
| Inputs | 14 |
| Buttons | 16 |
| Cards | 20 |
| Bottom Sheet | 24 |

### Typography (px)

| Style | Size | Weight |
|-------|------|--------|
| Headline 1 | 28 | 800 |
| Headline 2 | 24 | 700 |
| Title 1 | 18 | 700 |
| Title 2 | 16 | 600 |
| Body 1 | 16 | 400 |
| Body 2 | 14 | 400 |
| Caption | 12 | 500 |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | Dec 3, 2025 | Modern redesign with gradients, shadows, section cards |
| 1.0 | Nov 2024 | Initial design system |

---

*This document should be referenced when implementing any new screens or updating existing ones to maintain consistency across the application.*
