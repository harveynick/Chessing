import Foundation

enum RegularColor : Character {
    case Black = "b"
    case White = "w"
}

enum RegularPiece : PieceType {
    case Rook = "R"
    case Knight = "N"
    case Bishop = "B"
    case Queen = "Q"
    case King = "K"
    case Pawn = "P"
}

let kNumberOfBoards : UInt = 1
let kBoardWidth : UInt = 8
let kBoardHeight : UInt = 8

let fealty : [(RegularPiece, RegularPiece)] = [
    (.Queen, .Rook),
    (.Queen, .Knight),
    (.Queen, .Bishop),
    (.Queen, .Queen),
    (.King, .King),
    (.King, .Bishop),
    (.King, .Knight),
    (.King, .Rook) ]

let prettyPieceMapping : [RegularColor : [RegularPiece : String] ] = [
    .Black : [
        .Rook  :  "♜",
        .Knight : "♞",
        .Bishop : "♝",
        .Queen :  "♛",
        .King :   "♚",
        .Pawn :   "♟",
    ],
    .White : [
        .Rook :   "♖",
        .Knight : "♘",
        .Bishop : "♗",
        .Queen :  "♕",
        .King :   "♔",
        .Pawn :   "♙",
    ]
]

let player1 = Player(colour: "B", home: Position(row: 0, column: 0))
let player2 = Player(colour: "W", home: Position(row: 7, column: 7))

public func regularInitialPieces(players: [Player]) -> [Piece] {
  var pieces: [Piece] = []
  for player in players {
    for (column, (belongsType, pieceType)) in fealty.enumerate() {
        pieces.append(Piece(
            player: player,
            type:pieceType.rawValue,
            designation:"\(player.colour)\(belongsType)\(pieceType)",
            startingPosition:Position(row: player.home.row, column: UInt(column))))
        pieces.append(Piece(
            player: player,
            type:RegularPiece.Pawn.rawValue,
            designation:"\(player.colour)\(belongsType)\(pieceType)",
            startingPosition:Position(row: player == player1 ? 1 : 6, column: UInt(column))))
    }
  }
  return pieces
}

struct RegularGameController : GameController {
  let boards: UInt = kNumberOfBoards
  let boardWidth: UInt = kBoardWidth
  let boardHeight: UInt = kBoardHeight
  let players: Set<Player> = [player1, player2]
  let pieces: [Piece] = regularInitialPieces([player1, player2])
  var initialState : GameState {
    return GameState(controller: self, startingPieces: self.pieces)
  }
    
  func generateMoveMatrix(gameState: GameState) -> MoveMatrix {
    var availableMoves: [Piece: [Move]] = [:]
    var threatenedPositions: [Position: Set<Piece>] = [:]
    for (piece, position) in gameState.pieceToPosition {
      var moves: [Move] = []
      switch piece.type {
      case RegularPiece.Rook.rawValue:
        var consideredPosition = position.withColoumn(position.column + 1)
        while (consideredPosition.column < kBoardWidth) {
          if let target = gameState.positionToPiece[consideredPosition] {
            if (target.player != piece.player) {
              moves.append(Move(movedPiece: piece, positions: [consideredPosition], capturedPiece: target))
            }
            break;
          } else {
            moves.append(Move(movedPiece: piece, positions: [consideredPosition], capturedPiece: nil))
          }
          consideredPosition = consideredPosition.withColoumn(consideredPosition.column + 1)
        }
      default:
        NSLog("Big TODO")
      }
      availableMoves[piece] = moves
      for move in moves {
        var threatened = threatenedPositions[move.positions.last!]
        if threatened == nil {
          threatened = []
        }
        threatened?.insert(piece)
        threatenedPositions[move.positions.last!] = threatened
      }
    }
    return MoveMatrix(availableMoves: availableMoves, threatenedPositions: threatenedPositions)
  }
  
  func resolveMoves(gameState: GameState, moveChoices: Dictionary<Player, Move>) -> Outcome {
    // TODO: Actually implement this.
    return Outcome(performedMoves: moveChoices, finalState: gameState)
  }
}

