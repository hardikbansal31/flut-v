

void main() {
  final extPattern = RegExp(r'\.(mkv|mp4|avi|mov|wmv|flv|webm|m4v|ts)$', caseSensitive: false);
  
  var working = "[SubsPlease] Tengoku Daimakyou - 13 (1080p) [2B9B9B8A].mkv";
  working = working.replaceAll(extPattern, '');
  
  // Brackets
  final groupBracketPattern = RegExp(r'[\[\(\{][^\]\)\}]*[\]\)\}]');
  working = working.replaceAll(groupBracketPattern, ' ');
  
  // Replace dots, underscores, hyphens
  working = working.replaceAll(RegExp(r'[._]'), ' ');
  working = working.replaceAll(RegExp(r'\s*-\s*'), ' ');
  
  // Look for absolute episode
  final absMatch = RegExp(r'\s+(\d{1,4})\s*$').firstMatch(working);
  
  print("Working string: '$working'");
  print("Match: ${absMatch?.group(1)}");
}
