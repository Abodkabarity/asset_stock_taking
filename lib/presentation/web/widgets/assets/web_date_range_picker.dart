part of '../../../pages/web_asset_dashboard_page.dart';

Future<DateTimeRange?> showWebDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialRange,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xff0b1730).withValues(alpha: .38),
    builder: (_) => _WebDateRangePickerDialog(initialRange: initialRange),
  );
}

class _WebDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialRange;

  const _WebDateRangePickerDialog({this.initialRange});

  @override
  State<_WebDateRangePickerDialog> createState() =>
      _WebDateRangePickerDialogState();
}

class _WebDateRangePickerDialogState extends State<_WebDateRangePickerDialog> {
  late DateTime visibleMonth;
  DateTime? start;
  DateTime? end;
  String? quickSelection;

  @override
  void initState() {
    super.initState();
    start = widget.initialRange?.start;
    end = widget.initialRange?.end;
    final reference = start ?? DateTime.now();
    visibleMonth = DateTime(reference.year, reference.month);
  }

  DateTime get secondMonth =>
      DateTime(visibleMonth.year, visibleMonth.month + 1);

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  void _selectDay(DateTime value) {
    setState(() {
      quickSelection = null;
      final selected = _day(value);
      if (start == null || end != null) {
        start = selected;
        end = null;
      } else if (selected.isBefore(start!)) {
        end = start;
        start = selected;
      } else {
        end = selected;
      }
    });
  }

  void _selectQuick(String label, DateTime from, DateTime to) {
    setState(() {
      quickSelection = label;
      start = _day(from);
      end = _day(to);
      visibleMonth = DateTime(start!.year, start!.month);
    });
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Select date';
    return '${_monthShort(value.month)} ${value.day}, ${value.year}';
  }

