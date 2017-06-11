import Foundation

enum RegularPiece : PieceType {
    case rook = "R"
    case knight = "N"
    case bishop = "B"
    case queen = "Q"
    case king = "K"
    case pawn = "P"
}

let kBoardSize : Int = 8

let fealty : [(RegularPiece, RegularPiece)] = [
    (.queen, .rook),
    (.queen, .knight),
    (.queen, .bishop),
    (.queen, .queen),
    (.king, .king),
    (.king, .bishop),
    (.king, .knight),
    (.king, .rook) ]


let knightMoveChains = [
  [Position(row: 2, column: 1)],
  [Position(row: 1, column: 2)],
  [Position(row: 2, column: -1)],
  [Position(row: 1, column: -2)],
  [Position(row: -2, column: 1)],
  [Position(row: -1, column: 2)],
  [Position(row: -2, column: -1)],
  [Position(row: -1, column: -2)],
]

let boardRange = 0 ..< kBoardSize

let rookMoveChains = [
  boardRange.map { value in Position(row: value, column: 0) },
  boardRange.map { value in Position(row: 0, column: value) },
  boardRange.map { value in Position(row: -value, column: 0) },
  boardRange.map { value in Position(row: 0, column: -value) },
]

let bisopMoveChains = [
  boardRange.map { value in Position(row: value, column: value) },
  boardRange.map { value in Position(row: value, column: -value) },
  boardRange.map { value in Position(row: -value, column: value) },
  boardRange.map { value in Position(row: -value, column: -value) },
]

let queenMoveChains = rookMoveChains + bisopMoveChains

let kingMoveChains = [
  [Position(row: 0, column: 1)],
  [Position(row: 1, column: 0)],
  [Position(row: 0, column: -1)],
  [Position(row: 1, column: -0)],
  [Position(row: -0, column: 1)],
  [Position(row: -1, column: 0)],
  [Position(row: -0, column: -1)],
  [Position(row: -1, column: -0)],
]

enum MoveOperationOutcome {
  case Legal, Capturing(Piece), Illegal
}

func moveOutcome(piece: Piece,
                 endPositoon: Position,
                 gameState: GameState) -> MoveOperationOutcome {
  let maxPosition = kBoardSize - 1
  if endPositoon.row > maxPosition ||
     endPositoon.row < 0 ||
     endPositoon.column > maxPosition ||
     endPositoon.column < 0 {
    return .Illegal
  }
  if let target = gameState.positionToPiece[endPositoon] {
    if (target.player != piece.player) {
      return .Capturing(target)
    } else {
      return .Illegal
    }
  } else {
    return .Legal
  }
}

func movesFromChains(piece: Piece,
                     moveChains: [[Position]],
                     gameState: GameState) -> [Move] {
  guard let startPosition = gameState.pieceToPosition[piece] else {
    return []
  }
  var moves = [Move]()
  for moveChain in moveChains {
    for positionDelta in moveChain {
      let endPosition = startPosition + positionDelta
      let outcome = moveOutcome(piece: piece, endPositoon: endPosition, gameState: gameState)
      var shouldContinue = true
      switch outcome {
      case .Legal:
        let move = Move(movedPiece: piece, finalPosition: endPosition, capturedPiece: nil)
        moves.append(move)
      case .Capturing(let capturedPiece):
        let move = Move(movedPiece: piece, finalPosition: endPosition, capturedPiece: capturedPiece)
        moves.append(move)
        fallthrough
      case .Illegal:
        shouldContinue = false
      }
      if (!shouldContinue) {
        break
      }
    }
    
  }
  return moves
}


public func regularInitialPieces() -> [Piece] {
  var pieces: [Piece] = []
  for player in [ 0, 1 ] {
    for (column, (belongsType, pieceType)) in fealty.enumerated() {
        pieces.append(Piece(
            player: player,
            type:pieceType.rawValue,
            designation:"\(player)\(belongsType)\(pieceType)",
            startingPosition:Position(row: (player == 0) ? 0 : 7, column: column)))
        pieces.append(Piece(
            player: player,
            type:RegularPiece.pawn.rawValue,
            designation:"\(player)\(belongsType)\(pieceType)",
            startingPosition:Position(row: (player == 0) ? 1 : 6, column: column)))
    }
  }
  return pieces
}

struct RegularRules : Rules {
  let boardSize: Int = kBoardSize
  let players: UInt = 2
  let pieces: [Piece] = regularInitialPieces()
  var initialState : GameState {
    return GameState(rules: self, startingPieces: self.pieces)
  }
    
  func possibleMoves(_ piece: Piece, gameState: GameState) -> [Move] {
    guard let position = gameState.pieceToPosition[piece] else {
      return []
    }
    switch piece.type {
    case RegularPiece.rook.rawValue:
     return movesFromChains(piece: piece, moveChains: rookMoveChains, gameState: gameState)
    case RegularPiece.knight.rawValue:
      return movesFromChains(piece: piece, moveChains: knightMoveChains, gameState: gameState)
    case RegularPiece.bishop.rawValue:
      return movesFromChains(piece: piece, moveChains: bisopMoveChains, gameState: gameState)
    case RegularPiece.queen.rawValue:
      return movesFromChains(piece: piece, moveChains: queenMoveChains, gameState: gameState)
    case RegularPiece.king.rawValue:
      return movesFromChains(piece: piece, moveChains: kingMoveChains, gameState: gameState)
    case RegularPiece.pawn.rawValue:
      var moves: [Move] = []
      let yDirection = piece.startingPosition.row > (self.boardSize / 2) ? -1 : 1;
      let forwards = Position(row: yDirection, column: 0)
      let consideredPosition1 = position + forwards
      if gameState.positionToPiece[consideredPosition1] == nil {
          moves.append(Move(movedPiece: piece, finalPosition: consideredPosition1, capturedPiece: nil))
        if (position == piece.startingPosition) {
          let consideredPosition2 = consideredPosition1 + forwards
          if gameState.positionToPiece[consideredPosition2] == nil {
            moves.append(Move(movedPiece: piece, finalPosition: consideredPosition2, capturedPiece: nil))
          }
        }
      }
      let possibleCaptures = [ Position(row: yDirection, column: 1), Position(row: yDirection, column: -1) ]
      for delta in possibleCaptures {
      let consideredPosition3 = position + delta
        if let target = gameState.positionToPiece[consideredPosition3] {
          if (target.player != piece.player) {
            moves.append(Move(movedPiece: piece, finalPosition: consideredPosition3, capturedPiece: target))
          }
        }
      }
      return moves
    default:
      return []
    }
  }
  
  func resolveMoves(_ gameState: GameState, moveChoices: Dictionary<Player, Move>) -> Outcome {
    // TODO: Actually implement this.
    return Outcome(performedMoves: moveChoices, finalState: gameState, status: .ongoing)
  }
}

