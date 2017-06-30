import Foundation


let kBoardSize = 8

let fealty : [(PieceType, PieceType)] = [
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
                 endPosition: Position,
                 gameState: GameState) -> MoveOperationOutcome {
  let maxPosition = kBoardSize - 1
  if endPosition.row > maxPosition ||
     endPosition.row < 0 ||
     endPosition.column > maxPosition ||
     endPosition.column < 0 {
    return .Illegal
  }
  if let target = gameState.positionToPiece[endPosition] {
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
      let outcome = moveOutcome(piece: piece, endPosition: endPosition, gameState: gameState)
      var shouldContinue = true
      switch outcome {
      case .Legal:
        let move = Move(moved: piece, finalPosition: endPosition, captured: nil)
        moves.append(move)
      case .Capturing(let capturedPiece):
        let move = Move(moved: piece, finalPosition: endPosition, captured: capturedPiece)
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


public func regularInitialPieces() -> [Piece:Position] {
  var pieces: [Piece:Position] = [:]
  for player in [ Player.white, Player.black ] {
    let homeRow = player.homeRow(forBoardSize: kBoardSize)
    for (column, (belongsType, pieceType)) in fealty.enumerated() {
      let position = Position(row: homeRow, column: column)
      let piece = Piece(
            player: player,
            type:pieceType,
            designation:"\(player)\(belongsType)\(pieceType)")
      pieces[piece] = position
      
      let pawnPosition = Position(row: homeRow + player.forwards, column: column);
      let pawn = Piece(
            player: player,
            type:.pawn,
            designation:"\(player)\(belongsType)\(pieceType)p")
      pieces[pawn] = pawnPosition
    }
  }
  return pieces
}

struct RegularRules : Rules {
  let boardSize: Int = kBoardSize
  let players: UInt = 2
  let pieces: [Piece] = regularInitialPieces().keys.sorted(by: { $0.designation < $1.designation })
  var initialState : GameState {
    return GameState(boardSize: kBoardSize, positions: regularInitialPieces())
  }
    
  func possibleMoves(for piece: Piece, in gameState: GameState, previousMoves: [[Move]]) -> [Move] {
    guard let position = gameState.pieceToPosition[piece] else {
      return []
    }
    switch piece.type {
    case .rook:
     return movesFromChains(piece: piece, moveChains: rookMoveChains, gameState: gameState)
    case .knight:
      return movesFromChains(piece: piece, moveChains: knightMoveChains, gameState: gameState)
    case .bishop:
      return movesFromChains(piece: piece, moveChains: bisopMoveChains, gameState: gameState)
    case .queen:
      return movesFromChains(piece: piece, moveChains: queenMoveChains, gameState: gameState)
    case .king:
      return movesFromChains(piece: piece, moveChains: kingMoveChains, gameState: gameState)
    case .pawn:
      var moves: [Move] = []
      let forwards = Position(row: piece.player.forwards, column: 0)
      let consideredPosition1 = position + forwards
      if gameState.positionToPiece[consideredPosition1] == nil {
        moves.append(Move(moved: piece, finalPosition: consideredPosition1, captured: nil))
        if (previousMoves.flatMap{ $0.map{ $0.moved } }.first(where: { $0 == piece }) == nil) {
          let consideredPosition2 = consideredPosition1 + forwards
          if gameState.positionToPiece[consideredPosition2] == nil {
            moves.append(Move(moved: piece, finalPosition: consideredPosition2, captured: nil))
          }
        }
      }
      let possibleCaptures = [ Position(row: piece.player.forwards, column: 1),
                               Position(row: piece.player.forwards, column: -1) ]
      for delta in possibleCaptures {
      let consideredPosition3 = position + delta
        if let target = gameState.positionToPiece[consideredPosition3] {
          if (target.player != piece.player) {
            moves.append(Move(moved: piece, finalPosition: consideredPosition3, captured: target))
          }
        }
      }
      return moves
    }
  }
  
  func isChecking(move: Move) -> Bool {
    return move.captured?.type == .king
  }
  
  func resolve(moves: [Move], in gameState: GameState) -> Outcome? {
    let move1 = moves[0]
    let move2 = moves[1]
    guard move1.moved.player != move2.moved.player else {
      return nil
    }
    
    var performedMoves = moves
    if move1.finalPosition == move2.finalPosition {
      // TODO Based on terratory.
    } else if move1.captured == move2.moved,
              move2.captured == move1.moved {
      // TODO Both moves proceed.
      
    } else if move1.captured == move2.moved,
              move1.moved.type > move2.moved.type {
      performedMoves.remove(at:1)
    } else if move2.captured == move1.moved,
              move2.moved.type > move1.moved.type {
      performedMoves.remove(at:0)
    }
    
    // TODO: Actually implement this.
    return Outcome(requestedMoves: moves,
                   performedMoves: performedMoves,
                   finalState: gameState,
                   status: .ongoing)
  }
}

