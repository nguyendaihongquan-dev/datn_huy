class HistoryItem {
  final String key;
  final String timestamp;
  final String timeuse;
  final String plugNumber;
  final String energy;
  final String power;
  final String price;

  HistoryItem({
    required this.key,
    required this.timestamp,
    required this.timeuse,
    required this.plugNumber,
    required this.energy,
    required this.power,
    required this.price,
  });

  factory HistoryItem.fromMap(Map<String, dynamic> map, String key) {
    return HistoryItem(
      key: key,
      timestamp: map['timestamp']?.toString() ?? '',
      timeuse: map['timeuse']?.toString() ?? '',
      plugNumber: map['plugNumber']?.toString() ?? '',
      energy: map['energy']?.toString() ?? '0',
      power: map['power']?.toString() ?? '0',
      price: map['price']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'timestamp': timestamp,
      'timeuse': timeuse,
      'plugNumber': plugNumber,
      'energy': energy,
      'power': power,
      'price': price,
    };
  }

  // Getters để tương thích với Android
  String getKey() => key;
  String getTimestamp() => timestamp;
  String getTimeuse() => timeuse;
  String getPlugNumber() => plugNumber;
  String getEnergy() => energy;
  String getPower() => power;
  String getPrice() => price;

  @override
  String toString() {
    return 'HistoryItem(key: $key, timestamp: $timestamp, timeuse: $timeuse, plugNumber: $plugNumber, energy: $energy, power: $power, price: $price)';
  }
}
