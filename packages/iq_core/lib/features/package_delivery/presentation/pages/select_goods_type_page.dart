import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_primary_button.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../../core/widgets/iq_text_field.dart';
import '../../data/models/goods_type_model.dart';
import '../bloc/package_delivery_bloc.dart';
import '../bloc/package_delivery_event.dart';
import '../bloc/package_delivery_state.dart';

/// Screen 5 — Select goods type + optional quantity.
///
/// Displays a 2-column grid of goods sub-types (split from compound
/// API names by "/") inside a rounded card, plus a quantity card with
/// horizontal radio options.
///
/// Matches Figma node 7:4556.
class SelectGoodsTypePage extends StatefulWidget {
  const SelectGoodsTypePage({
    super.key,
    required this.onConfirmed,
  });

  /// Called after user confirms goods type selection.
  final VoidCallback onConfirmed;

  @override
  State<SelectGoodsTypePage> createState() => _SelectGoodsTypePageState();
}

class _SelectGoodsTypePageState extends State<SelectGoodsTypePage> {
  int? _selectedGoodsId;
  String _selectedGoodsName = '';
  bool _specifyQuantity = false;
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<PackageDeliveryBloc>().state;

    // Pre-select if already chosen before.
    if (state.parcelRequest.goodsTypeId != null) {
      _selectedGoodsId = state.parcelRequest.goodsTypeId;
      _selectedGoodsName = state.parcelRequest.goodsTypeName;
    }
    if (state.parcelRequest.goodsQuantity != null) {
      _specifyQuantity = true;
      _quantityController.text = state.parcelRequest.goodsQuantity!;
    }

    // Trigger goods type fetch if needed.
    if (state.goodsTypes.isEmpty) {
      context
          .read<PackageDeliveryBloc>()
          .add(const PackageDeliveryGoodsTypesRequested());
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // ─── helpers ─────────────────────────────────────────────────────

  /// Flatten compound API names ("A/B/C") into individual sub-items.
  List<_GoodsSubItem> _flattenTypes(List<GoodsTypeModel> types) {
    final items = <_GoodsSubItem>[];
    for (final type in types) {
      final parts = type.name.split('/');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          items.add(_GoodsSubItem(parentId: type.id, name: trimmed));
        }
      }
    }
    return items;
  }

  /// Unique key for radio selection (parentId + subName).
  String _radioKey(int id, String name) => '${id}_$name';

  // ─── build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IqAppBar(title: AppStrings.selectGoodsType),
      body: BlocBuilder<PackageDeliveryBloc, PackageDeliveryState>(
        builder: (context, state) {
          final goodsTypes = state.goodsTypes;

          if (goodsTypes.isEmpty &&
              state.status != PackageDeliveryStatus.error) {
            return const Center(child: CircularProgressIndicator());
          }

          final subItems = _flattenTypes(goodsTypes);

          return Column(
            children: [
              // ── Scrollable content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    children: [
                      // ── Goods-type grid card ──
                      _buildGoodsCard(subItems),
                      SizedBox(height: 16.h),

                      // ── Quantity card ──
                      _buildQuantityCard(),
                    ],
                  ),
                ),
              ),

              // ── Confirm button ──
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
                  child: IqPrimaryButton(
                    text: AppStrings.confirm,
                    onPressed: _selectedGoodsId == null ? null : _onConfirm,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Goods-type 2-column grid card
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildGoodsCard(List<_GoodsSubItem> items) {
    final selectedKey = _radioKey(
      _selectedGoodsId ?? -1,
      _selectedGoodsName,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RadioGroup<String>(
        groupValue: selectedKey,
        onChanged: (val) {
          // Find the matching item.
          for (final item in items) {
            if (_radioKey(item.parentId, item.name) == val) {
              setState(() {
                _selectedGoodsId = item.parentId;
                _selectedGoodsName = item.name;
              });
              break;
            }
          }
        },
        child: Wrap(
          spacing: 0,
          runSpacing: 4.h,
          children: items.map((item) {
            final key = _radioKey(item.parentId, item.name);
            final isSelected = key == selectedKey;
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 56.w) / 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(8.r),
                onTap: () => setState(() {
                  _selectedGoodsId = item.parentId;
                  _selectedGoodsName = item.name;
                }),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32.w,
                      height: 32.h,
                      child: Radio<String>(
                        value: key,
                        activeColor: AppColors.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: IqText(
                      item.name,
                      style: isSelected
                          ? AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            )
                          : AppTypography.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Quantity card
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildQuantityCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IqText(
            AppStrings.quantity,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),

          // ── Horizontal radio row ──
          RadioGroup<bool>(
            groupValue: _specifyQuantity,
            onChanged: (v) => setState(() {
              _specifyQuantity = v ?? false;
              if (!_specifyQuantity) _quantityController.clear();
            }),
            child: Row(
              children: [
                // Specify quantity
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: () => setState(() => _specifyQuantity = true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32.w,
                          height: 32.h,
                          child: Radio<bool>(
                            value: true,
                            activeColor: AppColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: IqText(
                            AppStrings.specifyQuantity,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // No quantity
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: () => setState(() {
                      _specifyQuantity = false;
                      _quantityController.clear();
                    }),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32.w,
                          height: 32.h,
                          child: Radio<bool>(
                            value: false,
                            activeColor: AppColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: IqText(
                            AppStrings.noQuantity,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Quantity text field (shown when "specify" is selected) ──
          if (_specifyQuantity) ...[
            SizedBox(height: 12.h),
            IqTextField(
              hintText: AppStrings.enterQuantity,
              controller: _quantityController,
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Confirm
  // ═══════════════════════════════════════════════════════════════════

  void _onConfirm() {
    if (_selectedGoodsId == null) return;

    final quantity = _specifyQuantity && _quantityController.text.isNotEmpty
        ? _quantityController.text.trim()
        : null;

    context.read<PackageDeliveryBloc>().add(
          PackageDeliveryGoodsTypeSelected(
            goodsTypeId: _selectedGoodsId!,
            goodsTypeName: _selectedGoodsName,
            quantity: quantity,
          ),
        );

    widget.onConfirmed();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Sub-item model (flattened from compound API names)
// ═══════════════════════════════════════════════════════════════════

class _GoodsSubItem {
  const _GoodsSubItem({required this.parentId, required this.name});
  final int parentId;
  final String name;
}
