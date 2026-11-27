import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';

const kUnits = ['Inches', 'Centimetres', 'Feet'];

const kOrientations = [
  'Landscape (Horizontal)',
  'Portrait (Vertical)',
  'Square',
];

class FrameSpecData {
  FrameSpecData()
    : price = TextEditingController(),
      width = TextEditingController(),
      height = TextEditingController(),
      qty = TextEditingController(text: '1'),
      notes = TextEditingController(),
      customerNote = TextEditingController(),
      priceFocus = FocusNode(debugLabel: 'frame_price'),
      qtyFocus = FocusNode(debugLabel: 'frame_qty'),
      widthFocus = FocusNode(debugLabel: 'frame_width'),
      heightFocus = FocusNode(debugLabel: 'frame_height'),
      notesFocus = FocusNode(debugLabel: 'frame_notes'),
      customerNoteFocus = FocusNode(debugLabel: 'frame_customerNote');

  String size = '';
  String unit = 'Inches';

  // Retained for compatibility with existing FrameSpec data.
  String type = 'Wooden Frame';
  String material = 'Teak Wood Moulding';
  String finish = 'Walnut Brown';

  String orientation = 'Landscape (Horizontal)';

  String? existingPhotoUrl;
  String? existingPhotoName;

  final TextEditingController price;
  final TextEditingController width;
  final TextEditingController height;
  final TextEditingController qty;
  final TextEditingController notes;
  final TextEditingController customerNote;

  final FocusNode priceFocus;
  final FocusNode qtyFocus;
  final FocusNode widthFocus;
  final FocusNode heightFocus;
  final FocusNode notesFocus;
  final FocusNode customerNoteFocus;

  double get unitPriceValue {
    final t = price.text.replaceAll(',', '').trim();
    return double.tryParse(t) ?? 0.0;
  }

  int get qtyValue {
    return math.max(1, int.tryParse(qty.text.trim()) ?? 1);
  }

  double get subtotalValue => (unitPriceValue > 0 ? unitPriceValue : 0.0) * qtyValue;

  FrameSpec toSpec([PickedPhoto? photo]) => FrameSpec(
    size: size,
    unit: unit,

    customWidth: width.text.trim(),
    customHeight: height.text.trim(),

    frameType: type,
    material: material,
    finish: finish,
    orientation: orientation,
    qty: qtyValue,
    unitPrice: unitPriceValue,
    notes: notes.text.trim(),
    customerNote: customerNote.text.trim(),
    photoName: photo?.name ?? existingPhotoName,
    photoBytes: photo?.bytes,
    photoUrl: photo?.url ?? (photo != null ? null : existingPhotoUrl),
  );

  void dispose() {
    price.dispose();
    width.dispose();
    height.dispose();
    qty.dispose();
    notes.dispose();
    customerNote.dispose();

    priceFocus.dispose();
    qtyFocus.dispose();
    widthFocus.dispose();
    heightFocus.dispose();
    notesFocus.dispose();
    customerNoteFocus.dispose();
  }

  void loadSpec(FrameSpec s) {
    size = s.size;

    final parsed = FrameUnit.fromString(s.unit);
    unit = parsed.label;

    type = s.frameType;
    material = s.material;
    finish = s.finish;

    orientation = s.orientation;

    price.text = s.unitPrice > 0
        ? (s.unitPrice == s.unitPrice.roundToDouble()
            ? '${s.unitPrice.toInt()}'
            : '${s.unitPrice}')
        : '';
    width.text = s.customWidth;
    height.text = s.customHeight;
    qty.text = '${s.qty}';

    notes.text = s.notes;
    customerNote.text = s.customerNote;

    existingPhotoUrl = s.photoUrl;
    existingPhotoName = s.photoName;
  }
}