  String _monthShort(int month) => const [
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

  String _monthTitle(DateTime value) =>
      '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][value.month - 1]} ${value.year}';

  @override
  Widget build(BuildContext context) {
    final now = _day(DateTime.now());

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: 850,
        height: 500,
        child: Material(
          color: Colors.white,
          elevation: 24,
          shadowColor: const Color(0xff061831).withValues(alpha: .16),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(
                width: 158,
                color: const Color(0xfff7f9fc),
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 9, bottom: 8),
                      child: Text(
                        'QUICK SELECT',
                        style: TextStyle(
                          color: Color(0xff8492a8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .45,
                        ),
                      ),
                    ),
                    _quickItem('Today', () => _selectQuick('Today', now, now)),
                    _quickItem('Yesterday', () {
                      final yesterday = now.subtract(const Duration(days: 1));
                      _selectQuick('Yesterday', yesterday, yesterday);
                    }),
                    _quickItem(
                      'This Week',
                      () => _selectQuick(
                        'This Week',
                        now.subtract(Duration(days: now.weekday - 1)),
                        now,
                      ),
                    ),
                    _quickItem(
                      'Last 7 Days',
                      () => _selectQuick(
                        'Last 7 Days',
                        now.subtract(const Duration(days: 6)),
                        now,
                      ),
                    ),
                    _quickItem(
                      'This Month',
                      () => _selectQuick(
                        'This Month',
                        DateTime(now.year, now.month),
                        DateTime(now.year, now.month + 1, 0),
                      ),
                    ),
                    _quickItem(
                      'Last 30 Days',
                      () => _selectQuick(
                        'Last 30 Days',
                        now.subtract(const Duration(days: 29)),
                        now,
                      ),
                    ),
                    _quickItem(
                      'Last 3 Months',
                      () => _selectQuick(
                        'Last 3 Months',
                        DateTime(now.year, now.month - 2),
                        now,
                      ),
                    ),
                    _quickItem(
                      'Last 6 Months',
                      () => _selectQuick(
                        'Last 6 Months',
                        DateTime(now.year, now.month - 5),
                        now,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, color: const Color(0xffe5ebf3)),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 66,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _navigationButton(
                              Icons.chevron_left_rounded,
                              () => setState(
                                () => visibleMonth = DateTime(
                                  visibleMonth.year,
                                  visibleMonth.month - 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _navigationButton(
                              Icons.chevron_right_rounded,
                              () => setState(
                                () => visibleMonth = DateTime(
                                  visibleMonth.year,
                                  visibleMonth.month + 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            _rangeBox('From', _dateLabel(start), true),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 9),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Color(0xff8190a7),
                              ),
                            ),
                            _rangeBox('To', _dateLabel(end), false),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 21,
                                color: Color(0xff526077),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xffe5ebf3)),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _calendar(visibleMonth)),
                          Container(width: 1, color: const Color(0xffe5ebf3)),
                          Expanded(child: _calendar(secondMonth)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xffe5ebf3)),
                    SizedBox(
                      height: 53,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Text(
                              start == null
                                  ? 'Choose a start and end date'
                                  : '${_dateLabel(start)}  -  ${_dateLabel(end)}',
                              style: const TextStyle(
                                color: Color(0xff77869c),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
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
                              onPressed: start == null || end == null
                                  ? null
                                  : () => Navigator.pop(
                                      context,
                                      DateTimeRange(start: start!, end: end!),
                                    ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xff0bb6cf),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xffe4e8ed,
                                ),
                                disabledForegroundColor: const Color(
                                  0xffa7adb6,
                                ),
                                minimumSize: const Size(80, 35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
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

  Widget _quickItem(String label, VoidCallback onTap) {
    final selected = quickSelection == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? const Color(0xffdff7fb) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(color: const Color(0xff8cdeea))
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xff08a9c1)
                    : const Color(0xff4c5b72),
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationButton(IconData icon, VoidCallback onTap) => Material(
    color: const Color(0xfff5f8fc),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffdfe7f1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xff6c7c92)),
      ),
    ),
  );

  Widget _rangeBox(String label, String value, bool active) => Container(
    height: 43,
    constraints: const BoxConstraints(minWidth: 96),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: active ? const Color(0xffeffcff) : const Color(0xfff8fafd),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: active ? const Color(0xff78dceb) : const Color(0xffdfe6f0),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff8b98ab),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: active ? const Color(0xff08abc3) : const Color(0xff34435a),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _calendar(DateTime month) {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = DateTime(month.year, month.month).weekday % 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 9),
      child: Column(
        children: [
          Text(
            _monthTitle(month),
            style: const TextStyle(
              color: Color(0xff2b3950),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: weekdays
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xff78879d),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 7),
          for (var week = 0; week < 6; week++)
            Row(
              children: List.generate(7, (weekday) {
                final dayNumber = week * 7 + weekday - leading + 1;
                if (dayNumber < 1 || dayNumber > days) {
                  return const Expanded(child: SizedBox(height: 39));
                }
                final date = DateTime(month.year, month.month, dayNumber);
                final isStart =
                    start != null && DateUtils.isSameDay(start, date);
                final isEnd = end != null && DateUtils.isSameDay(end, date);
                final inRange =
                    start != null &&
                    end != null &&
                    date.isAfter(start!) &&
                    date.isBefore(end!);
                final hasCompleteRange = start != null && end != null;
                final rangeCell =
                    inRange || (hasCompleteRange && (isStart || isEnd));

                return Expanded(
                  child: InkWell(
                    onTap: () => _selectDay(date),
                    child: Container(
                      height: 39,
                      alignment: Alignment.center,
                      color: rangeCell ? const Color(0xffcef3f8) : null,
                      child: Container(
                        width: 29,
                        height: 29,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isStart || isEnd
                              ? const Color(0xff08b5cf)
                              : null,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: isStart || isEnd
                                ? Colors.white
                                : inRange
                                ? const Color(0xff08abc3)
                                : const Color(0xff425168),
                            fontSize: 10.5,
                            fontWeight: isStart || isEnd
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
