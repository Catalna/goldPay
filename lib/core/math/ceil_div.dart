/// Integer ceiling division for non-negative [a] and positive [b].
///
/// Money and gold never use `double` (AGENTS.md). This is the only rounding
/// primitive in the app: it always rounds up, so the demo gold value is never
/// smaller than the amount that has to be paid.
int ceilDiv(int a, int b) {
  assert(a >= 0, 'ceilDiv expects a >= 0');
  assert(b > 0, 'ceilDiv expects b > 0');
  return (a + b - 1) ~/ b;
}