class FrameSpecFields extends StatelessWidget {
  const FrameSpecFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.onNextFromCustomerNote,
  });

  final FrameSpecData data;
  final VoidCallback onChanged;
  final VoidCallback? onNextFromCustomerNote;

  void _onUnitChanged(String newUnit) {
    final from = FrameUnit.fromString(data.unit);
    final to = FrameUnit.fromString(newUnit);

    if (from != to) {
      if (data.width.text.trim().isNotEmpty) {
        data.width.text = FrameMeasurementHelper.convertString(
          valueStr: data.width.text,
          from: from,
          to: to,
        );
      }

      if (data.height.text.trim().isNotEmpty) {
        data.height.text = FrameMeasurementHelper.convertString(
          valueStr: data.height.text,
          from: from,
          to: to,
        );
      }
    }

    data.unit = newUnit;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 18);
    final p = FormColors.of(context).p;
    final currentUnitObj = FrameUnit.fromString(data.unit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Price FIRST, followed by Quantity, Subtotal, and Measurement Unit
        FormRow(
          children: [
            LabeledField(
              label: 'Price per Frame (₹)',
              child: NumberBox(
                controller: data.price,
                focusNode: data.priceFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => data.qtyFocus.requestFocus(),
                hint: 'e.g. 150',
                allowDecimal: true,
                onChanged: (_) => onChanged(),
              ),
            ),
            LabeledField(
              label: 'Quantity',
              child: NumberBox(
                controller: data.qty,
                focusNode: data.qtyFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => data.widthFocus.requestFocus(),
                min: 1,
                onChanged: (_) => onChanged(),
              ),
            ),
            LabeledField(
              label: 'Item Subtotal',
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: p.isDark
                      ? const Color(0xFF232538)
                      : const Color(0xFFF6F3EC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${data.subtotalValue.toStringAsFixed(data.subtotalValue == data.subtotalValue.roundToDouble() ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (data.unitPriceValue > 0)
                      Text(
                        '₹${data.unitPriceValue.toStringAsFixed(0)} × ${data.qtyValue}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: p.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            LabeledField(
              label: 'Measurement Unit',
              child: FormDropdown<String>(
                value: kUnits.contains(data.unit)
                    ? data.unit
                    : currentUnitObj.label,
                items: kUnits,
                labelOf: (unit) {
                  final u = FrameUnit.fromString(unit);
                  return '${u.label} (${u.symbol})';
                },
                onChanged: _onUnitChanged,
              ),
            ),
          ],
        ),

        gap,

        // 2. Measurements (Width & Height) below Quantity
        FormRow(
          children: [
            LabeledField(
              label: 'Width (${currentUnitObj.symbol})',
              child: NumberBox(
                controller: data.width,
                focusNode: data.widthFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => data.heightFocus.requestFocus(),
                hint:
                    'Width in ${currentUnitObj.symbol} (e.g. ${currentUnitObj == FrameUnit.feet ? '2' : (currentUnitObj == FrameUnit.centimetres ? '60' : '24')})',
                allowDecimal: true,
                dim: true,
                onChanged: (_) => onChanged(),
              ),
            ),
            LabeledField(
              label: 'Height (${currentUnitObj.symbol})',
              child: NumberBox(
                controller: data.height,
                focusNode: data.heightFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => data.notesFocus.requestFocus(),
                hint:
                    'Height in ${currentUnitObj.symbol} (e.g. ${currentUnitObj == FrameUnit.feet ? '3' : (currentUnitObj == FrameUnit.centimetres ? '90' : '36')})',
                allowDecimal: true,
                dim: true,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),

        gap,

        // 3. Special Instructions & Customer Note
        FormRow(
          children: [
            LabeledField(
              label: 'Special Instructions / Mounting Notes',
              child: AppTextBox(
                controller: data.notes,
                focusNode: data.notesFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => data.customerNoteFocus.requestFocus(),
                maxLines: 3,
                hint:
                    'Glass type (Anti-glare, Clear), Matting board margin, mounting hooks...',
              ),
            ),
            LabeledField(
              label: 'Customer Note',
              child: AppTextBox(
                controller: data.customerNote,
                focusNode: data.customerNoteFocus,
                textInputAction: onNextFromCustomerNote != null
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: (_) {
                  onNextFromCustomerNote?.call();
                },
                maxLines: 3,
                hint: 'Enter additional notes from the customer...',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
