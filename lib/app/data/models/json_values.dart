int intValue(dynamic value) => switch (value) {
  int number => number,
  num number => number.round(),
  _ => int.tryParse(value?.toString() ?? '') ?? 0,
};
