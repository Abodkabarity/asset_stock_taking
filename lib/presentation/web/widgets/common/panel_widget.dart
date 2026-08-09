part of '../../../pages/web_asset_dashboard_page.dart';

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool expandChild;

  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
    this.expandChild = false,
  });

  @override
  Widget build(BuildContext context) {
    return WebHoverSurface(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty || trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 15),
              child: Row(
                children: [
                  if (title.isNotEmpty)
                    if (trailing == null)
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                  if (trailing != null) const SizedBox(width: 10),
                  if (trailing != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailing!,
                      ),
                    ),
                ],
              ),
            ),
          if (title.isNotEmpty || trailing != null)
            const Divider(height: 1, color: AppColors.border),
          if (expandChild)
            Expanded(
              child: Padding(padding: const EdgeInsets.all(20), child: child),
            )
          else
            Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}
