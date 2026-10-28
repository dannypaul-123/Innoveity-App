import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_dropdown_menu.dart';
import '../widgets/app_avatar.dart';
import '../services/file_saver.dart';

class AssetManagementScreen extends StatefulWidget {
  final AppState state;

  const AssetManagementScreen({super.key, required this.state});

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Statuses';

  List<SystemAsset> get _allAssets => widget.state.systemAssets;

  bool get _isAdminView => widget.state.isAdmin && !widget.state.previewAsEmployee;

  String get _currentEmployeeName {
    final name = widget.state.userProfile.name.trim();
    if (name.isNotEmpty && name.toLowerCase() != 'employee') {
      return name;
    }
    return 'Daniel Paul';
  }

  bool _isAssignedToCurrentEmployee(SystemAsset asset) {
    final current = _currentEmployeeName.trim().toLowerCase();
    final assigned = asset.assignedTo.trim().toLowerCase();
    if (assigned.isEmpty || assigned == 'unassigned') return false;
    if (assigned == current) return true;

    // Match by email prefix if present in user profile
    final userEmail = widget.state.userProfile.email.trim().toLowerCase();
    if (userEmail.isNotEmpty) {
      final emailPrefix = userEmail.split('@').first.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
      final cleanAssigned = assigned.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
      if (emailPrefix.isNotEmpty && cleanAssigned.isNotEmpty &&
          (emailPrefix == cleanAssigned || cleanAssigned.contains(emailPrefix))) {
        return true;
      }
    }
    return false;
  }

