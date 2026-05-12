import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../ticket/screens/ticket_detail_screen.dart';

/// Màn hình "Vé của tôi" — hiển thị danh sách vé dạng card chi tiết.
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
  String _searchQuery = '';
  int _displayLimit = 15;
  static const int _pageSize = 15;
  bool get _isParentMode => widget.children.isNotEmpty;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _fetchTickets() {
    widget.profileController.loadMyTickets(
      refresh: true,
      ticketType: _filterTicketType,
    );
  }

  List<TicketModel> get _filteredTickets {
    var tickets = widget.profileController.tickets;
    if (_filterChildId != null) {
      tickets = tickets.where((t) => t.student?.id == _filterChildId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tickets = tickets.where((t) {
        final route = t.route?.name.toLowerCase() ?? '';
        final student = t.student?.fullName.toLowerCase() ?? '';
        return route.contains(q) || student.contains(q);
      }).toList();
    }
    return tickets;
  }

  List<TicketModel> get _visibleTickets {
    final all = _filteredTickets;
    if (all.length <= _displayLimit) return all;
    return all.sublist(0, _displayLimit);
  }

  /// Tách vé active và vé không active.
  List<TicketModel> get _activeTickets =>
      _visibleTickets.where((t) => t.status.toUpperCase() == 'ACTIVE').toList();

  List<TicketModel> get _inactiveTickets =>
      _visibleTickets.where((t) => t.status.toUpperCase() != 'ACTIVE').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;

    return GestureDetector(
      onTap: () => _searchFocus.unfocus(),
      child: Scaffold(
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
      ),
    );
  }

  // ─── AppBar ───

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark, Color bgColor) {
    return AppBar(
      backgroundColor: bgColor.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _buildBackButton(theme, isDark),
      title: Text(
        'Vé của tôi',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildFilterButton(ThemeData theme, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.filter_list_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => _showFilterDialog(theme, isDark),
          ),
        ),
        if (_activeFilterCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$_activeFilterCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
      ],
    );
  }

  // ─── Filter dialog ───

  void _showFilterDialog(ThemeData theme, bool isDark) {
    String? tempType = _filterTicketType;
    String? tempChildId = _filterChildId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
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
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Bộ lọc', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text('Loại vé', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700])),
                    const SizedBox(height: 8),
                    _buildFilterChipGroup(
                      isDark: isDark, theme: theme,
                      options: const [
                        (value: null, label: 'Tất cả'),
                        (value: 'MONTHLY', label: 'Vé tháng'),
                        (value: 'SINGLE', label: 'Vé lượt'),
                      ],
                      selectedValue: tempType,
                      onSelected: (val) => setSheetState(() => tempType = val),
                    ),
                    if (_isParentMode) ...[
                      const SizedBox(height: 20),
                      Text('Học sinh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700])),
                      const SizedBox(height: 8),
                      _buildFilterChipGroup(
                        isDark: isDark, theme: theme,
                        options: [
                          (value: null, label: 'Tất cả'),
                          ...widget.children.map((c) => (value: c.id, label: c.fullName)),
                        ],
                        selectedValue: tempChildId,
                        onSelected: (val) => setSheetState(() => tempChildId = val),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setSheetState(() { tempType = null; tempChildId = null; }),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                              side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            ),
                            child: Text('Xóa lọc', style: TextStyle(fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[300] : Colors.grey[700])),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() { _filterTicketType = tempType; _filterChildId = tempChildId; _displayLimit = _pageSize; });
                              _fetchTickets();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                            ),
                            child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildFilterChipGroup({
    required bool isDark,
    required ThemeData theme,
    required List<({String? value, String label})> options,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selectedValue == opt.value;
        return GestureDetector(
          onTap: () => onSelected(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : isDark ? AppColors.darkCard : Colors.grey[100],
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              border: isSelected ? null : Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 0.5),
            ),
            child: Text(
              opt.label.length > 20 ? '${opt.label.substring(0, 20)}…' : opt.label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Body ───

  Widget _buildBody(ThemeData theme, bool isDark) {
    final allFiltered = _filteredTickets;

    if (widget.profileController.isLoading && allFiltered.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(child: _buildSearchBar(theme, isDark)),
        // Summary
        SliverToBoxAdapter(child: _buildSummaryRow(theme, isDark, allFiltered.length)),
        // Content
        if (allFiltered.isEmpty)
          SliverFillRemaining(child: _buildEmptyState(theme, isDark))
        else ...[
          // Active tickets section
          if (_activeTickets.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('Vé đang sử dụng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.success)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MyTicketCard(ticket: _activeTickets[index], onTap: () => _showTicketDetail(_activeTickets[index])),
                  ),
                  childCount: _activeTickets.length,
                ),
              ),
            ),
          ],
          // Inactive tickets section
          if (_inactiveTickets.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Vé đã sử dụng/hết hạn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MyTicketCard(ticket: _inactiveTickets[index], onTap: () => _showTicketDetail(_inactiveTickets[index])),
                  ),
                  childCount: _inactiveTickets.length,
                ),
              ),
            ),
          ],
          // Load more
          if (_visibleTickets.length < _filteredTickets.length)
            SliverToBoxAdapter(child: _buildLoadMoreButton(theme, isDark)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Tìm theo tên tuyến, học sinh...',
            hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, bool isDark, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text('Danh sách vé', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$total vé', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[600])),
          ),
          const Spacer(),
          if (_activeFilterCount > 0)
            GestureDetector(
              onTap: () {
                setState(() { _filterTicketType = null; _filterChildId = null; _displayLimit = _pageSize; });
                _fetchTickets();
              },
              child: Text('Xóa lọc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
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
          onPressed: () => setState(() => _displayLimit += _pageSize),
          icon: Icon(Icons.expand_more, size: 20, color: theme.colorScheme.primary),
          label: Text('Xem thêm', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
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
          Icon(Icons.confirmation_number_outlined, size: 48,
              color: isDark ? Colors.grey[500] : Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _isParentMode ? 'Chưa có vé nào cho bé' : 'Bạn chưa có vé nào',
            style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[500]),
          ),
          if (_activeFilterCount > 0) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() { _filterTicketType = null; _filterChildId = null; _displayLimit = _pageSize; });
                _fetchTickets();
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  void _showTicketDetail(TicketModel ticket) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)));
  }
}

