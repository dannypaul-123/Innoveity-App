import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_dropdown_menu.dart';
import 'announcements_screen.dart';
import 'main_navigation_screen.dart';

class TicketDeskScreen extends StatefulWidget {
  final List<ITTicket> tickets;
  final List<AssetItem> assets;
  final Function(ITTicket) onAddTicket;
  final AppState state;

  const TicketDeskScreen({
    super.key,
    required this.tickets,
    required this.assets,
    required this.onAddTicket,
    required this.state,
  });

  @override
  State<TicketDeskScreen> createState() => _TicketDeskScreenState();
}

class _TicketDeskScreenState extends State<TicketDeskScreen> {
  int _selectedTab = 0; // 0: IT Tickets, 1: Assigned Assets
  String _selectedStatusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredTickets = widget.tickets.where((t) {
      return _selectedStatusFilter == 'All' || t.status == _selectedStatusFilter;
    }).toList();

    final userName = widget.state.userProfile.name;
    final userEmployeeId = widget.state.userProfile.employeeId;
    final userRole = widget.state.userProfile.role;
    final userAvatar = widget.state.userProfile.avatar;

    return Scaffold(
      drawer: AppDrawer(state: widget.state, activeRoute: 'desk'),
      appBar: AppBar(
        leading: AppDropdownMenu(state: widget.state),
        titleSpacing: 8,
        title: Row(
          children: [
            buildUserAvatar(
              avatar: userAvatar,
              name: userName,
              size: 36,
              border: Border.all(color: AppColors.primaryPine, width: 1.5),
              backgroundColor: const Color(0xFFF97316),
              fontSize: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$userEmployeeId • ${userRole.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: () {
              showSearch(
                context: context,
                delegate: AppQuickSearchDelegate(
                  state: widget.state,
                  isDark: isDark,
                ),
              );
            },
            tooltip: 'Quick Search',
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            onPressed: () {
              widget.state.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnnouncementsScreen(state: widget.state),
                    ),
                  );
                },
                tooltip: 'Announcements & Alerts',
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEA580C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateTicketModal(context),
              backgroundColor: AppColors.primaryPine,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedTab == 0
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'IT Tickets (${widget.tickets.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                              color: _selectedTab == 0 ? AppColors.primaryPine : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedTab == 1
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'Assigned Assets (${widget.assets.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                              color: _selectedTab == 1 ? AppColors.primaryPine : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _selectedTab == 0 ? _buildTicketsView(filteredTickets) : _buildAssetsView(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.headerDarkPine : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderCardDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: widget.state.currentTab,
          onTap: (index) {
            widget.state.setTab(index);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
          selectedItemColor: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
          unselectedItemColor: isDark ? AppColors.textLightMuted : AppColors.textMuted,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_rounded),
              activeIcon: Icon(Icons.access_time_filled_rounded),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'Leaves',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsView(List<ITTicket> filteredTickets) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Open', 'In Progress', 'Resolved'].map((status) {
              final isSel = _selectedStatusFilter == status;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(status),
                  selected: isSel,
                  selectedColor: isDark ? AppColors.primaryPine.withValues(alpha: 0.25) : AppColors.surfaceContainerLow,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? AppColors.primaryPine : (isDark ? AppColors.textLight : AppColors.textDark),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedStatusFilter = status);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        filteredTickets.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 44,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Support Tickets',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? AppColors.textLight : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No IT support tickets logged yet. Tap "+ Create Ticket" to submit a request.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTickets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ticket = filteredTickets[index];
                  return _buildTicketCard(ticket);
                },
              ),
      ],
    );
  }

  Widget _buildTicketCard(ITTicket ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusBg;
    Color statusText;

    switch (ticket.status) {
      case 'In Progress':
        statusBg = AppColors.inProgressBg;
        statusText = AppColors.inProgressText;
        break;
      case 'Open':
        statusBg = AppColors.pendingBg;
        statusText = AppColors.pendingText;
        break;
      default:
        statusBg = AppColors.completedBg;
        statusText = AppColors.completedText;
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.id,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.textLight : AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticket.category,
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ticket.status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Priority: ${ticket.priority}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                ),
                Text(
                  ticket.createdAt,
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.assets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.devices_other,
              size: 44,
              color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No Assigned Assets',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your assigned laptops, hardware monitors, and security tokens will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.assets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final asset = widget.assets[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.laptop_mac, color: AppColors.primaryPine, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          asset.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.completedBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        asset.condition,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.completedText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(asset.model, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLightMuted : AppColors.textMuted)),
                const SizedBox(height: 4),
                Text('S/N: ${asset.serialNumber}  •  Assigned: ${asset.assignedDate}',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted)),
                Divider(height: 16, color: isDark ? const Color(0xFF334155) : AppColors.borderLight),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showCreateTicketModal(context, prefillTitle: 'Issue with ${asset.name}'),
                    icon: const Icon(Icons.report_problem, size: 14, color: AppColors.alertText),
                    label: const Text('Report Issue', style: TextStyle(color: AppColors.alertText, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateTicketModal(BuildContext context, {String? prefillTitle}) {
    final titleController = TextEditingController(text: prefillTitle ?? '');
    String category = 'Hardware';
    String priority = 'High';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                const Text('Create Support Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Ticket Summary',
                hintText: 'Describe hardware or IT access issue...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Hardware', child: Text('Hardware & Devices')),
                DropdownMenuItem(value: 'Access & Security', child: Text('Access & Security')),
                DropdownMenuItem(value: 'Peripherals', child: Text('Peripherals & Cable')),
                DropdownMenuItem(value: 'Software', child: Text('Software License')),
              ],
              onChanged: (val) {
                if (val != null) category = val;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    widget.onAddTicket(
                      ITTicket(
                        id: 'INC-${DateTime.now().millisecondsSinceEpoch % 10000}',
                        title: titleController.text,
                        category: category,
                        priority: priority,
                        status: 'Open',
                        createdAt: 'Just now',
                      ),
                    );
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