  List<SystemAsset> get _scopeAssets {
    if (_isAdminView) {
      return _allAssets;
    }
    return _allAssets.where(_isAssignedToCurrentEmployee).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SystemAsset> get _filteredAssets {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _scopeAssets.where((asset) {
      final matchesQuery = query.isEmpty ||
          asset.id.toLowerCase().contains(query) ||
          asset.name.toLowerCase().contains(query) ||
          asset.serialNumber.toLowerCase().contains(query) ||
          asset.assignedTo.toLowerCase().contains(query) ||
          asset.location.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (_selectedCategory != 'All Categories' && asset.category != _selectedCategory) {
        return false;
      }
      if (_selectedStatus != 'All Statuses' && asset.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _availableCount => _scopeAssets.where((a) => a.status == 'AVAILABLE').length;
  int get _assignedCount => _scopeAssets.where((a) => a.status == 'ASSIGNED').length;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final bgCanvas = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final brandOrange = const Color(0xFFEA580C);

    final filtered = _filteredAssets;

    return Scaffold(
      drawer: AppDrawer(state: widget.state, activeRoute: 'assets'),
      backgroundColor: bgCanvas,
      appBar: AppBar(
        leading: AppDropdownMenu(state: widget.state),
        titleSpacing: 8,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.laptop_mac_outlined,
                    color: Color(0xFFEA580C),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Asset Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: widget.state.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: buildUserAvatar(
              avatar: widget.state.userProfile.avatar,
              name: widget.state.userProfile.name,
              size: 28,
              backgroundColor: brandOrange,
              fontSize: 12,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb path
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Row(
                  children: [
                    Text(
                      'Portal',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    ),
                    Text(
                      ' / Operations / ',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    ),
                    Text(
                      'Asset Management',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandOrange),
                    ),
                  ],
                ),
              ),

              // 1. Header Banner Card (Matching CRM Screenshot)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                      ),
                      child: Icon(
                        Icons.laptop_mac_outlined,
                        color: brandOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asset Management Overview',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Hardware systems and user allocations.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Three KPI Metric Cards (Matching Screenshot)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'TOTAL ASSETS',
                      count: '${_scopeAssets.length}',
                      numberColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      cardBg: cardBg,
                      borderCol: borderCol,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'AVAILABLE',
                      count: '$_availableCount',
                      numberColor: const Color(0xFF16A34A), // Green
                      cardBg: cardBg,
                      borderCol: borderCol,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'ASSIGNED',
                      count: '$_assignedCount',
                      numberColor: const Color(0xFF2563EB), // Blue
                      cardBg: cardBg,
                      borderCol: borderCol,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Search Bar, Dropdowns, and Action Buttons (Matching Screenshot)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  children: [
                    // Search Input
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by ID, name, brand, S/N...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderCol),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderCol),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filters & Actions Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Category Dropdown
                        PopupMenuButton<String>(
                          initialValue: _selectedCategory,
                          onSelected: (val) => setState(() => _selectedCategory = val),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedCategory,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textLight : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 16),
                              ],
                            ),
                          ),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'All Categories', child: Text('All Categories')),
                            PopupMenuItem(value: 'NETWORK', child: Text('Network')),
                            PopupMenuItem(value: 'PRINTER', child: Text('Printer')),
                            PopupMenuItem(value: 'MOBILE', child: Text('Mobile / Camera')),
                            PopupMenuItem(value: 'LAPTOP', child: Text('Laptop')),
                            PopupMenuItem(value: 'DESKTOP', child: Text('Desktop / Monitor')),
                            PopupMenuItem(value: 'PERIPHERAL', child: Text('Peripherals')),
                            PopupMenuItem(value: 'ACCESSORY', child: Text('Accessories')),
                            PopupMenuItem(value: 'FURNITURE', child: Text('Furniture')),
                          ],
                        ),
                        // Status Dropdown
                        PopupMenuButton<String>(
                          initialValue: _selectedStatus,
                          onSelected: (val) => setState(() => _selectedStatus = val),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedStatus,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textLight : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 16),
                              ],
                            ),
                          ),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'All Statuses', child: Text('All Statuses')),
                            PopupMenuItem(value: 'AVAILABLE', child: Text('Available Only')),
                            PopupMenuItem(value: 'ASSIGNED', child: Text('Assigned Only')),
                            PopupMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
                          ],
                        ),
                        // Export CSV
                        OutlinedButton.icon(
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          label: const Text('Export CSV', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.textLight : AppColors.textDark,
                            side: BorderSide(color: borderCol),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        // + Add Asset (Only accessible by Admin, not on Employee side)
                        if (_isAdminView)
                          ElevatedButton.icon(
                            onPressed: () => _showAddOrEditAssetModal(context),
                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                            label: const Text(
                              '+ Add Asset',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandOrange,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. Asset Table / Cards
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 40, color: isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text(
                        _searchCtrl.text.isNotEmpty || _selectedCategory != 'All Categories' || _selectedStatus != 'All Statuses'
                            ? 'No matching assets found.'
                            : (_isAdminView ? 'No assets found.' : 'No assets assigned yet.'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _searchCtrl.text.isNotEmpty || _selectedCategory != 'All Categories' || _selectedStatus != 'All Statuses'
                            ? 'Try clearing search filters.'
                            : (_isAdminView
                                ? 'Try clearing search filters or add a new equipment item.'
                                : 'You do not have any company assets assigned to your name by the admin.'),
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final asset = filtered[i];
                    return _buildAssetRowCard(asset, cardBg, borderCol, isDark, brandOrange);
                  },
                ),
            ],
          ),
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

  Widget _buildMetricCard({
    required String label,
    required String count,
    required Color numberColor,
    required Color cardBg,
    required Color borderCol,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: numberColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetRowCard(
    SystemAsset asset,
    Color cardBg,
    Color borderCol,
    bool isDark,
    Color brandOrange,
  ) {
    final isAvailable = asset.status == 'AVAILABLE';
    final statusBg = isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
    final statusText = isAvailable ? const Color(0xFF15803D) : const Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Asset ID + Category Badge + Status Badge
          Row(
            children: [
              Text(
                asset.id,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  asset.category,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark ? AppColors.textLightMuted : const Color(0xFF475569),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  asset.status,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusText,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Laptop Icon + Name + Location
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Icon(Icons.laptop_mac_outlined, size: 18, color: brandOrange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      asset.location,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Row 3: S/N + Assigned To info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SERIAL NUMBER',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.serialNumber,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASSIGNED TO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.assignedTo,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: asset.assignedTo == 'Unassigned'
                            ? (isDark ? AppColors.textLightMuted : const Color(0xFF64748B))
                            : const Color(0xFF047857),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 4: Action Buttons (Eye, Edit, Bill, Assign)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // View Eye
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                tooltip: 'View Details',
                color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                onPressed: () => _showAssetDetailsModal(context, asset),
              ),
              if (_isAdminView) ...[
                const SizedBox(width: 4),
                // Edit Pencil (Admin only)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Asset',
                  color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  onPressed: () => _showAddOrEditAssetModal(context, existing: asset),
                ),
              ],
              const SizedBox(width: 4),
              // Bill
              TextButton.icon(
                icon: const Icon(Icons.receipt_long_outlined, size: 15),
                label: const Text('Bill', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showAssetBillModal(context, asset),
              ),
              if (_isAdminView) ...[
                const SizedBox(width: 4),
                // Assign / Reassign (Admin only)
                TextButton.icon(
                  icon: Icon(
                    asset.assignedTo == 'Unassigned' ? Icons.person_add_alt_outlined : Icons.swap_horiz,
                    size: 15,
                  ),
                  label: Text(asset.assignedTo == 'Unassigned' ? 'Assign' : 'Reassign', style: const TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF058A5E),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showAssignAssetModal(context, asset),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('Asset ID,Asset Name,Category,Serial Number,Assigned To,Status,Location,Cost (INR)');
    for (final a in _scopeAssets) {
      buffer.writeln('${a.id},"${a.name}",${a.category},${a.serialNumber},"${a.assignedTo}",${a.status},"${a.location}",${a.cost.toInt()}');
    }
    final bytes = buffer.toString().codeUnits;
    final fileName = 'assets_inventory_${DateTime.now().millisecondsSinceEpoch}.csv';
    final path = await saveAndDownloadFile(bytes, fileName, context: context);
    if (!mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${_scopeAssets.length} assets report to $path'),
          backgroundColor: const Color(0xFFEA580C),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Export cancelled or storage permission was not granted.'),
        ),
      );
    }
  }

  void _showAssetDetailsModal(BuildContext context, SystemAsset asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF7ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.laptop_mac_outlined, color: Color(0xFFEA580C), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(asset.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1),
                              Text('${asset.id} • ${asset.category}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow(Icons.qr_code, 'Serial Number', asset.serialNumber),
              _buildDetailRow(Icons.place_outlined, 'Location', asset.location),
              _buildDetailRow(Icons.person_outline, 'Assigned Employee', asset.assignedTo),
              _buildDetailRow(Icons.verified_outlined, 'Status', asset.status),
              _buildDetailRow(Icons.currency_rupee, 'Procurement Value', '₹${asset.cost.toInt()}'),
              _buildDetailRow(Icons.receipt_outlined, 'Invoice Number', asset.invoiceNumber),
              _buildDetailRow(Icons.shield_outlined, 'Warranty Period', asset.warrantyPeriod),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAssetBillModal(BuildContext context, SystemAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text('Invoice: ${asset.id}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipment: ${asset.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Invoice Number: ${asset.invoiceNumber}'),
            Text('Procurement Cost: ₹${asset.cost.toInt()}'),
            Text('Warranty: ${asset.warrantyPeriod}'),
            Text('Vendor: Authorized Enterprise Tech Distributor'),
            Text('Billing Entity: Innoveity Tech Private Limited'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloaded invoice for ${asset.name}')),
              );
            },
            icon: const Icon(Icons.download, size: 16, color: Colors.white),
            label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  void _showAssignAssetModal(BuildContext context, SystemAsset asset) {
    final staffNames = {
      ...AppState.userDirectory.values.map((u) => u.name).where((n) => n.isNotEmpty && n != 'System Admin' && n != 'Super Admin'),
      'Daniel Paul', 'Harish', 'Priya Sharma', 'Rahul Verma', 'Anita Desai', 'Vikram Patel', 'Neha Gupta', 'Arun Kumar',
      'Unassigned',
    }.toList();
    String chosen = asset.assignedTo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Assign Asset: ${asset.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Select employee to allocate "${asset.name}":', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: chosen,
                    decoration: InputDecoration(
                      labelText: 'Allocate To Employee',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: staffNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => chosen = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.state.assignSystemAsset(asset.id, chosen);
                        });
                        widget.state.addAuditLog(
                          'Asset Allocation',
                          'Allocated ${asset.name} (${asset.id}) to $chosen',
                          widget.state.userProfile.email,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${asset.name} is now allocated to $chosen!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Confirm Allocation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddOrEditAssetModal(BuildContext context, {SystemAsset? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final serialCtrl = TextEditingController(text: existing?.serialNumber ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? 'Office');
    final costCtrl = TextEditingController(text: existing != null ? '${existing.cost.toInt()}' : '15000');
    String category = existing?.category ?? 'NETWORK';
    String status = existing?.status ?? 'AVAILABLE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Add New Asset' : 'Edit Asset (${existing.id})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Asset Name *',
                        hintText: 'e.g. Brother Printer, MacBook Pro',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'NETWORK', child: Text('NETWORK')),
                              DropdownMenuItem(value: 'PRINTER', child: Text('PRINTER')),
                              DropdownMenuItem(value: 'MOBILE', child: Text('MOBILE')),
                              DropdownMenuItem(value: 'LAPTOP', child: Text('LAPTOP')),
                              DropdownMenuItem(value: 'DESKTOP', child: Text('DESKTOP')),
                              DropdownMenuItem(value: 'PERIPHERAL', child: Text('PERIPHERAL')),
                              DropdownMenuItem(value: 'ACCESSORY', child: Text('ACCESSORY')),
                              DropdownMenuItem(value: 'FURNITURE', child: Text('FURNITURE')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'AVAILABLE', child: Text('AVAILABLE')),
                              DropdownMenuItem(value: 'ASSIGNED', child: Text('ASSIGNED')),
                              DropdownMenuItem(value: 'MAINTENANCE', child: Text('MAINTENANCE')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => status = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: serialCtrl,
                      decoration: InputDecoration(
                        labelText: 'Serial Number / S/N',
                        hintText: 'e.g. SN-KM8821 or N/A',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: locationCtrl,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              hintText: 'Office / Floor',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cost (₹)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setState(() {
                            if (existing != null) {
                              existing.name = nameCtrl.text.trim();
                              existing.category = category;
                              existing.status = status;
                              existing.serialNumber = serialCtrl.text.trim().isEmpty ? 'N/A' : serialCtrl.text.trim();
                              existing.location = locationCtrl.text.trim();
                              existing.cost = double.tryParse(costCtrl.text.trim()) ?? existing.cost;
                              widget.state.updateSystemAsset(existing);
                            } else {
                              widget.state.addSystemAsset(
                                SystemAsset(
                                  id: 'AST-${1013 + _allAssets.length}',
                                  name: nameCtrl.text.trim(),
                                  category: category,
                                  status: status,
                                  serialNumber: serialCtrl.text.trim().isEmpty ? 'N/A' : serialCtrl.text.trim(),
                                  location: locationCtrl.text.trim(),
                                  cost: double.tryParse(costCtrl.text.trim()) ?? 15000,
                                  assignedTo: status == 'AVAILABLE' ? 'Unassigned' : 'Daniel Paul',
                                ),
                              );
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existing == null ? 'Added new asset "${nameCtrl.text.trim()}"' : 'Updated ${existing.name}'),
                              backgroundColor: const Color(0xFFEA580C),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          existing == null ? '+ Create Asset' : 'Save Changes',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
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

  Widget _buildDetailRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFEA580C)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
