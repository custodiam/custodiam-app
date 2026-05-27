// AsyncNotifier para US-05-01.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/material_create.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/usecases/create_material.dart';
import 'inventario_di.dart';

class AltaMaterialViewModel extends AsyncNotifier<MaterialItem?> {
  CreateMaterial get _create => ref.read(createMaterialProvider);

  @override
  Future<MaterialItem?> build() async => null;

  Future<void> submit(MaterialCreate data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _create(data);
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }
}

final altaMaterialViewModelProvider =
    AsyncNotifierProvider<AltaMaterialViewModel, MaterialItem?>(
  AltaMaterialViewModel.new,
);
