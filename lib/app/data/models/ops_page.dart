class OpsPage<T> {
  const OpsPage(this.items, {this.hasMore = false});
  final List<T> items;
  final bool hasMore;
}
