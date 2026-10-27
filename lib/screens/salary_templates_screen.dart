import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';

class SalaryTemplatesScreen extends StatelessWidget {
  final AppState state;
  final bool isStandalone;

  const SalaryTemplatesScreen({
    super.key,
    required this.state,
    this.isStandalone = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;

    if (!isStandalone) {
      return SalaryTemplatesBody(state: state, isDark: isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDarkBody : const Color(0xFFFAF9F6),
      drawer: AppDrawer(state: state, activeRoute: 'salary_templates'),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
        titleSpacing: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDBA74), width: 1),
              ),
              child: const Icon(Icons.layers_rounded, color: Color(0xFFEA580C), size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Salary Structure Templates',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
            ),
            onPressed: state.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Salary templates refreshed and synchronized.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Synchronize Templates',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SalaryTemplatesBody(state: state, isDark: isDark),
      ),
    );
  }
}

class SalaryTemplatesBody extends StatelessWidget {
  final AppState state;
  final bool isDark;

  const SalaryTemplatesBody({
    super.key,
    required this.state,
    required this.isDark,
  });

  void _openTemplateDialog(BuildContext context, [SalaryTemplate? existing]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SalaryTemplateFormDialog(
        state: state,
        existing: existing,
        isDark: isDark,
      ),
    );
  }

  void _confirmDeleteTemplate(BuildContext context, SalaryTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Salary Template?'),
        content: Text('Are you sure you want to remove the "${template.name}" template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.deleteSalaryTemplate(template.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted template "${template.name}".'),
                  backgroundColor: const Color(0xFFEF4444),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = state.salaryTemplates;
    final isCompact = MediaQuery.of(context).size.width < 450;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner / Header matching the exact web screenshot
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDBA74)),
                      ),
                      child: const Icon(Icons.layers_rounded, color: Color(0xFFEA580C), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salary Structure Templates',
                            style: TextStyle(
                              fontSize: isCompact ? 17 : 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Configure standardized salary components by role for quick assignment across Innoveity Tech.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openTemplateDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'Create Template',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Templates List / Cards
          if (templates.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.layers_clear_outlined, size: 40, color: isDark ? Colors.white30 : Colors.grey.shade400),
                    const SizedBox(height: 10),
                    const Text('No salary templates configured yet.'),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: () => _openTemplateDialog(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                      child: const Text('Create Developer Template', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final template = templates[idx];
                final usersAssigned = state.countAssignedUsersForTemplate(template);
                final net = template.estimatedNetPay;
                final pfTotal = template.basicSalary * (template.pfPercentage / 100);
                final taxTotal = template.basicSalary * (template.taxPercentage / 100);
                final hraTotal = template.hra + template.da;
                final allowancesTotal = template.specialAllowance + template.bonus;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Role Chip + Edit & Delete Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: Text(
                              template.role.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEA580C),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _openTemplateDialog(context, template),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _confirmDeleteTemplate(context, template),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Title & Description matching screenshot
                      Text(
                        template.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Components Rows
                      _buildComponentRow('Basic Salary:', '₹${template.basicSalary.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}', isDark),
                      const SizedBox(height: 5),
                      _buildComponentRow('HRA + DA:', '₹${hraTotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}', isDark),
                      const SizedBox(height: 5),
                      _buildComponentRow('Allowances & Bonus:', '₹${allowancesTotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}', isDark),
                      const SizedBox(height: 5),
                      _buildComponentRow(
                        'PF (${template.pfPercentage.toInt()}%) + Tax (${template.taxPercentage.toInt()}%)'
                        '${template.deductions > 0 ? " + Deductions" : ""}:',
                        '₹${(pfTotal + taxTotal + template.deductions).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        isDark,
                      ),

                      const SizedBox(height: 14),
                      Divider(height: 1, color: isDark ? AppColors.borderCardDark : const Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),

                      // Footer: Estimated Net Pay + Assigned Users
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESTIMATED NET PAY',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${net.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people_outline_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$usersAssigned user(s) assigned',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  state.applySalaryTemplateToEmployees(template);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Synchronized "${template.name}" template to $usersAssigned employee(s)!'),
                                      backgroundColor: const Color(0xFF10B981),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: const Text(
                                    'Apply to Staff',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildComponentRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class SalaryTemplateFormDialog extends StatefulWidget {
  final AppState state;
  final SalaryTemplate? existing;
  final bool isDark;

  const SalaryTemplateFormDialog({
    super.key,
    required this.state,
    this.existing,
    required this.isDark,
  });

  @override
  State<SalaryTemplateFormDialog> createState() => _SalaryTemplateFormDialogState();
}

class _SalaryTemplateFormDialogState extends State<SalaryTemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _basicCtrl;
  late TextEditingController _hraCtrl;
  late TextEditingController _daCtrl;
  late TextEditingController _allowanceCtrl;
  late TextEditingController _bonusCtrl;
  late TextEditingController _pfCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _deductionsCtrl;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '-');
    _basicCtrl = TextEditingController(text: t?.basicSalary.toInt().toString() ?? '20000');
    _hraCtrl = TextEditingController(text: t?.hra.toInt().toString() ?? '0');
    _daCtrl = TextEditingController(text: t?.da.toInt().toString() ?? '0');
    _allowanceCtrl = TextEditingController(text: t?.specialAllowance.toInt().toString() ?? '0');
    _bonusCtrl = TextEditingController(text: t?.bonus.toInt().toString() ?? '0');
    _pfCtrl = TextEditingController(text: t?.pfPercentage.toInt().toString() ?? '0');
    _taxCtrl = TextEditingController(text: t?.taxPercentage.toInt().toString() ?? '0');
    _deductionsCtrl = TextEditingController(text: t?.deductions.toInt().toString() ?? '0');
    _selectedRole = t?.role ?? 'EMPLOYEE';

    _basicCtrl.addListener(() => setState(() {}));
    _hraCtrl.addListener(() => setState(() {}));
    _daCtrl.addListener(() => setState(() {}));
    _allowanceCtrl.addListener(() => setState(() {}));
    _bonusCtrl.addListener(() => setState(() {}));
    _pfCtrl.addListener(() => setState(() {}));
    _taxCtrl.addListener(() => setState(() {}));
    _deductionsCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _basicCtrl.dispose();
    _hraCtrl.dispose();
    _daCtrl.dispose();
    _allowanceCtrl.dispose();
    _bonusCtrl.dispose();
    _pfCtrl.dispose();
    _taxCtrl.dispose();
    _deductionsCtrl.dispose();
    super.dispose();
  }

  double get _currentEstimatedNet {
    final basic = double.tryParse(_basicCtrl.text.trim()) ?? 0.0;
    final hra = double.tryParse(_hraCtrl.text.trim()) ?? 0.0;
    final da = double.tryParse(_daCtrl.text.trim()) ?? 0.0;
    final allow = double.tryParse(_allowanceCtrl.text.trim()) ?? 0.0;
    final bonus = double.tryParse(_bonusCtrl.text.trim()) ?? 0.0;
    final pfPercent = double.tryParse(_pfCtrl.text.trim()) ?? 0.0;
    final taxPercent = double.tryParse(_taxCtrl.text.trim()) ?? 0.0;
    final ded = double.tryParse(_deductionsCtrl.text.trim()) ?? 0.0;

    final earnings = basic + hra + da + allow + bonus;
    final pfAmount = basic * (pfPercent / 100);
    final taxAmount = basic * (taxPercent / 100);
    return (earnings - ded - pfAmount - taxAmount).clamp(0, double.infinity);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final template = SalaryTemplate(
      id: widget.existing?.id ?? 'ST-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      role: _selectedRole,
      description: _descCtrl.text.trim().isEmpty ? '-' : _descCtrl.text.trim(),
      basicSalary: double.tryParse(_basicCtrl.text.trim()) ?? 20000.0,
      hra: double.tryParse(_hraCtrl.text.trim()) ?? 0.0,
      da: double.tryParse(_daCtrl.text.trim()) ?? 0.0,
      specialAllowance: double.tryParse(_allowanceCtrl.text.trim()) ?? 0.0,
      bonus: double.tryParse(_bonusCtrl.text.trim()) ?? 0.0,
      pfPercentage: double.tryParse(_pfCtrl.text.trim()) ?? 0.0,
      taxPercentage: double.tryParse(_taxCtrl.text.trim()) ?? 0.0,
      deductions: double.tryParse(_deductionsCtrl.text.trim()) ?? 0.0,
      assignedUsersCount: widget.existing?.assignedUsersCount ?? 0,
    );

    widget.state.saveSalaryTemplate(template);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Salary template "${template.name}" saved & applied to employee profiles!'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.style_rounded, color: Color(0xFFEA580C), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          widget.existing == null ? 'Create Salary Template' : 'Edit Salary Template',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  'Define standardized salary components. Changes will automatically update assigned employee payslips and profile records.',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                ),
                const Divider(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Template Name & Role
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Template Name *',
                                  hintText: 'e.g. Developer',
                                  isDense: true,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedRole,
                                decoration: const InputDecoration(labelText: 'Role', isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'EMPLOYEE', child: Text('EMPLOYEE')),
                                  DropdownMenuItem(value: 'INTERN', child: Text('INTERN')),
                                  DropdownMenuItem(value: 'TEAM_LEADER', child: Text('TEAM LEADER')),
                                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRole = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'e.g. Standard Developer role package',
                            isDense: true,
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'EARNINGS COMPONENTS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _basicCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Basic Salary (₹) *',
                                  prefixText: '₹ ',
                                  isDense: true,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _hraCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'HRA (₹)',
                                  prefixText: '₹ ',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _allowanceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Special Allowance (₹)',
                                  prefixText: '₹ ',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _bonusCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Bonus / DA (₹)',
                                  prefixText: '₹ ',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'DEDUCTIONS & TAXES',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _pfCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'PF Contribution (%)',
                                  suffixText: '%',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _taxCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Income Tax TDS (%)',
                                  suffixText: '%',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _deductionsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Other Fixed Deductions (₹)',
                            prefixText: '₹ ',
                            isDense: true,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Calculated Net Pay Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'CALCULATED NET PAY',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFEA580C)),
                                  ),
                                  Text(
                                    'Applied across assigned staff',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF9A3412)),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${_currentEstimatedNet.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Save & Apply to Employees',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
