/// A detected brand and how many times its name/aliases were read in the photo.
///
/// [count] is a simple occurrence count of matched text, not an exact facing
/// count — the same package can print a brand name more than once.
class BrandResult {
  const BrandResult({required this.brandName, required this.count});

  final String brandName;
  final int count;
}
