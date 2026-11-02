import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';
import 'package:raigon_art/features/frame_sizes/models/frame_size_model.dart';
import 'package:raigon_art/features/frame_sizes/providers/frame_size_provider.dart';

const kUnits = ['Inches', 'Centimetres', 'Feet'];

const kOrientations = [
  'Landscape (Horizontal)',
  'Portrait (Vertical)',
  'Square',
];

class FrameSpecData {
  FrameSpecData()
    : width = TextEditingController(),
      height = TextEditingController(),
      qty = TextEditingController(text: '1'),
      notes = TextEditingController(),
      customerNote = TextEditingController();

  String size = '';
  String unit = 'Inches';

  // Retained for compatibility with existing FrameSpec data.
  String type = 'Wooden Frame';
  String material = 'Teak Wood Moulding';
  String finish = 'Walnut Brown';

  String orientation = 'Landscape (Horizontal)';

  String? existingPhotoUrl;
  String? existingPhotoName;

  final TextEditingController width;
  final TextEditingController height;
  final TextEditingController qty;
  final TextEditingController notes;
  final TextEditingController customerNote;

  FrameSpec toSpec([PickedPhoto? photo]) => FrameSpec(
    size: size,
    unit: unit,

    customWidth: width.text.trim(),
    customHeight: height.text.trim(),

    frameType: type,
    material: material,
    finish: finish,
    orientation: orientation,
    qty: math.max(1, int.tryParse(qty.text) ?? 1),
    notes: notes.text.trim(),
    customerNote: customerNote.text.trim(),
    photoName: photo?.name ?? existingPhotoName,
    photoBytes: photo?.bytes,
    photoUrl: photo?.url ?? (photo != null ? null : existingPhotoUrl),
  );

  void dispose() {
    width.dispose();
    height.dispose();
    qty.dispose();
    notes.dispose();
    customerNote.dispose();
  }

  void loadSpec(FrameSpec s) {
    size = s.size;

    final parsed = FrameUnit.fromString(s.unit);
    unit = parsed.label;

    type = s.frameType;
    material = s.material;
    finish = s.finish;

    orientation = s.orientation;

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
  });

  final FrameSpecData data;
  final VoidCallback onChanged;

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

    final provider = context.watch<FrameSizeProvider>();
    final savedSizes = provider.sizes;

    final activeSizes = savedSizes.where((size) => size.active).toList();
    final availableSizes = List<FrameSize>.of(activeSizes);

    final selectedExists = availableSizes.any((size) => size.name == data.size);

    if (!selectedExists && data.size.trim().isNotEmpty) {
      final oldSize = savedSizes.where((size) => size.name == data.size);

      if (oldSize.isNotEmpty) {
        availableSizes.add(oldSize.first);
      }
    }

    // final sizeNames = availableSizes.map((frame) => frame.name).toList();

    // final selectedSize = sizeNames.contains(data.size) ? data.size : null;

    final currentUnitObj = FrameUnit.fromString(data.unit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Frame Size and Measurement Unit
        FormRow(
          children: [
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
            LabeledField(
              label: 'Quantity',
              child: NumberBox(controller: data.qty, min: 1),
            ),
          ],
        ),

        gap,

        // Width and Height
        FormRow(
          children: [
            LabeledField(
              label: 'Width (${currentUnitObj.symbol})',
              child: NumberBox(
                controller: data.width,
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

        // Width and Height
        FormRow(
          children: [
            // Special Instructions
            LabeledField(
              label: 'Special Instructions / Mounting Notes',
              child: AppTextBox(
                controller: data.notes,
                maxLines: 3,
                hint: 'Glass type (Anti-glare, Clear), Matting board margin, mounting hooks...',
              ),
            ),
            // Customer Note
            LabeledField(
              label: 'Customer Note',
              child: AppTextBox(
                controller: data.customerNote,
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
