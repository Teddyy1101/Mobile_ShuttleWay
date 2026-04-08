import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../profile/controllers/profile_controller.dart';

/// Màn hình lịch sử vé — mở từ nút "Lịch sử" ở Quick Actions.
class TicketHistoryScreen extends StatefulWidget {
  final ProfileController profileController;
  final List<ChildModel> children;

  const TicketHistoryScreen({
    super.key,
    required this.profileController,
    required this.children,
  });

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  String? _filterTicketType;
  String? _filterChildId;
  int _displayLimit = 15;
  static const int _pageSize = 15;
  bool get _isParentMode => widget.children.isNotEmpty;

  /// Label hiển thị filter hiện tại (ở AppBar).
  String get _filterLabel {
    final parts = <String>[];
    if (_filterTicketType == 'MONTHLY') {
      parts.add('Vé tháng');
    } else if (_filterTicketType == 'SINGLE') {
      parts.add('Vé lượt');
    }
    if (_filterChildId != null) {
      final child = widget.children.firstWhere(
        (c) => c.id == _filterChildId,
        orElse: () => widget.children.first,
      );
      parts.add(child.fullName);
    }
    return parts.isEmpty ? 'Tất cả' : parts.join(' • ');
  }

  /// Đếm số filter đang active.
  int get _activeFilterCount {
    int count = 0;
    if (_filterTicketType != null) count++;
    if (_filterChildId != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  void _fetchTickets() {
    widget.profileController.loadMyTickets(
      refresh: true,
      ticketType: _filterTicketType,
    );
  }

  /// Lọc vé theo student ID (client-side).
  List<TicketModel> get _filteredTickets {
    final tickets = widget.profileController.tickets;
    if (_filterChildId == null) return tickets;
    return tickets.where((t) => t.student?.id == _filterChildId).toList();
  }

  /// Tickets hiển thị (giới hạn bởi _displayLimit).
  List<TicketModel> get _visibleTickets {
    final all = _filteredTickets;
    if (all.length <= _displayLimit) return all;
    return all.sublist(0, _displayLimit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(theme, isDark, bgColor),
      body: ListenableBuilder(
        listenable: widget.profileController,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: () => widget.profileController.loadMyTickets(
              refresh: true,
              ticketType: _filterTicketType,
            ),
            child: _buildBody(theme, isDark),
          );
        },
      ),
    );
  }

  // AppBar 

