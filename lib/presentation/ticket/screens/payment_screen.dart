import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/promotion_model.dart';
import '../../../data/models/ticket_model.dart';
import '../controllers/payment_controller.dart';
import 'payment_webview_screen.dart';
import 'sepay_qr_screen.dart';
import 'ticket_detail_screen.dart';

/// Giao diện 1:1 từ HTML mockup. Dùng cho cả Phụ huynh và Học sinh.
class PaymentScreen extends StatelessWidget {
  final TicketModel ticket;
  final PaymentController paymentController;

  const PaymentScreen({
    super.key,
    required this.ticket,
    required this.paymentController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ListenableBuilder(
        listenable: paymentController,
        builder: (context, _) {
          return Column(
            children: [
              _buildAppBar(context, theme, isDark, backgroundColor),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.paddingXXL + 60,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppConstants.paddingLG),
                      _buildSummaryCard(context, theme, isDark),
                      const SizedBox(height: AppConstants.paddingLG),
                      _buildPromotionSection(context, theme, isDark),
                      const SizedBox(height: AppConstants.paddingLG),
                      _buildPaymentMethods(context, theme, isDark),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: ListenableBuilder(
        listenable: paymentController,
        builder: (context, _) {
          return _buildBottomButton(context, theme, isDark);
        },
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXS,
          vertical: AppConstants.paddingSM,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: const CircleBorder(),
              ),
            ),
            Expanded(
              child: Text(
                'Thanh toán vé xe',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppConstants.avatarSizeMD),
          ],
        ),
      ),
    );
  }

  // Summary Card
  Widget _buildSummaryCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final labelColor =
        isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final valueColor = theme.colorScheme.onSurface;

