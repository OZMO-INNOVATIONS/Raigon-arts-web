import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';
import 'package:raigon_art/features/frame_sizes/models/frame_size_model.dart';
import 'package:raigon_art/features/frame_sizes/providers/frame_size_provider.dart';

const kUnits = ['Inch', 'CM', 'MM'];
const kFrameTypes = [
  'Wooden Frame',
  'Premium Frame',
  'Classic Frame',
  'Canvas Float',
  'Box Frame',
];
const kOrientations = [
  'Landscape (Horizontal)',
  'Portrait (Vertical)',
  'Square',
];

class FrameSpecData {
  FrameSpecData()
    : width = TextEditingController(),
      height = TextEditingController(),
      material = TextEditingController(text: 'Teak Wood Moulding'),
      finish = TextEditingController(text: 'Walnut Brown'),
      qty = TextEditingController(text: '1'),
      notes = TextEditingController();

  String size = '';
  String unit = 'Inch';
  String type = 'Wooden Frame';
  String orientation = 'Landscape (Horizontal)';
  final TextEditingController width;
  final TextEditingController height;
  final TextEditingController material;
  final TextEditingController finish;
  final TextEditingController qty;
  final TextEditingController notes;

  FrameSpec toSpec([PickedPhoto? photo]) => FrameSpec(
    size: size,
    unit: unit,
    customWidth: width.text.trim(),
    customHeight: height.text.trim(),
    frameType: type,
    material: material.text.trim(),
    finish: finish.text.trim(),
    orientation: orientation,
    qty: math.max(1, int.tryParse(qty.text) ?? 1),
    notes: notes.text.trim(),
    photoName: photo?.name,
    photoBytes: photo?.bytes,
  );

  void dispose() {
    width.dispose();
    height.dispose();
    material.dispose();
    finish.dispose();
    qty.dispose();
    notes.dispose();
  }

  void loadSpec(FrameSpec s) {
    size = s.size;
    unit = s.unit;
    type = s.frameType;
    orientation = s.orientation;
    width.text = s.customWidth;
    height.text = s.customHeight;
    material.text = s.material;
    finish.text = s.finish;
    qty.text = '${s.qty}';
    notes.text = s.notes;
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

    final sizeNames = availableSizes.map((frame) => frame.name).toList();

    final selectedSize = sizeNames.contains(data.size) ? data.size : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormRow(
          children: [
            LabeledField(
              label: 'Frame Size',
              child: sizeNames.isEmpty
                  ? const InputDecorator(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      child: Text('No frame sizes available'),
                    )
                  : FormDropdown<String>(
                      key: ValueKey(selectedSize),
                      value: selectedSize,
                      hint: 'Select Frame Size',
                      items: sizeNames,
                      labelOf: (name) => name,
                      onChanged: (value) {
                        data.size = value;

                        final selectedFrame = availableSizes.firstWhere(
                          (frame) => frame.name == value,
                        );

                        data.width.text = selectedFrame.width.toString();
                        data.height.text = selectedFrame.height.toString();
                        data.unit = kUnits.contains(selectedFrame.unit)
                            ? selectedFrame.unit
                            : 'Inch';

                        onChanged();
                      },
                    ),
            ),
            LabeledField(
              label: 'Unit',
              child: FormDropdown<String>(
                value: data.unit,
                items: kUnits,
                labelOf: (unit) => unit,
                onChanged: (value) {
                  data.unit = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        gap,
        FormRow(
          children: [
            LabeledField(
              label: 'Custom Width',
              child: NumberBox(
                controller: data.width,
                hint: 'Width (e.g. 12)',
                allowDecimal: true,
                dim: true,
              ),
            ),
            LabeledField(
              label: 'Custom Height',
              child: NumberBox(
                controller: data.height,
                hint: 'Height (e.g. 18)',
                allowDecimal: true,
                dim: true,
              ),
            ),
          ],
        ),
        gap,
        FormRow(
          children: [
            LabeledField(
              label: 'Frame Type',
              child: FormDropdown<String>(
                value: data.type,
                items: kFrameTypes,
                labelOf: (value) => value,
                onChanged: (value) {
                  data.type = value;
                  onChanged();
                },
              ),
            ),
            LabeledField(
              label: 'Frame Material',
              child: AppTextBox(controller: data.material),
            ),
            LabeledField(
              label: 'Frame Color Finish',
              child: AppTextBox(controller: data.finish),
            ),
          ],
        ),
        gap,
        FormRow(
          children: [
            LabeledField(
              label: 'Photo Orientation',
              child: FormDropdown<String>(
                value: data.orientation,
                items: kOrientations,
                labelOf: (value) => value,
                onChanged: (value) {
                  data.orientation = value;
                  onChanged();
                },
              ),
            ),
            LabeledField(
              label: 'Quantity',
              child: NumberBox(controller: data.qty, min: 1),
            ),
          ],
        ),
        gap,
        LabeledField(
          label: 'Special Instructions / Mounting Notes',
          child: AppTextBox(
            controller: data.notes,
            maxLines: 3,
            hint: 'Glass type (Anti-glare, Clear), Matting board margin, mounting hooks...',
          ),
        ),
      ],
    );
  }
}
