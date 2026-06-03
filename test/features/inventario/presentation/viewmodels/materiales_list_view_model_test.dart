// Tests del método eliminar de MaterialesListViewModel (A6). Mismo patrón que
// ubicaciones_list_view_model_test: ProviderContainer con los providers de use
// case overrideados sobre un repo mock (mocktail). Verifica:
//  - eliminar con éxito devuelve null y refresca (vuelve a listar),
//  - eliminar con Fail(RecursoEnUso) devuelve ese Failure sin romper el estado.

import 'package:custodiam/features/inventario/domain/entities/material_summary.dart';
import 'package:custodiam/features/inventario/domain/entities/materiales_page.dart';
import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_material.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/eliminar_material.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_materiales.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/materiales_list_view_model.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements InventarioRepository {}

MaterialSummary _m(String id) => MaterialSummary(
      id: id,
      nombre: 'Casco $id',
      tipo: TipoMaterial.personal,
      estado: EstadoInventario.operativo,
      cantidad: 1,
    );

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      listMaterialesProvider.overrideWithValue(ListMateriales(repo)),
      eliminarMaterialProvider.overrideWithValue(EliminarMaterial(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle(ProviderContainer container) async {
  await container
      .read(materialesListViewModelProvider.future)
      .catchError((_) => const MaterialesListState());
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  setUpAll(() {
    registerFallbackValue(EstadoInventario.operativo);
    registerFallbackValue(TipoMaterial.personal);
  });

  void stubList(MaterialesPage page) {
    when(() => repo.listMaterial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
          categoria: any(named: 'categoria'),
        )).thenAnswer((_) async => Success(page));
  }

  test('eliminar con éxito devuelve null y refresca (vuelve a listar)',
      () async {
    stubList(MaterialesPage(items: [_m('a')], total: 1));
    when(() => repo.deleteMaterial('a'))
        .thenAnswer((_) async => const Success<void>(null));
    final container = _container(repo);
    await _settle(container);

    final failure = await container
        .read(materialesListViewModelProvider.notifier)
        .eliminar('a');

    expect(failure, isNull);
    verify(() => repo.deleteMaterial('a')).called(1);
    // build (1) + refresh tras el borrado (1) = listMaterial llamado dos veces.
    verify(() => repo.listMaterial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
          categoria: any(named: 'categoria'),
        )).called(2);
  });

  test('eliminar con Fail(RecursoEnUso) devuelve ese Failure y no rompe el '
      'estado de datos', () async {
    stubList(MaterialesPage(items: [_m('a')], total: 1));
    when(() => repo.deleteMaterial('a')).thenAnswer(
      (_) async => const Fail(InventarioFailure.enUso()),
    );
    final container = _container(repo);
    await _settle(container);

    final failure = await container
        .read(materialesListViewModelProvider.notifier)
        .eliminar('a');

    expect(failure, isA<RecursoEnUso>());
    final state = container.read(materialesListViewModelProvider);
    expect(state, isA<AsyncData<MaterialesListState>>());
    expect(state.value!.items, hasLength(1));
    verify(() => repo.deleteMaterial('a')).called(1);
    // El fallo de borrado no refresca: listMaterial solo se llamó en build.
    verify(() => repo.listMaterial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
          categoria: any(named: 'categoria'),
        )).called(1);
  });
}
