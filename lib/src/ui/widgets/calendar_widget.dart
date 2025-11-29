import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime? focusedMonth;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, int>? appointmentCounts;
  final bool showMonthPicker;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    this.focusedMonth,
    required this.onDateSelected,
    this.appointmentCounts,
    this.showMonthPicker = true,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedMonth;
  late PageController _pageController;
  int _currentPage = 1000;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getMonthFromPage(int page) {
    final baseDate = DateTime.now();
    final diff = page - 1000;
    return DateTime(baseDate.year, baseDate.month + diff, 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
        final isLargeScreen = screenWidth >= 600;
        
        // Calculate cell size based on available width - larger cells for mobile
        final horizontalPadding = isSmallScreen ? 8.0 : 16.0;
        final cellSpacing = isSmallScreen ? 4.0 : 6.0;
        final availableWidth = screenWidth - (horizontalPadding * 2);
        final cellSize = (availableWidth - (cellSpacing * 6)) / 7;
        
        // Calculate grid height (6 rows) - taller for better visibility
        final gridHeight = (cellSize * 6) + (cellSpacing * 5) + 8;
        
        // Font sizes - increased for better readability on mobile
        final headerFontSize = isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 22.0);
        final dayFontSize = isSmallScreen ? 15.0 : (isMediumScreen ? 16.0 : 18.0);
        final weekdayFontSize = isSmallScreen ? 12.0 : 14.0;
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showMonthPicker) 
                _buildMonthHeader(context, headerFontSize, isSmallScreen, isDark),
              _buildWeekdayHeaders(weekdayFontSize, horizontalPadding, isDark),
              SizedBox(height: isSmallScreen ? 4 : 8),
              SizedBox(
                height: gridHeight,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                      _focusedMonth = _getMonthFromPage(page);
                    });
                  },
                  itemBuilder: (context, page) {
                    final month = _getMonthFromPage(page);
                    return _buildMonthGrid(
                      month, 
                      cellSize, 
                      cellSpacing, 
                      horizontalPadding,
                      dayFontSize,
                      isDark,
                    );
                  },
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthHeader(BuildContext context, double fontSize, bool isSmall, bool isDark) {
    final padding = isSmall ? 16.0 : 24.0;
    final iconSize = isSmall ? 26.0 : 30.0;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, padding * 0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(Icons.chevron_left_rounded, () {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, iconSize, isDark),
          Flexible(
            child: GestureDetector(
              onTap: () => _showMonthPicker(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 14 : 20, 
                  vertical: isSmall ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_focusedMonth),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      size: isSmall ? 22 : 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildNavButton(Icons.chevron_right_rounded, () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, iconSize, isDark),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap, double iconSize, bool isDark) {
    return Material(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(iconSize * 0.35),
          child: Icon(
            icon,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeaders(double fontSize, double horizontalPadding, bool isDark) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthGrid(
    DateTime month, 
    double cellSize, 
    double spacing,
    double horizontalPadding,
    double fontSize,
    bool isDark,
  ) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    final daysInMonth = lastDay.day;
    final today = DateTime.now();
    const totalCells = 42;
    
    final borderRadius = cellSize * 0.2;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final dayNumber = index - firstWeekday + 1;
          
          if (index < firstWeekday || dayNumber > daysInMonth) {
            return const SizedBox();
          }
          
          final date = DateTime(month.year, month.month, dayNumber);
          final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
          final isToday = DateUtils.isSameDay(date, today);
          
          return GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected 
                    ? null 
                    : (isToday 
                        ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1) 
                        : (isDark ? AppColors.darkBackground.withOpacity(0.5) : null)),
                borderRadius: BorderRadius.circular(borderRadius),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isToday 
                            ? (isDark ? AppColors.primaryLight : AppColors.primary) 
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              child: Text(
                'Select Month',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: isSmallScreen ? 18 : 22,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: isSmallScreen ? 2.2 : 2,
                  crossAxisSpacing: isSmallScreen ? 8 : 12,
                  mainAxisSpacing: isSmallScreen ? 8 : 12,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = DateTime(_focusedMonth.year, index + 1, 1);
                  final isCurrentMonth = month.month == DateTime.now().month && 
                                         month.year == DateTime.now().year;
                  final isSelected = month.month == _focusedMonth.month &&
                                     month.year == _focusedMonth.year;
                  
                  return Material(
                    color: isSelected 
                        ? AppColors.primary 
                        : (isCurrentMonth 
                            ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1) 
                            : (isDark ? AppColors.darkBackground : AppColors.background)),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        final diff = (month.year - DateTime.now().year) * 12 + 
                                     (month.month - DateTime.now().month);
                        _pageController.animateToPage(
                          1000 + diff,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          DateFormat('MMM').format(month),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 13 : 15,
                            color: isSelected 
                                ? Colors.white 
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }
}
