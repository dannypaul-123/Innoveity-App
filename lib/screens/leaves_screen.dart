import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';

class LeavesScreen extends StatefulWidget {
  final List<LeaveBalance> balances;
  final List<LeaveRequest> requests;
  final Function(LeaveRequest) onApplyLeave;
  final String? userName;
  final String? userRole;
  final LeaveRequest? latestApprovedLeave;
  final bool showLeaveApprovalNotice;
  final VoidCallback? onDismissLeaveNotice;
  final List<UserProfile>? allEmployees;

  const LeavesScreen({
    super.key,
    required this.balances,
    required this.requests,
    required this.onApplyLeave,
    this.userName,
    this.userRole,
    this.latestApprovedLeave,
    this.showLeaveApprovalNotice = false,
    this.onDismissLeaveNotice,
    this.allEmployees,
  });

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingCount = widget.requests.where((r) => r.status == 'Pending').length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyLeaveModal(context),
        backgroundColor: AppColors.primaryPine,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Apply Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showLeaveApprovalNotice && widget.latestApprovedLeave != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF059669) : const Color(0xFF10B981),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      widget.onDismissLeaveNotice?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Leave approval message marked as read.'),
                          backgroundColor: Color(0xFF059669),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.userRole?.toUpperCase() == 'INTERN'
                                            ? 'Intern Leave Sanctioned! 🎉'
                                            : 'Leave Request Approved! 🎉',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF065F46),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'APPROVED',
                                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Your ${widget.latestApprovedLeave!.leaveType} (${widget.latestApprovedLeave!.daysCount} Day) from ${widget.latestApprovedLeave!.startDate} to ${widget.latestApprovedLeave!.endDate} was approved by Admin.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857),
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded, size: 12, color: isDark ? Colors.white : const Color(0xFF047857)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Mark as Read',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onDismissLeaveNotice != null)
                            IconButton(
                              icon: Icon(Icons.close, size: 18, color: isDark ? Colors.white70 : const Color(0xFF047857)),
                              onPressed: () {
                                widget.onDismissLeaveNotice?.call();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Leave approval message marked as read.'),
                                    backgroundColor: Color(0xFF059669),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Dismiss Notification',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Leave Balances Section
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Leave Balances',
                    style: theme.textTheme.headlineSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.completedBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.completedBorder),
                  ),
                  child: const Text(
                    'Monthly Credit',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.completedText),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Horizontal Balances Scroll
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.balances.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final b = widget.balances[index];
                  return Container(
                    width: 110,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.borderLight),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          b.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${b.daysLeft}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.textLight : AppColors.textDark),
                          ),
                        ),
                        Text(
                          'Days Left',
                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primaryPine.withValues(alpha: 0.25) : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${b.usedDays} / ${b.totalDays} used',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Sub-footer Counters Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Pending Requests: ',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                        ),
                        Text(
                          '$pendingCount',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.pendingText),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Annual Quota Active',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryPine),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Leave History
            Text(
              'Leave Applications & History',
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = widget.requests[index];
                return _buildRequestCard(req);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(LeaveRequest req) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusBg;
    Color statusText;
    Color statusBorder;

    switch (req.status) {
      case 'Approved':
        statusBg = AppColors.completedBg;
        statusText = AppColors.completedText;
        statusBorder = AppColors.completedBorder;
        break;
      case 'Pending':
        statusBg = AppColors.pendingBg;
        statusText = AppColors.pendingText;
        statusBorder = AppColors.pendingBorder;
        break;
      default:
        statusBg = AppColors.alertBg;
        statusText = AppColors.alertText;
        statusBorder = AppColors.alertBorder;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event, size: 16, color: AppColors.primaryPine),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req.leaveType,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Text(
                    req.status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${req.startDate}  —  ${req.endDate} (${req.daysCount} Day)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              req.reason,
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyLeaveModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedType = 'WFH';
    final reasonController = TextEditingController();
    final DateTime startDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Apply for Leave / WFH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Leave Category', border: OutlineInputBorder()),
                items: widget.balances
                    .map((b) => DropdownMenuItem(value: b.type, child: Text('${b.type} (${b.daysLeft} left)', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Leave',
                  hintText: 'Brief context for manager approval...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final rawReason = reasonController.text.trim();
                    final effectiveReason = rawReason.isNotEmpty ? rawReason : 'Personal Leave';
                    final effectiveApplicant = (widget.userName != null && widget.userName!.isNotEmpty)
                        ? widget.userName!
                        : 'Daniel Paul';

                    widget.onApplyLeave(
                      LeaveRequest(
                        id: 'LR-${DateTime.now().millisecondsSinceEpoch % 100000}',
                        leaveType: selectedType,
                        startDate: '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
                        endDate: '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
                        daysCount: 1,
                        status: 'Pending',
                        reason: effectiveReason,
                        applicantName: effectiveApplicant,
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Leave request for $selectedType submitted successfully!'),
                        backgroundColor: AppColors.primaryPine,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
