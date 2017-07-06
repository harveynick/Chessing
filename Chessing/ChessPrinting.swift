extension Position : CustomStringConvertible {
    public var description: String {
        let columnNames = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters
        let index = columnNames.index(columnNames.startIndex,
                                      offsetBy: Int(column))
        return "\(columnNames[index])\(row + 1)"
    }
}

extension Move : CustomStringConvertible {
    public var description: String {
        var output = "\(self.moved) -> \(self.finalPosition)"
        if let capturedPiece = self.captured {
            output += "(\(capturedPiece))"
        }
        return output
    }
}

extension Piece : CustomStringConvertible {
    public var description: String {
        return self.designation
    }
}

extension GameState : CustomStringConvertible {
    public var description: String {
        var breakLine = "+"
        for _ in 0 ..< self.boardSize {
            breakLine += "---+"
        }
        breakLine += "\n"

        var output = breakLine
        for row in 0 ..< self.boardSize {
            output += "|"
            for column in 0 ..< self.boardSize {
                let thisPosition = Position(row: row, column: column)
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
        return output
    }
}

extension Outcome : CustomStringConvertible {
    public var description: String {
        var output = performedMoves
            .map { move in move.description + "\n" }
            .reduce("") { initial, next in initial + next }
        output += "\n" + finalState.description
        return output
    }
}

extension MoveMatrix : CustomStringConvertible {
    public var description: String {
        let movesString = availableMoves
            .map { (arg) in
                let (piece, availableMoves) = arg
                let movesForPiece = availableMoves
                    .map { move in "\t\t\(move)\n" }
                    .joined()
                return "\t\(piece)\n\(movesForPiece)"
            }
            .reduce("") { initial, next in initial + next }
        return "Moves:\n\(movesString)"
    }
}

extension Game : CustomStringConvertible {
    public var description: String {
        return self.outcomes
            .map { outcome in outcome.description + "\n" }
            .reduce("") { initial, next in initial + next }
    }
}