// ─── Card vé chi tiết (theo style ảnh tham khảo) ───

class _MyTicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback? onTap;

  const _MyTicketCard({required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = ticket.status.toUpperCase() == 'ACTIVE';
    final isMonthly = ticket.ticketType == 'MONTHLY';
    final routeName = ticket.route?.name ?? 'N/A';
    final ticketCode = ticket.id.length >= 6 ? ticket.id.substring(0, 6).toUpperCase() : ticket.id.toUpperCase();
    final validFromStr = DateFormat('dd/MM/yyyy').format(ticket.validFrom.toLocal());
    final validUntilStr = DateFormat('dd/MM/yyyy').format(ticket.validUntil.toLocal());
    final statusInfo = _getStatusInfo(ticket.status);
    final accentColor = isActive ? AppColors.success : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Accent bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusLG)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tuyến
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.directions_bus_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Tuyến: $routeName',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Hạng + Mã vé
                  _infoRow(isDark, 'Hạng:', isMonthly ? 'Vé tháng' : 'Vé lượt'),
                  const SizedBox(height: 6),
                  _infoRow(isDark, 'MST:', ticketCode),
                  const SizedBox(height: 6),
                  // Giá vé
                  _infoRow(isDark, 'Giá vé:', '${_formatCurrency(ticket.priceAtBuy)}đ'),
                  const SizedBox(height: 8),
                  // Trạng thái
                  Row(
                    children: [
                      Text('Trạng thái:  ', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusInfo.bgColor,
                          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                          border: Border.all(color: statusInfo.textColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(statusInfo.label,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusInfo.textColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Divider
                  Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  const SizedBox(height: 10),
                  // Hiệu lực
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text('Hiệu lực: $validFromStr - $validUntilStr',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    ],
                  ),
                  // Student name (nếu có)
                  if (ticket.student != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Học sinh: ${ticket.student!.fullName}',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // QR button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(Icons.qr_code_rounded, size: 18, color: theme.colorScheme.primary),
                label: Text('Hiển thị mã QR',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.04),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(bool isDark, String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1D2E)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.abs());
  }

  static ({String label, Color bgColor, Color textColor}) _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return (label: 'Đang hoạt động', bgColor: AppColors.success.withValues(alpha: 0.12), textColor: AppColors.success);
      case 'EXPIRED':
        return (label: 'Hết hạn', bgColor: Colors.grey.withValues(alpha: 0.12), textColor: Colors.grey);
      case 'CANCELLED':
        return (label: 'Đã hủy', bgColor: const Color(0xFFEF4444).withValues(alpha: 0.12), textColor: const Color(0xFFEF4444));
      case 'PENDING':
        return (label: 'Chờ thanh toán', bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.12), textColor: const Color(0xFFF59E0B));
      default:
        return (label: status, bgColor: Colors.grey.withValues(alpha: 0.12), textColor: Colors.grey);
    }
  }
}
