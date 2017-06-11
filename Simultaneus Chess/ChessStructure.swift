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

public typealias Player = Int

// Mark: Peice

public typealias PieceType = Character

public struct Piece {
    let player: Player
    let type: PieceType
    let designation: String
    let startingPosition: Position
}

extension Piece : Hashable {
    public var hashValue: Int {
        get {
            return startingPosition.hashValue
        }
    }
}

extension Piece : Equatable {}
public func ==(lhs: Piece, rhs: Piece) -> Bool {
    return lhs.startingPosition == rhs.startingPosition
}


// Mark: Move

public struct Move {
  let movedPiece: Piece
  let finalPosition: Position
  let capturedPiece: Piece?
}

extension Move : Equatable {}
public func ==(lhs: Move, rhs: Move) -> Bool {
    return lhs.movedPiece == rhs.movedPiece &&
        lhs.finalPosition == rhs.finalPosition &&
        lhs.capturedPiece == rhs.capturedPiece
}

// Mark: GameState

public struct GameState {

  let boardSize: Int
  let pieceToPosition: [Piece:Position]
  let positionToPiece: [Position:Piece]
  let capturedPeices: [Piece]
    
  init(boardSize: Int, startingPieces: [Piece]) {
    self.boardSize = boardSize
    var pieceToPosition : [Piece:Position] = [:]
    var positionToPiece : [Position:Piece] = [:]
    for piece in startingPieces {
      let startingPosition = piece.startingPosition
      pieceToPosition[piece] = startingPosition
      positionToPiece[startingPosition] = piece
    }
    self.pieceToPosition = pieceToPosition
    self.positionToPiece = positionToPiece
    self.capturedPeices = []
  }
  
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
  
  func apply(move: Move) -> GameState {
    var newPositions = pieceToPosition
    newPositions[move.movedPiece] = move.finalPosition
    var captures = capturedPeices
    if let capture = move.capturedPiece {
      captures.append(capture)
      newPositions.removeValue(forKey: capture)
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
  func possibleMoves(for piece: Piece, in gameState: GameState) -> [Move]
  func isChecking(move: Move) -> Bool
  func resolve(moves: [Move], in gameState: GameState) -> Outcome
}

public extension Rules {
  
  func possibleMoves(for gameState: GameState, excluding: [Player] = []) -> [Move] {
    return pieces
      .filter { !gameState.capturedPeices.contains($0) && !excluding.contains($0.player) }
      .map { possibleMoves(for: $0, in: gameState) }
      .reduce([]) { $0 + $1 }
  }
  
  func legalMoves(in gameState: GameState) -> [Move] {
    return possibleMoves(for: gameState)
      .filter { possibleMoves(for: gameState.apply(move: $0), excluding: [$0.movedPiece.player]).first(where:isChecking) == nil}
  }
}

// Mark: Game

public struct Game {
  let rules: Rules
  let outcomes: Array<Outcome>
  var currentState: GameState {
    get {
      if let outcome = self.outcomes.last {
        return outcome.finalState
      } else {
        return self.rules.initialState
      }
    }
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
