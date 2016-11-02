extension Position : CustomStringConvertible {
  public var description : String {
    get {
      let columnNames = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters
      let index = columnNames.index(columnNames.startIndex,
                                    offsetBy: Int(column))
      return "\(board)\(columnNames[index])\(row + 1)"
    }
  }
}

extension Move : CustomStringConvertible {
  public var description : String {
    get {
      var output = "\(self.movedPiece) -> \(self.finalPosition)"
      if let capturedPiece = self.capturedPiece {
        output += "(\(capturedPiece))"
      }
      return output;
    }
  }
}

extension Piece : CustomStringConvertible {
  public var description : String {
    get {
      return self.designation
    }
  }
}

extension GameState : CustomStringConvertible {
  public var description : String {
    get {
      var breakLine = "+"
      for _ in 0 ..< self.rules.boardWidth {
        breakLine += "---+"
      }
      breakLine += "\n"
      
      var output = breakLine;
      for board in 0 ..< self.rules.boards {
        for row in 0 ..< self.rules.boardHeight {
          output += "|"
          for column in 0 ..< self.rules.boardWidth {
            let thisPosition = self.rules.boards > 1
              ? Position(board:board, row: row, column: column)
              : Position(row: row, column: column)
            if let piece = self.positionToPiece[thisPosition] {
              output += "\(piece)\(piece.type) "
            } else {
              output += "   "
            }
            output += "|"
          }
          output += "\n"
          output += breakLine
        }
      }
      return output;
    }
  }
}

extension Outcome : CustomStringConvertible {
  public var description : String {
    get {
      var output = performedMoves
        .map { _, move in move.description + "\n" }
        .reduce("") { initial, next in initial + next }
      output += "\n" + finalState.description
      return output
    }
  }
}

extension MoveMatrix : CustomStringConvertible {
  public var description : String {
    let movesString = availableMoves
      .map { piece, availableMoves in
        let movesForPiece = availableMoves
          .map { move in "\t\t\(move)" }
          .reduce("") { initial, next in initial + next }
        return "\t\(piece)\n\(movesForPiece)"
      }
      .reduce("") { initial, next in initial + next }
//        let threatenedString = threatenedPositions
//            .map { position, threatenedBy in
//                let threateningPieces = threatenedBy
//                    .map { piece in "\t\t\(piece)" }
//                    .reduce("") { initial, next in initial + next }
//                return "\t\(position)\n\(threateningPieces)"
//            }
//            .reduce("") { initial, next in initial + next }
    return "Moves:\n\(movesString)"
  }
}

extension Game : CustomStringConvertible {
  public var description : String {
    get {
      return self.outcomes
        .map { outcome in outcome.description + "\n" }
        .reduce("") { initial, next in initial + next }
    }
  }
}
