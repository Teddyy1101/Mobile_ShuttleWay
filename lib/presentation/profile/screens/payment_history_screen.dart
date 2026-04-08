import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../controllers/profile_controller.dart';
import '../widgets/transaction_item.dart';

/// Màn hình Lịch sử thanh toán.
class PaymentHistoryScreen extends StatefulWidget {
  final ProfileController controller;

  const PaymentHistoryScreen({
    super.key,
    required this.controller,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  int _selectedTabIndex = 0;
  DateTime? _filterFrom;
  DateTime? _filterTo;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  void _fetchTransactions() {
    final now = DateTime.now();
    DateTime from;
    DateTime to;
    
    if (_hasDateFilter) {
      from = _filterFrom ?? DateTime(2020);
      to = _filterTo ?? now.add(const Duration(days: 1));
    } else {
      if (_selectedTabIndex == 0) {
        // This month
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else {
        // Last month
        from = DateTime(now.year, now.month - 1, 1);
        to = DateTime(now.year, now.month, 0, 23, 59, 59);
      }
    }
    
    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);
    
    widget.controller.loadTransactions(
      refresh: true, 
      fromDate: fromStr, 
      toDate: toStr,
    );
  }

  bool get _hasDateFilter => _filterFrom != null || _filterTo != null;

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
          'Lịch sử thanh toán',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: _hasDateFilter
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1C252E) : Colors.grey[200]),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _hasDateFilter
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                onPressed: () => _showDateFilterDialog(context),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              // ── Tab tháng này / tháng trước ──
              SliverToBoxAdapter(
                child: _buildMonthTabs(theme, isDark),
              ),

              // ── Active filter chip ──
              if (_hasDateFilter)
                SliverToBoxAdapter(
                  child: _buildActiveFilterChip(theme, isDark),
                ),

