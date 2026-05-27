import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/material_summary.dart';
import '../../domain/entities/tipo_material.dart';

class MaterialSummaryModel {
  const MaterialSummaryModel._();

  static MaterialSummary fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String;
    final tipo = TipoMaterial.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo de material: $tipoRaw');
    }
    final estadoRaw = json['estado'] as String;
    final estado = EstadoInventario.fromWire(estadoRaw);
    if (estado == null) {
      throw FormatException('Unknown estado de inventario: $estadoRaw');
    }
    return MaterialSummary(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String?,
      tipo: tipo,
      categoria: json['categoria'] as String?,
      estado: estado,
      cantidad: json['cantidad'] as int,
      ubicacionBase: json['ubicacion_base'] as String,
    );
  }
}
