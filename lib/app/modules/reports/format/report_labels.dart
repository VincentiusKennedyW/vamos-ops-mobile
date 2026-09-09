String reportCategoryLabel(String value) => switch (value) {
  'DAMAGE' => 'KERUSAKAN',
  'STOCK' => 'STOK / BARANG',
  'OPERATIONAL' => 'OPERASIONAL',
  _ => 'INFO / USULAN',
};
