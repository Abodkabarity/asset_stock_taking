import 'package:flutter/material.dart';

Future<DateTime?> showWebSingleDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Select date',
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xff0b1730).withValues(alpha: .38),
    builder: (_) => _WebSingleDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
    ),
  );
}

class _WebSingleDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const _WebSingleDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  @override
  State<_WebSingleDatePickerDialog> createState() =>
      _WebSingleDatePickerDialogState();
}

class _WebSingleDatePickerDialogState
    extends State<_WebSingleDatePickerDialog> {
  late DateTime selectedDate;
  late DateTime visibleMonth;

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    final first = _day(widget.firstDate);
    final last = _day(widget.lastDate);
    final initial = _day(widget.initialDate);
    selectedDate = initial.isBefore(first)
        ? first
        : initial.isAfter(last)
        ? last
        : initial;
    visibleMonth = DateTime(selectedDate.year, selectedDate.month);
  }

  bool get canGoBack {
    final previous = DateTime(visibleMonth.year, visibleMonth.month - 1);
    return !DateTime(
      previous.year,
      previous.month + 1,
      0,
    ).isBefore(_day(widget.firstDate));
  }

  bool get canGoForward {
    final next = DateTime(visibleMonth.year, visibleMonth.month + 1);
    return !next.isAfter(_day(widget.lastDate));
  }

  bool _enabled(DateTime date) {
    final day = _day(date);
    return !day.isBefore(_day(widget.firstDate)) &&
        !day.isAfter(_day(widget.lastDate));
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  String _shortMonth(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: 430,
        height: 470,
        child: Material(
          color: Colors.white,
          elevation: 24,
          shadowColor: const Color(0xff061831).withValues(alpha: .18),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(),
              const Divider(height: 1, color: Color(0xffe5ebf3)),
              _monthNavigation(),
              Expanded(child: _calendar()),
              const Divider(height: 1, color: Color(0xffe5ebf3)),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => SizedBox(
    height: 74,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff4263eb), Color(0xff15aabf)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1769ff).withValues(alpha: .22),
                  blurRadius: 15,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xff17243b),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${selectedDate.day} ${_shortMonth(selectedDate.month)} ${selectedDate.year}',
                  style: const TextStyle(
                    color: Color(0xff71809a),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xff536178),
              size: 21,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _monthNavigation() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
    child: Row(
      children: [
        Text(
          '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
          style: const TextStyle(
            color: Color(0xff263650),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _arrow(
          Icons.chevron_left_rounded,
          canGoBack
              ? () => setState(
                  () => visibleMonth = DateTime(
                    visibleMonth.year,
                    visibleMonth.month - 1,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 7),
        _arrow(
          Icons.chevron_right_rounded,
          canGoForward
              ? () => setState(
                  () => visibleMonth = DateTime(
                    visibleMonth.year,
                    visibleMonth.month + 1,
                  ),
                )
              : null,
        ),
      ],
    ),
  );

  Widget _arrow(IconData icon, VoidCallback? onTap) => Material(
    color: const Color(0xfff5f8fc),
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffdfe7f1)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 19,
          color: onTap == null
              ? const Color(0xffc2cad5)
              : const Color(0xff607089),
        ),
      ),
    ),
  );

  Widget _calendar() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final days = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final leading = DateTime(visibleMonth.year, visibleMonth.month).weekday % 7;
    final today = _day(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: weekdays
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xff8492a7),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 9),
          for (var week = 0; week < 6; week++)
            Expanded(
              child: Row(
                children: List.generate(7, (weekday) {
                  final number = week * 7 + weekday - leading + 1;
                  if (number < 1 || number > days) {
                    return const Expanded(child: SizedBox());
                  }
                  final date = DateTime(
                    visibleMonth.year,
                    visibleMonth.month,
                    number,
                  );
                  final enabled = _enabled(date);
                  final selected = DateUtils.isSameDay(date, selectedDate);
                  final isToday = DateUtils.isSameDay(date, today);

                  return Expanded(
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: enabled
                              ? () => setState(() => selectedDate = date)
                              : null,
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xff1769ff)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isToday && !selected
                                  ? Border.all(
                                      color: const Color(0xff25b6cc),
                                      width: 1.4,
                                    )
                                  : null,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xff1769ff,
                                        ).withValues(alpha: .25),
                                        blurRadius: 12,
                                        spreadRadius: -4,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              '$number',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : enabled
                                    ? const Color(0xff34435a)
                                    : const Color(0xffc5ccd6),
                                fontSize: 11.5,
                                fontWeight: selected || isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer() => SizedBox(
    height: 61,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              final today = _day(DateTime.now());
              if (!_enabled(today)) return;
              setState(() {
                selectedDate = today;
                visibleMonth = DateTime(today.year, today.month);
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff52627b),
              side: const BorderSide(color: Color(0xffdfe7f1)),
              minimumSize: const Size(86, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            icon: const Icon(Icons.today_rounded, size: 16),
            label: const Text(
              'Today',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xff65748b)),
            ),
          ),
          const SizedBox(width: 7),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedDate),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xff1769ff),
              foregroundColor: Colors.white,
              minimumSize: const Size(92, 39),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Select',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}
