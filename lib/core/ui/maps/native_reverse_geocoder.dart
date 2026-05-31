// Punto de entrada con conditional import para el reverse-geocoder
// nativo. En móvil (dart.library.io) carga la implementación que usa el
// paquete `geocoding`; en cualquier otro target carga el stub, de modo
// que el plugin nativo nunca llega al build web.

export 'native_reverse_geocoder_stub.dart'
    if (dart.library.io) 'native_reverse_geocoder_io.dart';
