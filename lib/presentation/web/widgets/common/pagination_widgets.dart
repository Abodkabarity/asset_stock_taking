part of '../../../pages/web_asset_dashboard_page.dart';

class _PagedItems<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const _PagedItems({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    var firstPage = currentPage - 2;
    if (firstPage < 0) firstPage = 0;
    var lastPage = firstPage + 4;
    if (lastPage >= totalPages) lastPage = totalPages - 1;
    firstPage = (lastPage - 4).clamp(0, totalPages - 1);

    final firstItem = currentPage * pageSize + 1;
    final lastItem = ((currentPage + 1) * pageSize).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            'Showing $firstItem–$lastItem of $totalItems assets',
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _PaginationIconButton(
            tooltip: 'First page',
            icon: Icons.first_page,
            enabled: currentPage > 0,
            onPressed: () => onPageChanged(0),
          ),
          _PaginationIconButton(
            tooltip: 'Previous page',
            icon: Icons.chevron_left,
            enabled: currentPage > 0,
            onPressed: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 6),
          for (var page = firstPage; page <= lastPage; page++) ...[
            _PaginationPageButton(
              page: page,
              selected: page == currentPage,
              onPressed: () => onPageChanged(page),
            ),
            if (page != lastPage) const SizedBox(width: 5),
          ],
          const SizedBox(width: 6),
          _PaginationIconButton(
            tooltip: 'Next page',
            icon: Icons.chevron_right,
            enabled: currentPage < totalPages - 1,
            onPressed: () => onPageChanged(currentPage + 1),
          ),
          _PaginationIconButton(
            tooltip: 'Last page',
            icon: Icons.last_page,
            enabled: currentPage < totalPages - 1,
            onPressed: () => onPageChanged(totalPages - 1),
          ),
        ],
      ),
    );
  }
}

class _PaginationIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PaginationIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
    );
  }
}

class _PaginationPageButton extends StatelessWidget {
  final int page;
  final bool selected;
  final VoidCallback onPressed;

  const _PaginationPageButton({
    required this.page,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected ? Colors.white : AppColors.headerText,
          backgroundColor: selected ? AppColors.primaryColor : Colors.white,
          side: BorderSide(
            color: selected ? AppColors.primaryColor : AppColors.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          '${page + 1}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
