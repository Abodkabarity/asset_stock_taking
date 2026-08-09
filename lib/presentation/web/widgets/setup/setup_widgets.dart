part of '../../../pages/web_asset_dashboard_page.dart';

class _SetupHero extends StatelessWidget {
  final bool branchesMode;
  final int count;
  final VoidCallback onAdd;

  const _SetupHero({
    required this.branchesMode,
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 136),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff102b50), Color(0xff174b82), Color(0xff2463a8)],
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff174b82).withValues(alpha: .22),
          blurRadius: 32,
          spreadRadius: -10,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            right: -75,
            top: -105,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .055),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .17),
                    ),
                  ),
                  child: Icon(
                    branchesMode
                        ? Icons.account_balance_outlined
                        : Icons.category_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            branchesMode ? 'Branch Directory' : 'Asset Master',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.6,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count records',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        branchesMode
                            ? 'Create and maintain pharmacy branches used throughout the web system.'
                            : 'Manage the definitions used when creating assets and inventory records.',
                        style: const TextStyle(
                          color: Color(0xffd9e8f8),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff174b82),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    branchesMode
                        ? Icons.add_business_outlined
                        : Icons.add_box_outlined,
                    size: 19,
                  ),
                  label: Text(
                    branchesMode ? 'Add Branch' : 'Add Asset',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SetupTypePill extends StatelessWidget {
  final String value;

  const _SetupTypePill({required this.value});

  @override
  Widget build(BuildContext context) {
    final inventory = value.toLowerCase() == 'inventory';
    final color = inventory ? const Color(0xff7950f2) : const Color(0xff1769ff);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Text(
          value.isEmpty ? '-' : value,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SetupOptionHero extends StatelessWidget {
  final String title;
  final String singular;
  final IconData icon;
  final int count;
  final VoidCallback onAdd;

  const _SetupOptionHero({
    required this.title,
    required this.singular,
    required this.icon,
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 136),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff102b50), Color(0xff174b82), Color(0xff2463a8)],
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff174b82).withValues(alpha: .22),
          blurRadius: 32,
          spreadRadius: -10,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .17)),
          ),
          child: Icon(icon, color: Colors.white, size: 27),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count options',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Manage the options shown in every Asset Master dropdown.',
                style: const TextStyle(color: Color(0xffd9e8f8), fontSize: 12),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xff174b82),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Add $singular',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _SetupEmptyState extends StatelessWidget {
  final String label;
  final bool hasSearch;
  final VoidCallback onAdd;

  const _SetupEmptyState({
    required this.label,
    required this.hasSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 245,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xffedf4ff),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch ? Icons.search_off_rounded : Icons.add_box_outlined,
              color: const Color(0xff4263eb),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch ? 'No matching records' : 'No $label records yet',
            style: const TextStyle(
              color: Color(0xff26354d),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 13),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Add $label',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4263eb),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