  PreferredSizeWidget _buildAppBar(
      ThemeData theme, bool isDark, Color bgColor) {
    return AppBar(
      backgroundColor: bgColor.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _buildBackButton(theme, isDark),
      title: Text(
        'Lịch sử vé',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        _buildFilterButton(theme, isDark),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBackButton(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C252E) : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// Nút filter có badge đếm số filter active.
  Widget _buildFilterButton(ThemeData theme, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C252E) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => _showFilterDialog(theme, isDark),
          ),
        ),
        if (_activeFilterCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$_activeFilterCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Filter dialog

  void _showFilterDialog(ThemeData theme, bool isDark) {
    // Temp values để user preview trước khi apply
    String? tempType = _filterTicketType;
    String? tempChildId = _filterChildId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C252E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      'Bộ lọc',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ─── Loại vé ───
                    Text(
                      'Loại vé',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterChipGroup(
                      isDark: isDark,
                      theme: theme,
                      options: const [
                        (value: null, label: 'Tất cả'),
                        (value: 'MONTHLY', label: 'Vé tháng'),
                        (value: 'SINGLE', label: 'Vé lượt'),
                      ],
                      selectedValue: tempType,
                      onSelected: (val) =>
                          setSheetState(() => tempType = val),
                    ),
                    // ─── Học sinh (Parent only) ───
                    if (_isParentMode) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Học sinh',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFilterChipGroup(
                        isDark: isDark,
                        theme: theme,
                        options: [
                          (value: null, label: 'Tất cả'),
                          ...widget.children.map(
                            (c) => (value: c.id, label: c.fullName),
                          ),
                        ],
                        selectedValue: tempChildId,
                        onSelected: (val) =>
                            setSheetState(() => tempChildId = val),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // ─── Buttons ───
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                tempType = null;
                                tempChildId = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              'Xóa lọc',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _filterTicketType = tempType;
                                _filterChildId = tempChildId;
                                _displayLimit = _pageSize;
                              });
                              _fetchTickets();
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD),
                              ),
                            ),
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Nhóm chip lọc (dùng chung cho loại vé + học sinh).
  Widget _buildFilterChipGroup({
    required bool isDark,
    required ThemeData theme,
    required List<({String? value, String label})> options,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selectedValue == opt.value;
        return GestureDetector(
          onTap: () => onSelected(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : isDark
                      ? AppColors.darkCard
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              border: isSelected
                  ? null
                  : Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 0.5,
                    ),
            ),
            child: Text(
              opt.label.length > 20
                  ? '${opt.label.substring(0, 20)}…'
                  : opt.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.grey[300]
                        : Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Body

  Widget _buildBody(ThemeData theme, bool isDark) {
    final allFiltered = _filteredTickets;
    final visible = _visibleTickets;
    final hasMore = visible.length < allFiltered.length;

    if (widget.profileController.isLoading && allFiltered.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allFiltered.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: visible.length + 1 + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Header summary
        if (index == 0) {
          return _buildSummaryRow(theme, isDark, allFiltered.length);
        }
        // Load more button
        if (hasMore && index == visible.length + 1) {
          return _buildLoadMoreButton(theme, isDark);
        }
        // Ticket card
        final ticket = visible[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TicketHistoryCard(
            ticket: ticket,
            onTap: () => _showTicketDetail(ticket),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(ThemeData theme, bool isDark, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            'Danh sách vé',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C252E) : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$total vé',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
          ),
          const Spacer(),
          if (_activeFilterCount > 0)
            GestureDetector(
              onTap: () {
                setState(() {
                  _filterTicketType = null;
                  _filterChildId = null;
                  _displayLimit = _pageSize;
                });
                _fetchTickets();
              },
              child: Text(
                'Xóa lọc',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextButton.icon(
          onPressed: () {
            setState(() => _displayLimit += _pageSize);
          },
          icon: Icon(Icons.expand_more, size: 20,
              color: theme.colorScheme.primary),
          label: Text(
            'Xem thêm',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            backgroundColor: isDark
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: isDark ? Colors.grey[500] : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            _isParentMode ? 'Chưa có vé nào cho bé' : 'Bạn chưa có vé nào',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          if (_activeFilterCount > 0) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterTicketType = null;
                  _filterChildId = null;
                  _displayLimit = _pageSize;
                });
                _fetchTickets();
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  // Ticket detail bottom sheet

  void _showTicketDetail(TicketModel ticket) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C252E) : Colors.white;
    final isMonthly = ticket.ticketType == 'MONTHLY';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Icon + type
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      isMonthly ? theme.colorScheme.primary : Colors.orange,
                      isMonthly
                          ? theme.colorScheme.primary.withValues(alpha: 0.7)
                          : Colors.orange.withValues(alpha: 0.7),
                    ]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isMonthly
                                ? theme.colorScheme.primary
                                : Colors.orange)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isMonthly
                        ? Icons.confirmation_number_outlined
                        : Icons.local_activity_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isMonthly ? 'Vé tháng' : 'Vé lượt',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: ticket.status),
                const SizedBox(height: 24),
                _DetailRow(
                  isDark: isDark,
                  icon: Icons.route_outlined,
                  label: 'Tuyến',
                  value: ticket.route?.name ?? 'N/A',
                ),
                _DetailRow(
                  isDark: isDark,
                  icon: Icons.payments_outlined,
                  label: 'Giá vé',
                  value:
                      '${NumberFormat('#,###', 'vi_VN').format(ticket.priceAtBuy.abs())}đ',
                ),
                _DetailRow(
                  isDark: isDark,
                  icon: Icons.date_range_outlined,
                  label: 'Hiệu lực',
                  value:
                      '${DateFormat('dd/MM/yyyy').format(ticket.validFrom.toLocal())} → ${DateFormat('dd/MM/yyyy').format(ticket.validUntil.toLocal())}',
                ),
                if (ticket.student != null)
                  _DetailRow(
                    isDark: isDark,
                    icon: Icons.school_outlined,
                    label: 'Học sinh',
                    value: ticket.student!.fullName,
                  ),
                _DetailRow(
                  isDark: isDark,
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày mua',
                  value: DateFormat('dd/MM/yyyy HH:mm')
                      .format(ticket.createdAt.toLocal()),
                  isLast: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card hiển thị thông tin 1 vé trong danh sách.
class _TicketHistoryCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback? onTap;

  const _TicketHistoryCard({required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMonthly = ticket.ticketType == 'MONTHLY';
    final routeName = ticket.route?.name ?? 'N/A';
    final validStr =
        '${DateFormat('dd/MM').format(ticket.validFrom.toLocal())} → ${DateFormat('dd/MM/yyyy').format(ticket.validUntil.toLocal())}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingSM + 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isMonthly
                      ? [
                          colorScheme.primary.withValues(alpha: 0.15),
                          colorScheme.primary.withValues(alpha: 0.05),
                        ]
                      : [
                          Colors.orange.withValues(alpha: 0.15),
                          Colors.orange.withValues(alpha: 0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Icon(
                isMonthly
                    ? Icons.confirmation_number_outlined
                    : Icons.local_activity_outlined,
                size: 20,
                color: isMonthly ? colorScheme.primary : Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.paddingSM + 4),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isMonthly ? 'Vé tháng' : 'Vé lượt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusBadge(status: ticket.status),
                      const Spacer(),
                      Text(
                        '${_formatCurrency(ticket.priceAtBuy)}đ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routeName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        validStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                      if (ticket.student != null) ...[
                        const Spacer(),
                        Icon(
                          Icons.person_outline_rounded,
                          size: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ticket.student!.fullName,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.abs());
  }
}

/// Badge trạng thái vé (ACTIVE / EXPIRED / CANCELLED / PENDING).
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final info = _getInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: info.textColor,
        ),
      ),
    );
  }

  static ({String label, Color bgColor, Color textColor}) _getInfo(
      String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return (
          label: 'Đang dùng',
          bgColor: AppColors.success.withValues(alpha: 0.15),
          textColor: AppColors.success,
        );
      case 'EXPIRED':
        return (
          label: 'Hết hạn',
          bgColor: Colors.grey.withValues(alpha: 0.15),
          textColor: Colors.grey,
        );
      case 'CANCELLED':
        return (
          label: 'Đã hủy',
          bgColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
          textColor: const Color(0xFFEF4444),
        );
      case 'PENDING':
        return (
          label: 'Chờ TT',
          bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          textColor: const Color(0xFFF59E0B),
        );
      default:
        return (
          label: status,
          bgColor: Colors.grey.withValues(alpha: 0.15),
          textColor: Colors.grey,
        );
    }
  }
}

/// Row chi tiết trong bottom sheet vé.
class _DetailRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[500]),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark
                ? Colors.grey[800]!.withValues(alpha: 0.5)
                : Colors.grey[200],
          ),
      ],
    );
  }
}
