import 'package:chicaparts_partner/api/traveler/api_accommodation_traveler.dart';
import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';
import 'package:chicaparts_partner/widgets/traveler/book/book_app_bar.dart';
import 'package:chicaparts_partner/widgets/traveler/book/booking_step_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';

class SelectBookingDetailsPage extends StatefulWidget {
  final double pricePerNight;
  final int idAcc;
  final String currency;
  final double cleaningFees;
  final int roomId;
  final int propId;
  final int capacity;

  const SelectBookingDetailsPage({
    super.key,
    required this.pricePerNight,
    required this.idAcc,
    required this.currency,
    required this.cleaningFees,
    required this.roomId,
    required this.propId,
    required this.capacity,
  });

  @override
  _SelectBookingDetailsPageState createState() =>
      _SelectBookingDetailsPageState();
}

class _SelectBookingDetailsPageState extends State<SelectBookingDetailsPage> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _adults = 1;
  int _children = 0;
  double _totalPrice = 0.0;
  DateTime _focusedDay = DateTime.now();
  final apiBooking = ApiBooking();
  final apiAccommodation = ApiAccommodationTraveler();
  List<DateTime> availableDates = [];
  Map<DateTime, double> availablePrices = {};
  String _houseRulesText = '';
  Map<String, dynamic> _houseRules = const {};
  bool _isLoading = true;

  int get _totalTravelers => _adults + _children;
  int get _remainingCapacity => widget.capacity - _totalTravelers;
  bool get _hasValidStay =>
      _checkInDate != null && _checkOutDate != null && _totalPrice > 0;

  String displayPrice = '';

  @override
  void initState() {
    super.initState();
    _getAvailibilities();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: buildBookAppBar(lang.t('select_stay')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
          children: [
            const BookingStepIndicator(currentStep: 1),
            const SizedBox(height: 14),
            _sectionCard(
              title: lang.t('date_select'),
              icon: Icons.calendar_month_outlined,
              child: _buildCalendar(),
            ),
            const SizedBox(height: 14),
            _buildTravelersSection(lang),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(lang),
    );
  }

  Future<void> _getAvailibilities() async {
    setState(() => _isLoading = true);
    try {
      final response = await apiBooking.fetchAvailabilities(widget.idAcc);
      String houseRulesText = '';
      Map<String, dynamic> houseRules = const {};
      try {
        final details =
            await apiAccommodation.fetchAccommodationDetails(widget.idAcc);
        if (details is Map) {
          houseRulesText =
              _plainText(details['rule_of_procedure']?.toString() ?? '');
          final rawRules = details['house_rules'];
          if (rawRules is Map) {
            houseRules = Map<String, dynamic>.from(rawRules);
          }
        }
      } catch (e) {
        debugPrint('Error fetching house rules: $e');
      }
      setState(() {
        availablePrices = response.map(
          (key, value) => MapEntry(_dateOnly(key), value),
        );
        availableDates = availablePrices.keys.toList();
        _houseRulesText = houseRulesText;
        _houseRules = houseRules;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching availabilities: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final colors = Theme.of(context).colorScheme;
    final today = _dateOnly(DateTime.now());

    return _isLoading
        ? _buildShimmerLoader()
        : TableCalendar(
            focusedDay: _focusedDay,
            firstDay: today,
            lastDay: DateTime.now().add(const Duration(days: 365)),
            selectedDayPredicate: (date) =>
                isSameDay(date, _checkInDate) || isSameDay(date, _checkOutDate),
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            rangeStartDay: _checkInDate,
            rangeEndDay: _checkOutDate,
            onDaySelected: _handleDaySelected,
            enabledDayPredicate: (date) => _isAvailable(date),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
              weekendTextStyle: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
              rangeHighlightColor: colors.primary.withOpacity(0.16),
              rangeStartDecoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: Color(0xFF21A35B),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 2),
              ),
              todayTextStyle: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
              outsideDaysVisible: true,
            ),
            calendarBuilders: CalendarBuilders(
              outsideBuilder: (context, date, focusedDay) {
                if (!date.isBefore(today)) return null;
                return Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.16),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              },
              disabledBuilder: (context, date, focusedDay) {
                final day = _dateOnly(date);
                final isPast = day.isBefore(today);
                final isToday = isSameDay(day, today);

                if (isPast) {
                  return Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.18),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }

                return Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.55),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: colors.primary, width: 2)
                          : null,
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isToday
                            ? colors.primary
                            : colors.onSurfaceVariant.withOpacity(0.62),
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: colors.error,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: colors.onSurfaceVariant),
              weekendStyle: TextStyle(color: colors.onSurfaceVariant),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left),
              rightChevronIcon: Icon(Icons.chevron_right),
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
  }

  Widget _buildShimmerLoader() {
    final colors = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHighest,
      highlightColor: colors.surfaceContainer,
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTravelersSection(LanguageProvider lang) {
    return _sectionCard(
      title: lang.t('travelers'),
      icon: Icons.groups_2_outlined,
      child: Row(
        children: [
          _buildTravelerSelector(
            lang.t('adults'),
            _adults,
            (value) => setState(() => _adults = value),
            max: widget.capacity - _children,
            min: 1,
          ),
          const SizedBox(width: 10),
          _buildTravelerSelector(
            lang.t('children'),
            _children,
            (value) => setState(() => _children = value),
            max: widget.capacity - _adults,
            min: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildTravelerSelector(
    String label,
    int value,
    Function(int) onChanged, {
    required int max,
    int min = 0,
  }) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;
    final canDecrement = value > min;
    final canIncrement = value < max;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.55),
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _counterButton(
                  icon: Icons.remove,
                  enabled: canDecrement,
                  onPressed: () {
                    onChanged(value - 1);
                    _updateTotalPrice();
                  },
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _counterButton(
                  icon: Icons.add,
                  enabled: canIncrement,
                  onPressed: () {
                    onChanged(value + 1);
                    _updateTotalPrice();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${lang.t('capacity_short')}: ${widget.capacity}  ${lang.t('remaining_short')}: ${_remainingCapacity < 0 ? 0 : _remainingCapacity}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor:
              enabled ? colors.primary.withOpacity(0.10) : colors.surface,
          foregroundColor: enabled ? colors.primary : colors.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildBottomBar(LanguageProvider lang) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totalText = _totalPrice > 0 ? displayPrice : '--';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('total_price'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _continueToBilling(lang),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(
                  lang.t('continue'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToBilling(LanguageProvider lang) {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.t('select_checkin_checkout')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    if (!_hasValidStay) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.t('select_available_dates')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    final booking = BookingDetails(
      checkIn: _checkInDate!,
      checkOut: _checkOutDate!,
      adults: _adults,
      children: _children,
      totalPrice: _totalPrice,
      currency: widget.currency,
      cleaningFees: widget.cleaningFees,
      cityTaxe: _totalPrice * 0.12,
      propId: widget.propId,
      roomId: widget.roomId,
      houseRulesText: _houseRulesText,
      houseRules: _houseRules,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillingInfoPage(bookingDetails: booking),
      ),
    );
  }

  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final selected = _dateOnly(selectedDay);
    if (!_isAvailable(selected)) return;

    setState(() {
      _focusedDay = focusedDay;
      if (_checkInDate == null ||
          (selected.isBefore(_checkInDate!) && _checkOutDate == null)) {
        _checkInDate = selected;
        _checkOutDate = null;
      } else if (_checkOutDate == null && selected.isAfter(_checkInDate!)) {
        if (_isRangeAvailable(_checkInDate!, selected)) {
          _checkOutDate = selected;
        } else {
          _checkInDate = selected;
          _checkOutDate = null;
          _totalPrice = 0;
          displayPrice = '';
        }
      } else {
        _checkInDate = selected;
        _checkOutDate = null;
        _totalPrice = 0;
        displayPrice = '';
      }
      _updateTotalPrice();
    });
  }

  bool _isAvailable(DateTime date) {
    return availablePrices.containsKey(_dateOnly(date));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isRangeAvailable(DateTime start, DateTime end) {
    DateTime currentDate = _dateOnly(start);
    while (currentDate.isBefore(_dateOnly(end))) {
      if (!_isAvailable(currentDate)) return false;
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return true;
  }

  void _updateTotalPrice() {
    if (_checkInDate != null && _checkOutDate != null) {
      double basePrice = 0.0;
      DateTime currentDate = _dateOnly(_checkInDate!);
      while (currentDate.isBefore(_checkOutDate!)) {
        final price = availablePrices[_dateOnly(currentDate)];
        basePrice += _effectiveNightPrice(price);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      final extraTravelers =
          (_adults + _children) > 2 ? (_adults + _children - 2) : 0;
      final extraCostPerTraveler = CurrencyConverter.convert(
        amount: 10,
        from: 'EUR',
        to: widget.currency,
        rates: context.read<ExchangeRateProvider>().rates,
      );
      final extraCost = extraTravelers * extraCostPerTraveler;
      final rates = context.read<ExchangeRateProvider>().rates;

      setState(() {
        _totalPrice = basePrice + extraCost;
        displayPrice = CurrencyConverter.format(
          _totalPrice,
          from: widget.currency,
          to: context.read<CurrencyProvider>().currency,
          rates: rates,
        );
      });
    } else {
      setState(() {
        _totalPrice = 0;
        displayPrice = '';
      });
    }
  }

  double _effectiveNightPrice(double? availabilityPrice) {
    if (availabilityPrice != null && availabilityPrice > 0) {
      return availabilityPrice;
    }
    return widget.pricePerNight > 0 ? widget.pricePerNight : 0.0;
  }

  String _plainText(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s+'), '\n')
        .trim();
  }
}

class BookingDetails {
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final double totalPrice;
  final String currency;
  final double cleaningFees;
  final double cityTaxe;
  final double chicapartsFees;
  final int propId;
  final int roomId;
  final String houseRulesText;
  final Map<String, dynamic> houseRules;

  BookingDetails({
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.totalPrice,
    required this.currency,
    required this.cleaningFees,
    required this.cityTaxe,
    required this.propId,
    required this.roomId,
    required this.houseRulesText,
    required this.houseRules,
  }) : chicapartsFees = totalPrice * 0.10;

  double get finalPrice =>
      totalPrice + cleaningFees + cityTaxe + chicapartsFees;

  Map<String, dynamic> toJson() => {
        'propId': propId,
        'roomId': roomId,
        'firstNight': checkIn.toIso8601String().split('T')[0],
        'lastNight': checkOut.toIso8601String().split('T')[0],
        'numAdult': adults,
        'numChild': children,
        'price': totalPrice.toStringAsFixed(2),
        'currency': _normalizedCurrency,
        'tax': cityTaxe.toStringAsFixed(2),
        'commission': chicapartsFees.toStringAsFixed(2),
        'cleaning_fees_partner': cleaningFees.toStringAsFixed(2),
        'house_rules_accepted': true,
      };

  String get _normalizedCurrency {
    final value = currency.trim().toUpperCase();
    if (value == 'FCFA' || value == 'CFA' || value == 'XOF') return 'XAF';
    return value;
  }
}
