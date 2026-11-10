String fechaLegible(String iso) {
  final partes = iso.split('-');
  if (partes.length != 3) return iso;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}

String? fechaAIso(String texto) {
  final coincidencia = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(texto.trim());
  if (coincidencia == null) return null;
  final dia = int.parse(coincidencia[1]!);
  final mes = int.parse(coincidencia[2]!);
  final anio = int.parse(coincidencia[3]!);
  final fecha = DateTime(anio, mes, dia);
  if (fecha.year != anio || fecha.month != mes || fecha.day != dia) return null;
  return '$anio-${mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';
}

bool fechaYaPaso(String iso) {
  final hoy = DateTime.now();
  return DateTime.parse(iso).isBefore(DateTime(hoy.year, hoy.month, hoy.day));
}

String? horaAIso(String texto) {
  final coincidencia = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(texto.trim());
  if (coincidencia == null) return null;
  return '${coincidencia[1]!.padLeft(2, '0')}:${coincidencia[2]}';
}

String resumenEntrega(Map<String, dynamic> propuesta) {
  return '${fechaLegible(propuesta['fecha'] as String)} a las ${propuesta['hora']} en ${propuesta['lugar']}';
}