              // ── Header ──
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _buildTransactionHeader(theme, isDark),
                ),
              ),

              // ── Danh sách giao dịch ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _buildTransactionSliver(theme, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Date filter dialog ──────────────────────────────────

  Future<void> _showDateFilterDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    DateTime? tmpFrom = _filterFrom;
    DateTime? tmpTo = _filterTo;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C252E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                    Text(
                      'Lọc theo ngày',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Từ ngày
                    _buildDatePickerRow(
                      context: ctx,
                      theme: theme,
                      isDark: isDark,
                      label: 'Từ ngày',
                      icon: Icons.calendar_today_outlined,
                      selectedDate: tmpFrom,
                      onPick: (date) => setModalState(() => tmpFrom = date),
                    ),
                    const SizedBox(height: 12),
                    // Đến ngày
                    _buildDatePickerRow(
                      context: ctx,
                      theme: theme,
                      isDark: isDark,
                      label: 'Đến ngày',
                      icon: Icons.event_outlined,
                      selectedDate: tmpTo,
                      onPick: (date) => setModalState(() => tmpTo = date),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        // Xóa bộ lọc
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filterFrom = null;
                                _filterTo = null;
                              });
                              _fetchTransactions();
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Xóa bộ lọc',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Áp dụng
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filterFrom = tmpFrom;
                                _filterTo = tmpTo;
                              });
                              _fetchTransactions();
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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

  Widget _buildDatePickerRow({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onPick,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          builder: (ctx, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  surface: isDark ? const Color(0xFF1C252E) : Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A22) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(selectedDate)
                      : 'Chọn ngày',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedDate != null
                        ? (isDark ? Colors.white : Colors.grey[900])
                        : (isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Active filter chip ────────────────────────────────

  Widget _buildActiveFilterChip(ThemeData theme, bool isDark) {
    String text = '';
    if (_filterFrom != null && _filterTo != null) {
      text =
          '${DateFormat('dd/MM').format(_filterFrom!)} → ${DateFormat('dd/MM').format(_filterTo!)}';
    } else if (_filterFrom != null) {
      text = 'Từ ${DateFormat('dd/MM').format(_filterFrom!)}';
    } else if (_filterTo != null) {
      text = 'Đến ${DateFormat('dd/MM').format(_filterTo!)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  _filterFrom = null;
                  _filterTo = null;
                });
                _fetchTransactions();
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Month tabs ─────────────────────────────────────────

  Widget _buildMonthTabs(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C252E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabItem(
              theme: theme,
              isDark: isDark,
              label: 'Tháng này',
              isSelected: _selectedTabIndex == 0,
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                  _filterFrom = null;
                  _filterTo = null;
                });
                _fetchTransactions();
              },
            ),
            _buildTabItem(
              theme: theme,
              isDark: isDark,
              label: 'Tháng trước',
              isSelected: _selectedTabIndex == 1,
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                  _filterFrom = null;
                  _filterTo = null;
                });
                _fetchTransactions();
              },
            ),
          ],
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
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Transaction header ─────────────────────────────────

  Widget _buildTransactionHeader(ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final targetMonth =
        _selectedTabIndex == 0 ? now : DateTime(now.year, now.month - 1, 1);
    final monthLabel = 'Tháng ${targetMonth.month}, ${targetMonth.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Danh sách giao dịch',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C252E)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            monthLabel,
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

  // ─── Transaction list ───────────────────────────────────

  Widget _buildTransactionSliver(ThemeData theme, bool isDark) {
    var transactions = widget.controller.transactions;

    if (widget.controller.isLoading && transactions.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (transactions.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: isDark ? Colors.grey[500] : Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có giao dịch nào',
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

    // Group by date
    final grouped = _groupTransactionsByDate(transactions);
    final List<Widget> children = [];

    for (final group in grouped) {
      children.add(_buildDateHeader(group.dateLabel, theme, isDark));
      children.add(const SizedBox(height: 12));

      for (final tx in group.transactions) {
        children.add(_buildTransactionFromModel(tx, theme, isDark));
        children.add(const SizedBox(height: 12));
      }
      children.add(const SizedBox(height: 8));
    }

    // ── "Xem thêm giao dịch cũ" button — visible in dark mode ──
    children.add(
      Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextButton.icon(
            onPressed: () => widget.controller.loadTransactions(),
            icon: Icon(
              Icons.expand_more,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Xem thêm giao dịch cũ',
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
      ),
    );
    children.add(const SizedBox(height: 100));

    return SliverList(
      delegate: SliverChildListDelegate(children),
    );
  }

  Widget _buildDateHeader(String text, ThemeData theme, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: isDark ? Colors.grey[400] : Colors.grey[500],
      ),
    );
  }

  Widget _buildTransactionFromModel(
      TransactionModel tx, ThemeData theme, bool isDark) {
    final ticketType = tx.ticket?.ticketType ?? '';
    final studentName = tx.ticket?.student?.fullName ?? 'Học sinh';
    final timeStr = DateFormat('HH:mm').format(tx.createdAt.toLocal());
    final paymentLabel = _getPaymentMethodLabel(tx.paymentMethod);
    final isRefund = tx.discountAmount > 0 && tx.finalAmount == 0;
    final isFailed = tx.status.toUpperCase() == 'FAILED';

    // Xác định người thanh toán
    final currentUserId = widget.controller.profile?.id;
    final payerLabel = _getPayerLabel(tx, currentUserId);

    final IconData txIcon;
    final Color txIconColor;
    final Color txIconBgColor;
    final String txTitle;
    final String txAmount;
    final Color? txAmountColor;

    if (isRefund) {
      txIcon = Icons.redeem_outlined;
      txIconColor = Colors.purple;
      txIconBgColor = Colors.purple.withValues(alpha: isDark ? 0.25 : 0.1);
      txTitle = 'Hoàn tiền vé hủy';
      txAmount = '+${_formatCurrency(tx.discountAmount)}đ';
      txAmountColor = const Color(0xFF22C55E);
    } else if (ticketType == 'MONTHLY') {
      txIcon = Icons.confirmation_number_outlined;
      txIconColor = theme.primaryColor;
      txIconBgColor =
          theme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.1);
      txTitle = 'Vé tháng – $studentName';
      txAmount = '-${_formatCurrency(tx.finalAmount)}đ';
      txAmountColor = null;
    } else {
      txIcon = Icons.local_activity_outlined;
      txIconColor = Colors.orange;
      txIconBgColor = Colors.orange.withValues(alpha: isDark ? 0.25 : 0.1);
      txTitle = 'Vé lượt – $studentName';
      txAmount = '-${_formatCurrency(tx.finalAmount)}đ';
      txAmountColor = null;
    }

    TransactionStatus txStatus;
    switch (tx.status.toUpperCase()) {
      case 'SUCCESS':
        txStatus = TransactionStatus.success;
      case 'FAILED':
        txStatus = TransactionStatus.failed;
      default:
        txStatus = TransactionStatus.pending;
    }

    return TransactionItem(
      icon: isFailed ? Icons.warning_amber_rounded : txIcon,
      iconColor: isFailed ? Colors.red : txIconColor,
      iconBgColor:
          isFailed ? Colors.red.withValues(alpha: isDark ? 0.2 : 0.1) : txIconBgColor,
      title: txTitle,
      subtitle: '$timeStr • $paymentLabel • $payerLabel',
      amount: txAmount,
      amountColor: txAmountColor,
      status: txStatus,
      isStrikethrough: isFailed,
      opacity: isFailed ? 0.8 : 1.0,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────

  List<_TransactionGroup> _groupTransactionsByDate(
      List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in transactions) {
      final txDate = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );

      String dateKey;
      if (txDate == today) {
        dateKey = 'HÔM NAY, ${DateFormat('dd/MM').format(txDate)}';
      } else if (txDate == yesterday) {
        dateKey = 'HÔM QUA, ${DateFormat('dd/MM').format(txDate)}';
      } else {
        dateKey = DateFormat('dd/MM/yyyy').format(txDate);
      }

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(tx);
    }

    return grouped.entries
        .map((e) =>
            _TransactionGroup(dateLabel: e.key, transactions: e.value))
        .toList();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.abs());
  }

  /// Trả về nhãn người thanh toán.
  /// - Nếu chính mình thanh toán → "Bạn"
  /// - Nếu phụ huynh thanh toán (trên màn hình học sinh) → "Phụ huynh"
  String _getPayerLabel(TransactionModel tx, String? currentUserId) {
    final txUser = tx.user;
    if (txUser == null) return 'Bạn';

    if (txUser.id == currentUserId) {
      return 'Bạn';
    }

    // Người thanh toán là PARENT → hiển thị "Phụ huynh"
    if (txUser.role.toUpperCase() == 'PARENT') {
      return 'Phụ huynh';
    }

    return txUser.fullName;
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'VNPAY':
        return 'VNPay';
      case 'MOMO':
        return 'MoMo';
      case 'SEPAY':
        return 'Ví điện tử';
      case 'CASH':
        return 'Tiền mặt';
      default:
        return method;
    }
  }
}

class _TransactionGroup {
  final String dateLabel;
  final List<TransactionModel> transactions;
  const _TransactionGroup(
      {required this.dateLabel, required this.transactions});
}
