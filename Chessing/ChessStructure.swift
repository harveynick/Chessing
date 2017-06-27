// Mark: Position

public struct Position {
  let row: Int
  let column: Int
  
  init(row: Int, column: Int) {
      self.row = row
      self.column = column
  }
  
  func withRow(_ row: Int) -> Position {
    return Position(row: row, column: self.column)
  }
  
  func withColoumn(_ column: Int) -> Position {
    return Position(row: self.row, column: column)
  }
}

extension Position : Hashable {
  public var hashValue: Int {
    get {
      return (Int)((row << 1) + (column << 4))
    }
  }
}

extension Position : Equatable {}
public func ==(lhs: Position, rhs: Position) -> Bool {
    return lhs.row == rhs.row &&
        lhs.column == rhs.column
}

func +(left: Position, right: Position) -> Position {
  return Position(row: left.row + right.row,
                  column: left.column + right.column)
}

// Mark: Player

public enum Player {
  case white
  case black
  
  func homeRow(forBoardSize boardSize: Int) -> Int {
    switch self {
    case .white:
      return 0
    case .black:
      return boardSize - 1
    }
  }
  
  var forwards: Int {
    switch self {
    case .white:
      return 1
    case .black:
      return -1
    }
  }
}

// Mark: PieceType

enum PieceType : Int {
  case pawn
  case knight
  case bishop
  case rook
  case queen
  case king
  
  var signifier : String {
    switch self {
    case .pawn:
      return "P"
    case .knight:
      return "N"
    case .bishop:
      return "B"
    case .rook:
      return "R"
    case .queen:
      return "Q"
    case .king:
      return "K"
    }
  }
}

extension PieceType : Comparable {
  public static func <(lhs: PieceType, rhs: PieceType) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}

// Mark: Piece

public struct Piece {
    let player: Player
    let type: PieceType
    let designation: String
//    let startingPosition: Position
}

extension Piece : Hashable {
    public var hashValue: Int {
        get {
            return designation.hashValue
        }
    }
}

extension Piece : Equatable {}
public func ==(lhs: Piece, rhs: Piece) -> Bool {
    return lhs.designation == rhs.designation
}


// Mark: Move

public struct Move {
  let moved: Piece
  let finalPosition: Position
  let captured: Piece?
  
  func asCapture(of captured: Piece) -> Move {
    return Move(moved: moved, finalPosition: finalPosition, captured: captured)
  }
}

extension Move : Equatable {}
public func ==(lhs: Move, rhs: Move) -> Bool {
    return lhs.moved == rhs.moved &&
        lhs.finalPosition == rhs.finalPosition &&
        lhs.captured == rhs.captured
}

// Mark: GameState

public struct GameState {

  let boardSize: Int
  let pieceToPosition: [Piece:Position]
  let positionToPiece: [Position:Piece]
  let capturedPeices: [Piece]
    
//  init(boardSize: Int, startingPieces: [Piece:Position]) {
//    self.boardSize = boardSize
//    var pieceToPosition : [Piece:Position] = [:]
//    var positionToPiece : [Position:Piece] = [:]
//    for piece in startingPieces {
//      let startingPosition = piece.startingPosition
//      pieceToPosition[piece] = startingPosition
//      positionToPiece[startingPosition] = piece
//    }
//    self.pieceToPosition = startingPieces
//    self.positionToPiece = positionToPiece
//    self.capturedPeices = []
//  }
  
  init(boardSize: Int, newPositions: [Piece:Position], newCaptures: [Piece]) {
    self.boardSize = boardSize
    self.pieceToPosition = newPositions
    var positionToPiece : [Position:Piece] = [:]
    for (piece, position) in newPositions {
      positionToPiece[position] = piece
    }
    self.positionToPiece = positionToPiece
    self.capturedPeices = newCaptures
  }
  
  func apply(moves: [Move]) -> GameState {
    var newPositions = pieceToPosition
    var captures = capturedPeices
    for move in moves {
      newPositions[move.moved] = move.finalPosition
    }
    for move in moves {
      if let capture = move.captured {
        captures.append(capture)
        newPositions.removeValue(forKey: capture)
      }
    }
    return GameState(boardSize: boardSize, newPositions: newPositions, newCaptures: captures)
  }
}

extension GameState : Equatable {}
public func ==(lhs: GameState, rhs: GameState) -> Bool {
  return lhs.pieceToPosition == rhs.pieceToPosition &&
      lhs.capturedPeices == rhs.capturedPeices
}

// Mark: GameStatus

public enum GameStatus {
  case ongoing
  case checked([Player])
  case checkmated([Player])
  case stalemated([Player])
  case resigned([Player])
}

// Mark: Outcome

public struct Outcome {
  let requestedMoves: [Move]
  let performedMoves: [Move]
  let finalState: GameState
  let status : GameStatus
}

// Mark: MoveMatrix

public struct MoveMatrix {
  let availableMoves: [Piece: [Move]]
  let threatenedPositions: [Position: Set<Piece>]
}

// Mark: Rules

public protocol Rules {
  var pieces : [Piece] { get }
  var initialState: GameState { get }
  func possibleMoves(for piece: Piece, in gameState: GameState, previousMoves: [[Move]]) -> [Move]
  func isChecking(move: Move) -> Bool
  func resolve(moves: [Move], in gameState: GameState) -> Outcome?
}

public extension Rules {
  
  func possibleMoves(for gameState: GameState, previousMoves: [[Move]], excluding: [Player] = []) -> [Move] {
    return pieces
      .filter { !gameState.capturedPeices.contains($0) && !excluding.contains($0.player) }
      .map { possibleMoves(for: $0, in: gameState, previousMoves: previousMoves) }
      .reduce([]) { $0 + $1 }
  }
  
  func legalMoves(in gameState: GameState, previousMoves: [[Move]]) -> [Move] {
    return possibleMoves(for: gameState, previousMoves: previousMoves)
      .filter { possibleMoves(for: gameState.apply(moves: [$0]),
                              previousMoves: previousMoves,
                              excluding: [$0.moved.player]).first(where:isChecking) == nil }
  }
}

// Mark: Game

public struct Game {
  let rules: Rules
  let outcomes: [Outcome]
  
  var currentState: GameState {
    get {
      if let outcome = self.outcomes.last {
        return outcome.finalState
      } else {
        return self.rules.initialState
      }
    }
  }
  
  var previousMoves: [[Move]] {
    return outcomes.map { $0.performedMoves }
  }
  
  fileprivate init (rules: Rules, outcomes: Array<Outcome>) {
    self.rules = rules
    self.outcomes = outcomes
  }

  init(rules: Rules) {
    let initialOutcome = Outcome(requestedMoves:[],
                                 performedMoves: [],
                                 finalState: rules.initialState,
                                 status: .ongoing)
    self = Game(rules:rules, outcomes:[initialOutcome])
  }
    
  func withOutcome(_ outcome: Outcome) -> Game {
    var newOutcomes = self.outcomes
    newOutcomes .append(outcome)
   return Game(rules: self.rules, outcomes: newOutcomes)
  }
}