    final studentName = ticket.student?.fullName ?? 'N/A';
    final studentEmail = ticket.student?.email ?? '';
    final routeName = ticket.route?.name ?? 'N/A';
    final ticketTypeLabel = ticket.ticketType == 'MONTHLY'
        ? 'Vé tháng'
        : 'Vé lượt';
    final validFromStr = DateFormat('dd/MM/yyyy').format(ticket.validFrom);
    final validUntilStr = DateFormat('dd/MM/yyyy').format(ticket.validUntil);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative blur circle
            Positioned(
              top: -24,
              right: -24,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMD + 4),
              child: Column(
                children: [
                  // Student info + month badge
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: AppConstants.iconSizeMD,
                        backgroundColor: theme.colorScheme.primary
                            .withValues(alpha: 0.15),
                        backgroundImage: ticket.student?.avatarUrl != null
                            ? NetworkImage(ticket.student!.avatarUrl!)
                            : null,
                        child: ticket.student?.avatarUrl == null
                            ? Text(
                                studentName.isNotEmpty
                                    ? studentName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppConstants.paddingSM + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: valueColor,
                              ),
                            ),
                            if (studentEmail.isNotEmpty)
                              Text(
                                studentEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: labelColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Month badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingSM + 4,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSM),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'Tháng ${ticket.validFrom.month}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingLG),

                  // Ticket details
                  _buildDetailRow('Loại vé', ticketTypeLabel, labelColor,
                      valueColor),
                  const SizedBox(height: AppConstants.paddingSM + 4),
                  _buildDetailRow(
                      'Tuyến xe', routeName, labelColor, valueColor),
                  const SizedBox(height: AppConstants.paddingSM + 4),
                  _buildDetailRow('Thời gian',
                      '$validFromStr - $validUntilStr', labelColor, valueColor),

                  // Dashed divider with notch circles
                  const SizedBox(height: AppConstants.paddingMD + 4),
                  _buildDashedDivider(isDark),
                  const SizedBox(height: AppConstants.paddingMD + 4),

                  // Giá gốc
                  _buildDetailRow(
                    'Giá vé',
                    '${_formatCurrency(ticket.priceAtBuy)}đ',
                    labelColor,
                    valueColor,
                  ),

                  // Giảm giá (nếu có)
                  if (paymentController.appliedPromotion != null) ...[
                    const SizedBox(height: AppConstants.paddingSM + 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giảm giá (${paymentController.appliedPromotion!.code})',
                          style: TextStyle(fontSize: 13, color: AppColors.success),
                        ),
                        Text(
                          '-${_formatCurrency(paymentController.appliedPromotion!.calculateDiscount(ticket.priceAtBuy))}đ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppConstants.paddingSM + 4),

                  // Tổng thanh toán
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(paymentController.calculateFinalAmount(ticket.priceAtBuy))}đ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
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

  Widget _buildDetailRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: labelColor),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider(bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedHorizontalPainter(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        // Left notch
        Positioned(
          left: -(AppConstants.paddingMD + 4 + 8),
          top: -8,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Right notch
        Positioned(
          right: -(AppConstants.paddingMD + 4 + 8),
          top: -8,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Promotion Section ─────────────────────────────────

  Widget _buildPromotionSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final applied = paymentController.appliedPromotion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mã giảm giá',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM + 4),
          GestureDetector(
            onTap: () {
              // Vé lượt (SINGLE_TRIP) không cho dùng mã giảm giá
              if (ticket.ticketType == 'SINGLE_TRIP') {
                AppToast.showError(
                  context,
                  'Mã giảm giá chỉ áp dụng cho vé tháng',
                );
                return;
              }
              _showPromotionBottomSheet(context, theme, isDark);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              decoration: BoxDecoration(
                color: applied != null
                    ? theme.colorScheme.primary.withValues(alpha: 0.05)
                    : cardBg,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(
                  color: applied != null
                      ? theme.colorScheme.primary
                      : cardBorder,
                  width: applied != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: applied != null
                          ? AppColors.success.withValues(alpha: 0.15)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      applied != null
                          ? Icons.check_circle_outline
                          : Icons.local_offer_outlined,
                      color: applied != null
                          ? AppColors.success
                          : theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMD),
                  // Nội dung
                  Expanded(
                    child: applied != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                applied.code,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                applied.discountLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chọn mã giảm giá',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ticket.ticketType == 'SINGLE_TRIP'
                                    ? 'Không áp dụng cho vé lượt'
                                    : 'Bạn có mã ưu đãi?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextHint
                                      : AppColors.lightTextHint,
                                ),
                              ),
                            ],
                          ),
                  ),
                  // Hủy / Mũi tên
                  if (applied != null)
                    GestureDetector(
                      onTap: () => paymentController.removePromotion(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị BottomSheet danh sách mã giảm giá.
  void _showPromotionBottomSheet(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    // Load promotions khi mở sheet
    paymentController.loadPromotions();

    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL - 4),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return ListenableBuilder(
              listenable: paymentController,
              builder: (context, _) {
                return Column(
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.paddingMD,
                      ),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMD),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppConstants.paddingSM),
                          Text(
                            'Chọn mã giảm giá',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    // Content
                    Expanded(
                      child: paymentController.isLoadingPromotions
                          ? Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : paymentController.promotions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_offer_outlined,
                                        size: 48,
                                        color: isDark
                                            ? AppColors.darkTextHint
                                            : AppColors.lightTextHint,
                                      ),
                                      const SizedBox(
                                          height: AppConstants.paddingMD),
                                      Text(
                                        'Chưa có mã giảm giá nào',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? AppColors.darkTextHint
                                              : AppColors.lightTextHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(
                                    AppConstants.paddingMD,
                                  ),
                                  itemCount:
                                      paymentController.promotions.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(
                                          height: AppConstants.paddingSM + 4),
                                  itemBuilder: (_, index) {
                                    final promo =
                                        paymentController.promotions[index];
                                    return _buildPromotionItem(
                                      ctx,
                                      theme,
                                      isDark,
                                      promo,
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Widget cho mỗi mã giảm giá trong BottomSheet.
  Widget _buildPromotionItem(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    PromotionModel promo,
  ) {
    final isApplied = paymentController.appliedPromotion?.id == promo.id;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final discount = promo.calculateDiscount(ticket.priceAtBuy);
    final validUntilStr = DateFormat('dd/MM/yyyy').format(promo.validUntil);

    return GestureDetector(
      onTap: () {
        if (isApplied) {
          paymentController.removePromotion();
        } else {
          paymentController.applyPromotion(promo);
        }
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        decoration: BoxDecoration(
          color: isApplied
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : cardBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: isApplied
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isApplied ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Discount badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.percent, size: 18, color: Colors.white),
                  Text(
                    promo.discountType == 'PERCENTAGE'
                        ? '${promo.discountValue.toInt()}%'
                        : _formatCurrency(promo.discountValue),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingMD),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.code,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${promo.discountLabel} • Tiết kiệm ${_formatCurrency(discount)}đ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'HSD: $validUntilStr',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                      ),
                      if (promo.remainingUsage != null) ...[
                        const SizedBox(width: AppConstants.paddingSM),
                        Text(
                          '• Còn ${promo.remainingUsage} lượt',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingSM),
            // Radio
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isApplied
                      ? theme.colorScheme.primary
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                  width: 2,
                ),
                color: isApplied
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              child: isApplied
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // Payment Methods

  Widget _buildPaymentMethods(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phương thức thanh toán',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          _buildMethodCard(
            context: context,
            theme: theme,
            isDark: isDark,
            methodKey: 'MOMO',
            icon: Icons.account_balance_wallet,
            iconBgColor: const Color(0xFFA50064),
            title: 'Ví MoMo',
            subtitle: 'Miễn phí giao dịch',
          ),
          const SizedBox(height: AppConstants.paddingSM + 4),
          _buildMethodCard(
            context: context,
            theme: theme,
            isDark: isDark,
            methodKey: 'VNPAY',
            iconWidget: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF003087),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              alignment: Alignment.center,
              child: const Text(
                'VN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            title: 'VNPay',
            subtitle: 'Thẻ ATM / Visa / QR',
          ),
          const SizedBox(height: AppConstants.paddingSM + 4),
          _buildMethodCard(
            context: context,
            theme: theme,
            isDark: isDark,
            methodKey: 'ZALOPAY',
            iconWidget: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0068FF),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              alignment: Alignment.center,
              child: const Text(
                'ZALO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            title: 'Ví ZaloPay',
            subtitle: 'Đang phát triển',
            isDisabled: true,
          ),
          const SizedBox(height: AppConstants.paddingSM + 4),
          _buildMethodCard(
            context: context,
            theme: theme,
            isDark: isDark,
            methodKey: 'SEPAY',
            icon: Icons.qr_code_scanner,
            iconBgColor: AppColors.warning,
            title: 'Chuyển khoản QR',
            subtitle: 'Quét mã VietQR',
          ),

          // Error message
          if (paymentController.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.paddingMD),
              child: Text(
                paymentController.errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String methodKey,
    IconData? icon,
    Color? iconBgColor,
    Widget? iconWidget,
    required String title,
    required String subtitle,
    bool isDisabled = false,
  }) {
    final isSelected = paymentController.selectedMethod == methodKey;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: () {
        if (isDisabled) {
          AppToast.showError(context, 'Tính năng đang phát triển');
          return;
        }
        paymentController.selectMethod(methodKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : cardBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Row(
            children: [
              // Icon
              iconWidget ??
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor ?? theme.colorScheme.primary,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
              const SizedBox(width: AppConstants.paddingMD),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint,
                      ),
                    ),
                  ],
                ),
              ),
              // Radio indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: 2,
                  ),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom Button

  Widget _buildBottomButton(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final isProcessing = paymentController.isProcessing;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingSM,
        AppConstants.paddingMD,
        MediaQuery.of(context).padding.bottom + AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isProcessing
              ? null
              : () => _handlePayment(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMD,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            elevation: 0,
          ),
          child: isProcessing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Thanh toán ngay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: AppConstants.paddingSM),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  // Actions

  Future<void> _handlePayment(BuildContext context) async {
    final needsUrl = await paymentController.processPayment(ticket.id);

    if (!context.mounted) return;

    if (paymentController.errorMessage != null) {
      AppToast.showError(context, paymentController.errorMessage!);
      return;
    }

    if (needsUrl && paymentController.paymentUrl != null) {
      // VNPay / MoMo: mở WebView thanh toán trong app
      final result = await Navigator.push<PaymentWebViewResult>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            paymentUrl: paymentController.paymentUrl!,
            title: paymentController.selectedMethod == 'VNPAY'
                ? 'Thanh toán VNPay'
                : 'Thanh toán MoMo',
          ),
        ),
      );

      if (!context.mounted) return;

      if (result != null) {
        // Nhận được kết quả từ WebView → hiển thị popup
        _showPaymentResultDialog(context, result);
      }
      // result == null nghĩa là user bấm nút X đóng WebView (hủy thanh toán)
    } else if (paymentController.selectedMethod == 'SEPAY' &&
        paymentController.transaction != null) {
      // SePay: mở màn hình QR chuyển khoản fullscreen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SePayQrScreen(
              ticket: ticket,
              paymentController: paymentController,
            ),
          ),
        );
      }
    }
  }

  /// Hiển thị popup kết quả thanh toán (thành công / thất bại).
  void _showPaymentResultDialog(
    BuildContext context,
    PaymentWebViewResult result,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLG + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon kết quả
                _buildResultIcon(result.isSuccess, theme),
                const SizedBox(height: AppConstants.paddingLG),
                // Tiêu đề
                Text(
                  result.isSuccess
                      ? 'Thanh toán thành công!'
                      : 'Thanh toán thất bại',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingSM),
                // Mô tả
                Text(
                  result.isSuccess
                      ? 'Vé xe đã được kích hoạt. '
                          'Bạn có thể xem chi tiết vé ngay bây giờ.'
                      : _getPaymentErrorMessage(
                          result.responseCode),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Mã giao dịch (nếu có)
                if (result.transactionRef != null) ...[
                  const SizedBox(height: AppConstants.paddingMD),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMD,
                      vertical: AppConstants.paddingSM,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : AppColors.lightCard,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mã GD: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            result.transactionRef!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.paddingLG + 4),
                // Buttons
                if (result.isSuccess) ...[
                  // Thành công: Xem vé + Quay lại
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx); // Đóng dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketDetailScreen(
                              ticket: ticket,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.confirmation_number_outlined,
                          size: 20),
                      label: const Text(
                        'Xem vé',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSM + 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Đóng dialog
                        Navigator.pop(context); // Quay về màn hình đặt vé
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                        ),
                      ),
                      child: const Text(
                        'Quay lại',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Thất bại: Thử lại + Quay lại
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx); // Đóng dialog, ở lại PaymentScreen
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        'Thử lại',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSM + 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Đóng dialog
                        Navigator.pop(context); // Quay về màn hình đặt vé
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                        ),
                      ),
                      child: const Text(
                        'Quay lại',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Icon animated cho popup kết quả thanh toán.
  Widget _buildResultIcon(bool isSuccess, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSuccess
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSuccess
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.close_rounded,
              size: 32,
              color: isSuccess ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  /// Trả về thông báo lỗi dễ hiểu dựa trên response code
  /// từ cổng thanh toán (VNPay hoặc MoMo).
  String _getPaymentErrorMessage(String? responseCode) {
    switch (responseCode) {
      // ── VNPay response codes ──
      case '07':
        return 'Giao dịch bị nghi ngờ gian lận. '
            'Vui lòng liên hệ ngân hàng.';
      case '09':
        return 'Thẻ/Tài khoản chưa đăng ký dịch vụ '
            'thanh toán trực tuyến.';
      case '10':
        return 'Xác thực thông tin thẻ không đúng '
            'quá 3 lần. Vui lòng thử lại sau.';
      case '11':
        return 'Đã hết thời gian chờ thanh toán. '
            'Vui lòng thực hiện lại.';
      case '12':
        return 'Thẻ/Tài khoản bị khóa. '
            'Vui lòng liên hệ ngân hàng.';
      case '24':
        return 'Giao dịch đã bị hủy bởi người dùng.';
      case '51':
        return 'Tài khoản không đủ số dư để thanh toán.';
      case '65':
        return 'Tài khoản đã vượt quá hạn mức giao dịch trong ngày.';
      case '75':
        return 'Ngân hàng đang bảo trì. '
            'Vui lòng thử lại sau.';

      // ── MoMo result codes ──
      case '1000':
        return 'Tài khoản MoMo không đủ số dư để thanh toán.';
      case '1005':
        return 'Đã hết thời gian chờ thanh toán MoMo. '
            'Vui lòng thực hiện lại.';
      case '1006':
        return 'Giao dịch đã bị hủy bởi người dùng.';
      case '1001':
        return 'Giao dịch thất bại. Vui lòng thử lại.';

      default:
        return 'Thanh toán không thành công. '
            'Vui lòng kiểm tra lại và thử lại.';
    }
  }



  // Helpers
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.abs());
  }
}

/// Custom painter cho đường nét đứt ngang (dashed horizontal line).
class _DashedHorizontalPainter extends CustomPainter {
  final Color color;

  _DashedHorizontalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const gapWidth = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}