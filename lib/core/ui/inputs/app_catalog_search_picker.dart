// Molécula de selección sobre un catálogo (guía 27 §5.19): lista paginada
// con filtro de texto en la cabecera, selección única y un footer "crear"
// opcional gateado por permiso (AppPermissionGate). Genérica sobre el tipo
// de elemento T.
//
// El contrato de diseño la describía como StatelessWidget, pero el filtro en
// vivo (debounce) y la paginación por scroll exigen estado interno, así que
// se materializa como StatefulWidget. La API pública —incluido `show<T>`—
// se mantiene fiel al contrato.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/test_keys.dart';
import '../../../infrastructure/auth/permissions.dart';
import '../auth/app_permission_gate.dart';
import '../buttons/app_text_button.dart';
import '../feedback/app_loading_indicator.dart';
import '../states/app_empty_state.dart';
import '../tokens/app_spacing.dart';
import 'app_text_field.dart';

class AppCatalogSearchPicker<T> extends StatefulWidget {
  final String title;
  final String searchHint;

  /// Carga paginada del catálogo filtrado por [query]. Una página vacía marca
  /// el fin de la paginación.
  final Future<List<T>> Function(String query, int page) onLoadPage;

  final String Function(T item) labelOf;
  final ValueChanged<T> onSelected;

  /// Permiso requerido para mostrar el footer "crear". Si es `null`, no se
  /// muestra footer. Si se indica, el footer se envuelve en [AppPermissionGate].
  final Permission? createPermission;
  final String? createLabel;
  final VoidCallback? onCreate;

  const AppCatalogSearchPicker({
    super.key,
    required this.title,
    this.searchHint = 'Buscar…',
    required this.onLoadPage,
    required this.labelOf,
    required this.onSelected,
    this.createPermission,
    this.createLabel,
    this.onCreate,
  });

  /// Abre el picker como hoja modal a pantalla casi completa y devuelve el
  /// elemento elegido (o `null` si se cierra sin seleccionar). El [onCreate]
  /// recibido se invoca tras cerrar la hoja para que el llamador navegue al
  /// alta sin que el picker conozca el router.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String searchHint = 'Buscar…',
    required Future<List<T>> Function(String query, int page) onLoadPage,
    required String Function(T item) labelOf,
    Permission? createPermission,
    String? createLabel,
    VoidCallback? onCreate,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Altura acotada explícita en lugar de FractionallySizedBox: bajo
      // showModalBottomSheet(isScrollControlled: true) el builder recibe
      // restricciones verticales laxas (la hoja se dimensiona al contenido),
      // por lo que FractionallySizedBox no resolvía 0.85*alto y el
      // Column→Expanded→ListView del cuerpo quedaba sin altura útil: la lista
      // se poblaba pero no era interactiva ni desplazable. Con una caja de
      // altura tight el Expanded recibe restricciones acotadas y la lista
      // vuelve a responder.
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.85,
        child: AppCatalogSearchPicker<T>(
          title: title,
          searchHint: searchHint,
          onLoadPage: onLoadPage,
          labelOf: labelOf,
          onSelected: (item) => Navigator.of(sheetContext).pop(item),
          createPermission: createPermission,
          createLabel: createLabel,
          onCreate: onCreate == null
              ? null
              : () {
                  Navigator.of(sheetContext).pop();
                  onCreate();
                },
        ),
      ),
    );
  }

  @override
  State<AppCatalogSearchPicker<T>> createState() =>
      _AppCatalogSearchPickerState<T>();
}

class _AppCatalogSearchPickerState<T> extends State<AppCatalogSearchPicker<T>> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  final List<T> _items = [];
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _error = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
    _scrollCtrl.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _searchCtrl.text.trim();
      if (q == _query) return;
      _query = q;
      _loadFirstPage();
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 && !_loading && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = false;
      _loading = true;
    });
    await _fetch(0);
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    await _fetch(_page + 1);
  }

  Future<void> _fetch(int page) async {
    try {
      final result = await widget.onLoadPage(_query, page);
      if (!mounted) return;
      setState(() {
        _items.addAll(result);
        _page = page;
        _hasMore = result.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  bool get _showCreateFooter =>
      widget.createPermission != null &&
      widget.createLabel != null &&
      widget.onCreate != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(widget.title, style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  key: K.catalogSearchField,
                  label: widget.searchHint,
                  controller: _searchCtrl,
                  prefixIcon: Symbols.search,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(theme)),
          if (_showCreateFooter)
            AppPermissionGate(
              permission: widget.createPermission!,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AppTextButton(
                  key: K.catalogCreateBtn,
                  label: widget.createLabel!,
                  icon: Symbols.add,
                  onPressed: widget.onCreate,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error) {
      return AppEmptyState(
        icon: Symbols.error,
        title: 'No se pudo cargar el catálogo.',
        actionLabel: 'Reintentar',
        onAction: _loadFirstPage,
      );
    }
    if (_loading && _items.isEmpty) {
      return const AppLoadingIndicator.fullScreen();
    }
    if (_items.isEmpty) {
      return const AppEmptyState(
        icon: Symbols.search_off,
        title: 'Sin resultados.',
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      itemCount: _items.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppLoadingIndicator(),
          );
        }
        final item = _items[index];
        final label = widget.labelOf(item);
        return Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: () => widget.onSelected(item),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label, style: theme.textTheme.bodyLarge),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
