import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ticket_model.dart';
import '../controllers/profile_controller.dart';

/// Màn hình Quản lý vé dành cho học sinh.
class TicketManagementScreen extends StatefulWidget {
  final ProfileController controller;

  const TicketManagementScreen({
    super.key,
    required this.controller,
  });

  @override
  State<TicketManagementScreen> createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen> {
  int _selectedTabIndex = 0;

  /// Tab filter values: null = tất cả, MONTHLY, SINGLE
  final _tabFilters = [null, 'MONTHLY', 'SINGLE'];
  final _tabLabels = ['Tất cả', 'Vé tháng', 'Vé lượt'];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  void _fetchTickets() {
    widget.controller.loadMyTickets(
      refresh: true,
      ticketType: _tabFilters[_selectedTabIndex],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C252E) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Quản lý vé',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              // ── Tab filter ──
              SliverToBoxAdapter(
                child: _buildTabs(theme, isDark),
              ),

              // ── Header ──
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(theme, isDark),
                ),
              ),

              // ── Danh sách vé ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _buildTicketSliver(theme, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Tab filter ──────────────────────────────────────────

  Widget _buildTabs(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C252E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(_tabLabels.length, (index) {
            return _buildTabItem(
              theme: theme,
              isDark: isDark,
              label: _tabLabels[index],
              isSelected: _selectedTabIndex == index,
              onTap: () {
                setState(() => _selectedTabIndex = index);
                _fetchTickets();
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.grey[700] : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (isDark ? Colors.white : theme.primaryColor)
                  : (isDark ? Colors.grey[400] : Colors.grey[500]),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final total = widget.controller.ticketTotal;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Danh sách vé',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ],
    );
  }

  // ─── Ticket list ──────────────────────────────────────────

  Widget _buildTicketSliver(ThemeData theme, bool isDark) {
    final tickets = widget.controller.tickets;

    if (widget.controller.isLoading && tickets.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (tickets.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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
                'Chưa có vé nào',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == tickets.length) {
            // Load more button
            return _buildLoadMoreButton(theme, isDark);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTicketCard(tickets[index], theme, isDark),
          );
        },
        childCount: tickets.length + 1,
      ),
    );
  }

  Widget _buildLoadMoreButton(ThemeData theme, bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextButton.icon(
          onPressed: () => widget.controller.loadMyTickets(
            ticketType: _tabFilters[_selectedTabIndex],
          ),
          icon: Icon(
            Icons.expand_more,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          label: Text(
            'Xem thêm',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Ticket card ──────────────────────────────────────────

  Widget _buildTicketCard(TicketModel ticket, ThemeData theme, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C252E) : Colors.white;
    final isMonthly = ticket.ticketType == 'MONTHLY';
    final routeName = ticket.route?.name ?? 'N/A';
    final statusInfo = _getStatusInfo(ticket.status);
    final validStr =
        '${DateFormat('dd/MM/yyyy').format(ticket.validFrom.toLocal())} → ${DateFormat('dd/MM/yyyy').format(ticket.validUntil.toLocal())}';
    final priceStr = _formatCurrency(ticket.priceAtBuy);

    return GestureDetector(
      onTap: () => _showTicketDetail(context, ticket),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
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
                color: isMonthly
                    ? theme.primaryColor.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isMonthly
                    ? Icons.confirmation_number_outlined
                    : Icons.local_activity_outlined,
                size: 20,
                color: isMonthly ? theme.primaryColor : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isMonthly ? 'Vé tháng' : 'Vé lượt',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(statusInfo),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routeName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    validStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Price
            Text(
              '${priceStr}đ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ticket detail bottom sheet ────────────────────────────

  void _showTicketDetail(BuildContext context, TicketModel ticket) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C252E) : Colors.white;
    final isMonthly = ticket.ticketType == 'MONTHLY';
    final statusInfo = _getStatusInfo(ticket.status);

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
                _buildStatusBadge(statusInfo),
                const SizedBox(height: 24),
                // Detail rows
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.route_outlined,
                  label: 'Tuyến đường',
                  value: ticket.route?.name ?? 'N/A',
                ),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.schedule_outlined,
                  label: 'Ca',
                  value: _getShiftLabel(ticket.route?.shiftType),
                ),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.payments_outlined,
                  label: 'Giá vé',
                  value: '${_formatCurrency(ticket.priceAtBuy)}đ',
                ),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày mua',
                  value: DateFormat('dd/MM/yyyy HH:mm')
                      .format(ticket.createdAt.toLocal()),
                ),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.date_range_outlined,
                  label: 'Hiệu lực',
                  value:
                      '${DateFormat('dd/MM/yyyy').format(ticket.validFrom.toLocal())} → ${DateFormat('dd/MM/yyyy').format(ticket.validUntil.toLocal())}',
                ),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.person_outlined,
                  label: 'Người mua',
                  value: ticket.parent != null
                      ? '${ticket.parent!.fullName} (Phụ huynh)'
                      : 'Bạn',
                  isLast: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
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

  // ─── Helpers ──────────────────────────────────────────────

  ({String label, Color bgColor, Color textColor}) _getStatusInfo(
      String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return (
          label: 'Đang dùng',
          bgColor: const Color(0xFF22C55E).withValues(alpha: 0.2),
          textColor: const Color(0xFF22C55E),
        );
      case 'EXPIRED':
        return (
          label: 'Hết hạn',
          bgColor: Colors.grey.withValues(alpha: 0.2),
          textColor: Colors.grey,
        );
      case 'CANCELLED':
        return (
          label: 'Đã hủy',
          bgColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
          textColor: const Color(0xFFEF4444),
        );
      case 'PENDING':
        return (
          label: 'Chờ TT',
          bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
          textColor: const Color(0xFFF59E0B),
        );
      default:
        return (
          label: status,
          bgColor: Colors.grey.withValues(alpha: 0.2),
          textColor: Colors.grey,
        );
    }
  }

  Widget _buildStatusBadge(
      ({String label, Color bgColor, Color textColor}) info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: info.textColor,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.abs());
  }

  String _getShiftLabel(String? shiftType) {
    switch (shiftType?.toUpperCase()) {
      case 'MORNING':
        return 'Sáng';
      case 'AFTERNOON':
        return 'Chiều';
      case 'BOTH':
        return 'Cả ngày';
      default:
        return 'N/A';
    }
  }
}
