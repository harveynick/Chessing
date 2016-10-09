import Foundation

enum RegularColor : Character {
    case black = "b"
    case white = "w"
}

enum RegularPiece : PieceType {
    case rook = "R"
    case knight = "N"
    case bishop = "B"
    case queen = "Q"
    case king = "K"
    case pawn = "P"
}

let kNumberOfBoards : Int = 1
let kBoardWidth : Int = 8
let kBoardHeight : Int = 8

let fealty : [(RegularPiece, RegularPiece)] = [
    (.queen, .rook),
    (.queen, .knight),
    (.queen, .bishop),
    (.queen, .queen),
    (.king, .king),
    (.king, .bishop),
    (.king, .knight),
    (.king, .rook) ]

let prettyPieceMapping : [RegularColor : [RegularPiece : String] ] = [
    .black : [
        .rook  :  "♜",
        .knight : "♞",
        .bishop : "♝",
        .queen :  "♛",
        .king :   "♚",
        .pawn :   "♟",
    ],
    .white : [
        .rook :   "♖",
        .knight : "♘",
        .bishop : "♗",
        .queen :  "♕",
        .king :   "♔",
        .pawn :   "♙",
    ]
]

let player1 = Player(colour: "B", home: Position(row: 0, column: 0))
let player2 = Player(colour: "W", home: Position(row: 7, column: 7))

public func regularInitialPieces() -> [Piece] {
  var pieces: [Piece] = []
  for player in [ player1, player2 ] {
    for (column, (belongsType, pieceType)) in fealty.enumerated() {
        pieces.append(Piece(
            player: player,
            type:pieceType.rawValue,
            designation:"\(player.colour)\(belongsType)\(pieceType)",
            startingPosition:Position(row: player.home.row, column: column)))
        pieces.append(Piece(
            player: player,
            type:RegularPiece.pawn.rawValue,
            designation:"\(player.colour)\(belongsType)\(pieceType)",
            startingPosition:Position(row: player == player1 ? 1 : 6, column: column)))
    }
  }
  return pieces
}

struct RegularRules : Rules {
  let boards: Int = kNumberOfBoards
  let boardWidth: Int = kBoardWidth
  let boardHeight: Int = kBoardHeight
  let players: Set<Player> = [player1, player2]
  let pieces: [Piece] = regularInitialPieces()
  var initialState : GameState {
    return GameState(rules: self, startingPieces: self.pieces)
  }
    
  func generateMoves(_ piece: Piece, gameState: GameState) -> [Move] {
    guard let position = gameState.pieceToPosition[piece] else {
      return []
    }
    var moves: [Move] = []
    switch piece.type {
    case RegularPiece.rook.rawValue:
      var consideredPosition = position.withColoumn(position.column + 1)
      while (consideredPosition.column < kBoardWidth) {
        if let target = gameState.positionToPiece[consideredPosition] {
          if (target.player != piece.player) {
            moves.append(Move(movedPiece: piece, finalPosition: consideredPosition, capturedPiece: target))
          }
          break;
        } else {
          moves.append(Move(movedPiece: piece, finalPosition: consideredPosition, capturedPiece: nil))
        }
        consideredPosition = consideredPosition.withColoumn(consideredPosition.column + 1)
      }
      break
    case RegularPiece.pawn.rawValue:
      let yDirection = piece.startingPosition.row > (self.boardHeight / 2) ? -1 : 1;
      let consideredPosition1 = position.withRow(position.row + yDirection)
      if gameState.positionToPiece[consideredPosition1] == nil {
          moves.append(Move(movedPiece: piece, finalPosition: consideredPosition1, capturedPiece: nil))
        
        if (position == piece.startingPosition) {
          let consideredPosition2 = consideredPosition1.withRow(consideredPosition1.row + yDirection)
          if gameState.positionToPiece[consideredPosition2] == nil {
            moves.append(Move(movedPiece: piece, finalPosition: consideredPosition2, capturedPiece: nil))
          }
        }
      }
      
      let consideredPosition3 = consideredPosition1.withColoumn(consideredPosition1.column + 1)
      if let target = gameState.positionToPiece[consideredPosition3] {
        if (target.player != piece.player) {
          moves.append(Move(movedPiece: piece, finalPosition: consideredPosition3, capturedPiece: target))
        }
      }
      
      let consideredPosition4 = consideredPosition1.withColoumn(consideredPosition1.column - 1)
      if let target = gameState.positionToPiece[consideredPosition4] {
        if (target.player != piece.player) {
          moves.append(Move(movedPiece: piece, finalPosition: consideredPosition4, capturedPiece: target))
        }
      }
      break;
    default:
      NSLog("Big TODO")
    }
   return moves
  }
  
  func resolveMoves(_ gameState: GameState, moveChoices: Dictionary<Player, Move>) -> Outcome {
    // TODO: Actually implement this.
    return Outcome(performedMoves: moveChoices, finalState: gameState)
  }
}

