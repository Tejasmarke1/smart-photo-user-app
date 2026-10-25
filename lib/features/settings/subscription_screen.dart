import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/tokens.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import 'purchase_bottom_sheet.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isAnnual = true;
  int _currentPlanIndex = 0;
  late PageController _pageController;

  /// All user plans fetched from the backend API
  List<PlanResponse> _dbPlans = [];

  /// Grouped plan tiers derived from _dbPlans (e.g. Basic, Standard, Essential, Premium)
  /// Each tier contains: name, quarterlyPlan, yearlyPlan, features, icon
  List<Map<String, dynamic>> _planTiers = [];

  bool _isLoading = true;

  // Icon mapping based on plan tier name
  static const Map<String, IconData> _tierIcons = {
    'Basic': Icons.star_border_rounded,
    'Standard': Icons.star_outline_rounded,
    'Essential': Icons.diamond_rounded,
    'Premium': Icons.workspace_premium_rounded,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: _currentPlanIndex);
    _fetchDbPlans();
  }

  Future<void> _fetchDbPlans() async {
    try {
      final client = ref.read(apiClientProvider);
      final plans = await client.getPlans('user');
      if (mounted) {
        setState(() {
          _dbPlans = plans;
          _buildPlanTiers();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Groups plans by name into tiers, excluding free plans.
  /// Each tier has quarterly + yearly variants, features, and pricing.
  void _buildPlanTiers() {
    // Collect paid plan names in order of appearance (preserving DB sort_order)
    final List<String> tierOrder = [];
    final Map<String, Map<String, dynamic>> tierMap = {};

    for (final plan in _dbPlans) {
      final billingCycle = plan.billingCycle;
      // Skip free plans from the subscription carousel
      if (billingCycle == 'free' || plan.priceCents == 0) continue;

      final name = plan.name;

      if (!tierMap.containsKey(name)) {
        tierOrder.add(name);
        tierMap[name] = {
          'name': name,
          'icon': _tierIcons[name] ?? Icons.star_outline_rounded,
          'quarterlyPlan': null,
          'yearlyPlan': null,
          'features': <String>[],
        };
      }

      if (billingCycle == 'quarterly') {
        tierMap[name]!['quarterlyPlan'] = plan;
      } else if (billingCycle == 'yearly') {
        tierMap[name]!['yearlyPlan'] = plan;
      }

      // Use features from the first variant that has them
      final features = plan.features;
      if (features != null && (tierMap[name]!['features'] as List).isEmpty) {
        tierMap[name]!['features'] = List<String>.from(features);
      }
    }

    _planTiers = tierOrder.map((name) => tierMap[name]!).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Returns the currently selected DB plan model based on tier index and billing toggle
  PlanResponse? get _selectedDbPlan {
    if (_planTiers.isEmpty || _currentPlanIndex >= _planTiers.length) return null;
    final tier = _planTiers[_currentPlanIndex];
    return _isAnnual ? (tier['yearlyPlan'] as PlanResponse?) : (tier['quarterlyPlan'] as PlanResponse?);
  }



  String? get _selectedPlanId {
    return _selectedDbPlan?.id;
  }

  int _getPlanPriceForCard(int cardIndex) {
    if (_planTiers.isEmpty || cardIndex >= _planTiers.length) return 0;
    final tier = _planTiers[cardIndex];
    final plan = _isAnnual ? (tier['yearlyPlan'] as PlanResponse?) : (tier['quarterlyPlan'] as PlanResponse?);
    if (plan != null) {
      return plan.priceCents ~/ 100;
    }
    return 0;
  }

  /// Compute a strikethrough "original" price for yearly plans (quarterly * 4)
  int? _getOriginalPriceForCard(int cardIndex) {
    if (!_isAnnual) return null;
    if (_planTiers.isEmpty || cardIndex >= _planTiers.length) return null;
    final tier = _planTiers[cardIndex];
    final quarterlyPlan = tier['quarterlyPlan'] as PlanResponse?;
    if (quarterlyPlan != null) {
      return (quarterlyPlan.priceCents * 4) ~/ 100;
    }
    return null;
  }

  String _getBillingLabel(int cardIndex) {
    if (_planTiers.isEmpty || cardIndex >= _planTiers.length) return 'per year';
    final tier = _planTiers[cardIndex];
    final plan = _isAnnual ? (tier['yearlyPlan'] as PlanResponse?) : (tier['quarterlyPlan'] as PlanResponse?);
    if (plan != null) {
      return plan.billingCycle == 'yearly' ? 'per year' : 'per quarter';
    }
    return _isAnnual ? 'per year' : 'per quarter';
  }

  int get _validityDays {
    final dbPlan = _selectedDbPlan;
    if (dbPlan != null) {
      return dbPlan.billingCycle == 'yearly' ? 365 : 90;
    }
    return _isAnnual ? 360 : 90;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Subscription', style: GoogleFonts.outfit(color: Colors.white, fontWeight: LuminaTokens.fontWeightSemibold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : _planTiers.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: LuminaTokens.spacingLg),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LuminaTokens.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Lumina',
                                style: GoogleFonts.outfit(
                                  fontSize: LuminaTokens.textXl,
                                  fontWeight: LuminaTokens.fontWeightBold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: LuminaTokens.spacingLg),
                              Text(
                                'UPGRADE YOUR PLAN',
                                style: GoogleFonts.outfit(
                                  fontSize: LuminaTokens.textSm,
                                  fontWeight: LuminaTokens.fontWeightSemibold,
                                  color: const Color(0xFF38BDF8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: LuminaTokens.spacingLg),

                          // Billing Toggle
                          _buildBillingToggle(),

                          const SizedBox(height: LuminaTokens.spacingXs),
                          Text(
                            'ALL PLANS HAVE UNLIMITED FACIAL RECOGNITION',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: LuminaTokens.fontWeightSemibold,
                              color: const Color(0xFF38BDF8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: LuminaTokens.spacingMd),
                        ],
                      ),
                    ),

                    // Plan Carousel — fully dynamic
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _planTiers.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPlanIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _buildPlanCard(_planTiers[index], index == _currentPlanIndex, index);
                        },
                      ),
                    ),

                    // Bottom Actions
                    _buildBottomActions(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            'No plans available',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchDbPlans();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6091),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: LuminaTokens.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Bill Quarterly', !_isAnnual, () {
            setState(() => _isAnnual = false);
          }),
          _buildToggleButton('Bill Annually', _isAnnual, () {
            setState(() => _isAnnual = true);
          }),
          if (_isAnnual) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '30%\noff',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: LuminaTokens.fontWeightBold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ).animate().scale(
              duration: 300.ms,
              curve: Curves.elasticOut,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E6091) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: LuminaTokens.textSm,
            fontWeight: isActive ? LuminaTokens.fontWeightSemibold : LuminaTokens.fontWeightRegular,
            color: isActive ? Colors.white : LuminaTokens.darkTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> tier, bool isActive, int index) {
    final price = _getPlanPriceForCard(index);
    final billingLabel = _getBillingLabel(index);
    final originalPrice = _getOriginalPriceForCard(index);
    final features = tier['features'] as List<String>;
    final planName = tier['name'] as String;
    final icon = tier['icon'] as IconData;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: LuminaTokens.spacingSm),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF38BDF8) : LuminaTokens.darkBorder,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LuminaTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price section
            if (originalPrice != null) ...[
              Text(
                '₹$originalPrice',
                style: GoogleFonts.outfit(
                  fontSize: LuminaTokens.textMd,
                  color: isActive ? Colors.grey.shade500 : LuminaTokens.darkTextMuted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: isActive ? Colors.grey.shade500 : LuminaTokens.darkTextMuted,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹ $price',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: LuminaTokens.fontWeightBold,
                    color: isActive ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    '/$billingLabel + GST',
                    style: GoogleFonts.inter(
                      fontSize: LuminaTokens.textSm,
                      color: isActive ? Colors.grey.shade600 : LuminaTokens.darkTextMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  planName,
                  style: GoogleFonts.outfit(
                    fontSize: LuminaTokens.textLg,
                    fontWeight: LuminaTokens.fontWeightSemibold,
                    color: isActive ? const Color(0xFF1E6091) : const Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? const Color(0xFF1E6091) : const Color(0xFF38BDF8),
                ),
              ],
            ),
            const SizedBox(height: LuminaTokens.spacingMd),
            Divider(
              color: isActive ? Colors.grey.shade200 : LuminaTokens.darkBorder.withValues(alpha: 0.5),
            ),
            const SizedBox(height: LuminaTokens.spacingSm),

            // Features List — from database
            ...features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: isActive ? const Color(0xFF1E6091) : const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.inter(
                          fontSize: LuminaTokens.textSm,
                          color: isActive ? const Color(0xFF334155) : LuminaTokens.darkTextMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(LuminaTokens.spacingLg, LuminaTokens.spacingMd, LuminaTokens.spacingLg, LuminaTokens.spacingLg),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: LuminaTokens.darkBorder.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Proceed to Pay Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showPurchaseBottomSheet();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Proceed to Pay',
                  style: GoogleFonts.outfit(
                    fontSize: LuminaTokens.textMd,
                    fontWeight: LuminaTokens.fontWeightSemibold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: LuminaTokens.spacingMd),
            // Share Payment Link
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Payment Link via',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: LuminaTokens.darkTextMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildShareIcon(Icons.chat_rounded, const Color(0xFF25D366)),
                    const SizedBox(width: 12),
                    _buildShareIcon(Icons.email_rounded, const Color(0xFFEA4335)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareIcon(IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement share via WhatsApp / Email
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showPurchaseBottomSheet() {
    if (_planTiers.isEmpty || _currentPlanIndex >= _planTiers.length) return;
    final tier = _planTiers[_currentPlanIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PurchaseBottomSheet(
        planName: tier['name'] as String,
        billingFrequency: _isAnnual ? 'Yearly' : 'Quarterly',
        validityDays: _validityDays,
        basePriceCents: _selectedDbPlan?.priceCents ?? 0,
        planId: _selectedPlanId,
      ),
    );
  }
}
