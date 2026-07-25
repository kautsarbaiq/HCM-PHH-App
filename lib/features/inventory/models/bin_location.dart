/// A storage bin / location tag in the warehouse (scanned during Placement).
class BinLocation {
  final String code; // the barcode printed on the location tag
  final String zone;
  final String rack;
  final String shelf;

  BinLocation({
    required this.code,
    required this.zone,
    required this.rack,
    required this.shelf,
  });

  /// Human label, e.g. "Rack 1 - Shelf 1".
  String get label => 'Rack $rack - Shelf $shelf';
  String get fullLabel => 'Zone $zone • Rack $rack • Shelf $shelf';

  factory BinLocation.fromJson(Map<String, dynamic> json) => BinLocation(
        code: json['code'] as String,
        zone: json['zone'] as String,
        rack: json['rack'] as String,
        shelf: json['shelf'] as String,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'zone': zone,
        'rack': rack,
        'shelf': shelf,
      };
}
