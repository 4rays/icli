import Foundation

struct ParsedArgs {
  let tokens: [String]

  init(_ tokens: [String]) {
    self.tokens = tokens
  }

  // True if any of the flag names appears in tokens.
  func hasFlag(_ names: String...) -> Bool {
    names.contains { tokens.contains($0) }
  }

  // Returns the value for --name value or --name=value, nil if absent.
  func option(_ names: String...) -> String? {
    for name in names {
      if let idx = tokens.firstIndex(of: name), idx + 1 < tokens.count {
        let next = tokens[idx + 1]
        if !next.hasPrefix("-") { return next }
      }
      let prefix = name + "="
      if let t = tokens.first(where: { $0.hasPrefix(prefix) }) {
        return String(t.dropFirst(prefix.count))
      }
    }
    return nil
  }

  // Positional arguments: non-flag tokens, with flag values skipped.
  // Heuristic: if a flag is followed by a non-flag token, that token is its value.
  var positionals: [String] {
    var result: [String] = []
    var i = 0
    while i < tokens.count {
      let token = tokens[i]
      if token.hasPrefix("-") {
        if i + 1 < tokens.count && !tokens[i + 1].hasPrefix("-") {
          i += 2
        } else {
          i += 1
        }
      } else {
        result.append(token)
        i += 1
      }
    }
    return result
  }
}
