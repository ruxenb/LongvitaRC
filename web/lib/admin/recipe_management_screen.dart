import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_core/services/admin_service.dart';
import 'package:longvita_admin/admin/admin_states.dart';
import 'package:longvita_admin/admin/admin_viewmodels.dart';

class RecipeManagementScreen extends StatefulWidget {
  const RecipeManagementScreen({super.key});

  @override
  State<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<RecipeAdminViewModel>().start(),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<RecipeAdminViewModel>(
    builder: (context, vm, _) => LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Padding(
          padding: EdgeInsets.all(compact ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPageHeader(
                title: 'Quản lý công thức',
                subtitle: 'Tạo, chỉnh sửa và lưu trữ món ăn dùng trên ứng dụng di động',
                action: FilledButton.icon(
                  onPressed: vm.saving ? null : () => _openEditor(context, vm),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm công thức'),
                ),
              ),
              SizedBox(height: compact ? 16 : 24),
              TextField(
                onChanged: vm.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm theo tên hoặc danh mục',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: vm.state == AdminLoadState.ready
                    ? _RecipeTable(
                        vm: vm,
                        compact: compact,
                        onEdit: (recipe) => _openEditor(context, vm, recipe),
                      )
                    : AdminStateView(
                        state: vm.state,
                        error: vm.error,
                        emptyTitle: 'Chưa có công thức',
                        emptyMessage: 'Tạo công thức đầu tiên để Mobile có dữ liệu sử dụng.',
                        retry: vm.start,
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _openEditor(
    BuildContext context,
    RecipeAdminViewModel vm, [
    RecipeModel? recipe,
  ]) async {
    final saved = await showDialog<RecipeModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecipeEditor(recipe: recipe),
    );
    if (saved == null) return;
    try {
      await vm.save(saved);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã lưu công thức.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể lưu: $error')));
      }
    }
  }
}

class _RecipeTable extends StatelessWidget {
  final RecipeAdminViewModel vm;
  final bool compact;
  final Future<void> Function(RecipeModel recipe) onEdit;

  const _RecipeTable({
    required this.vm,
    required this.compact,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final rows = vm.recipes;
    if (rows.isEmpty) {
      return const AdminStateView(
        state: AdminLoadState.empty,
        emptyTitle: 'Không tìm thấy công thức',
        emptyMessage: 'Hãy thử từ khóa khác.',
      );
    }
    if (compact) {
      return ListView.separated(
        key: const ValueKey('recipe-compact-list'),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _CompactRecipeCard(recipe: rows[index], vm: vm, onEdit: onEdit),
      );
    }
    return Card(
      key: const ValueKey('recipe-desktop-table'),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Tên món')),
              DataColumn(label: Text('Danh mục')),
              DataColumn(label: Text('Kcal'), numeric: true),
              DataColumn(label: Text('Protein'), numeric: true),
              DataColumn(label: Text('Trạng thái')),
              DataColumn(label: Text('Thao tác')),
            ],
            rows: [
              for (final recipe in rows)
                DataRow(
                  cells: [
                    DataCell(Text(recipe.name)),
                    DataCell(Text(recipe.category)),
                    DataCell(Text(recipe.calories.toStringAsFixed(0))),
                    DataCell(
                      Text('${recipe.proteinGrams.toStringAsFixed(1)} g'),
                    ),
                    DataCell(
                      Chip(
                        label: Text(
                          recipe.isArchived ? 'Đã lưu trữ' : 'Đang dùng',
                        ),
                        backgroundColor: recipe.isArchived
                            ? AppColors.disabledBg
                            : AppColors.bgSelected,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Chỉnh sửa',
                            onPressed: () => onEdit(recipe),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: recipe.isArchived
                                ? 'Khôi phục'
                                : 'Lưu trữ',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await vm.archive(recipe);
                              } catch (error) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Không thể cập nhật: $error'),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              recipe.isArchived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactRecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final RecipeAdminViewModel vm;
  final Future<void> Function(RecipeModel recipe) onEdit;

  const _CompactRecipeCard({
    required this.recipe,
    required this.vm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.category,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(recipe.isArchived ? 'Đã lưu trữ' : 'Đang dùng'),
                backgroundColor: recipe.isArchived
                    ? AppColors.disabledBg
                    : AppColors.bgSelected,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${recipe.calories.toStringAsFixed(0)} kcal  |  '
            '${recipe.proteinGrams.toStringAsFixed(1)} g protein',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Chỉnh sửa',
                onPressed: () => onEdit(recipe),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: recipe.isArchived ? 'Khôi phục' : 'Lưu trữ',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await vm.archive(recipe);
                  } catch (error) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Không thể cập nhật: $error')),
                    );
                  }
                },
                icon: Icon(
                  recipe.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RecipeEditor extends StatefulWidget {
  final RecipeModel? recipe;
  const _RecipeEditor({this.recipe});

  @override
  State<_RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends State<_RecipeEditor> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.recipe?.name);
  late final description = TextEditingController(
    text: widget.recipe?.description,
  );
  late final calories = TextEditingController(
    text: widget.recipe?.calories.toString(),
  );
  late final protein = TextEditingController(
    text: widget.recipe?.proteinGrams.toString(),
  );
  late final ingredients = TextEditingController(
    text: widget.recipe?.ingredients.map((row) => row.name).join('\n'),
  );
  late final instructions = TextEditingController(
    text: widget.recipe?.instructions.join('\n'),
  );
  late final source = TextEditingController(text: widget.recipe?.sourceNote);
  late String category = widget.recipe?.category ?? 'rau_cu';

  static const categoryLabels = {
    'rau_cu': 'Rau củ',
    'dau': 'Đậu',
    'ca': 'Cá',
    'ngu_coc': 'Ngũ cốc',
  };

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    calories.dispose();
    protein.dispose();
    ingredients.dispose();
    instructions.dispose();
    source.dispose();
    super.dispose();
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Không được để trống' : null;

  String? positiveNumber(String? value) {
    final number = double.tryParse(value ?? '');
    return number == null || !number.isFinite || number < 0
        ? 'Nhập số hợp lệ'
        : null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.recipe == null ? 'Thêm công thức' : 'Sửa công thức'),
    content: SizedBox(
      width: 720,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Wrap(
            runSpacing: 16,
            spacing: 16,
            children: [
              _field(name, 'Tên món', validator: requiredText, wide: true),
              _field(description, 'Mô tả', validator: requiredText, wide: true),
              SizedBox(
                width: 330,
                child: DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: [
                    for (final entry in categoryLabels.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    if (!categoryLabels.containsKey(category))
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) => category = value!,
                ),
              ),
              _field(calories, 'Năng lượng (kcal)', validator: positiveNumber),
              _field(protein, 'Protein (g)', validator: positiveNumber),
              _field(
                ingredients,
                'Nguyên liệu, mỗi nguyên liệu một dòng',
                validator: requiredText,
                wide: true,
                lines: 4,
              ),
              _field(
                instructions,
                'Các bước, mỗi bước một dòng',
                validator: requiredText,
                wide: true,
                lines: 4,
              ),
              _field(source, 'Nguồn dữ liệu', wide: true),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            editableRecipe(
              id: widget.recipe?.id ?? '',
              name: name.text,
              description: description.text,
              category: category,
              calories: double.parse(calories.text),
              protein: double.parse(protein.text),
              ingredients: ingredients.text,
              instructions: instructions.text,
              sourceNote: source.text,
              isArchived: widget.recipe?.isArchived ?? false,
              imageUrl: widget.recipe?.imageUrl,
              existingIngredients: widget.recipe?.ingredients ?? const [],
            ),
          );
        },
        child: const Text('Lưu'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    bool wide = false,
    int lines = 1,
  }) => SizedBox(
    width: wide ? 680 : 330,
    child: TextFormField(
      controller: controller,
      validator: validator,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
