// Mark: Position

public struct Position {
  let board: Int?
  let row: Int
  let column: Int
  
  init(row: Int, column: Int) {
      self.board = nil
      self.row = row
      self.column = column
  }
  
  init(board: Int, row: Int, column: Int) {
      self.board = board
      self.row = row
      self.column = column
  }
  
  func withRow(_ row: Int) -> Position {
    if let board = self.board {
      return Position(board: board, row: row, column: self.column)
    } else {
      return Position(row: row, column: self.column)
    }
  }
  
  func withColoumn(_ column: Int) -> Position {
    if let board = self.board {
      return Position(board: board, row: self.row, column: column)
    } else {
      return Position(row: self.row, column: column)
    }
  }
}

extension Position : Hashable {
    public var hashValue: Int {
        get {
            var hashValue = (Int)((row << 1) + (column << 4))
            if let boardNumber = board {
                hashValue = hashValue + Int(boardNumber)
            }
            return hashValue
        }
    }
}

extension Position : Equatable {}
public func ==(lhs: Position, rhs: Position) -> Bool {
    return lhs.board == rhs.board &&
        lhs.row == rhs.row &&
        lhs.column == rhs.column
}


public struct Player {
  let colour: Character
  let home: Position
}

extension Player : Hashable {
  public var hashValue: Int {
    get {
      return self.colour.hashValue ^ self.home.hashValue
    }
  }
}

extension Player : Equatable {}
public func ==(lhs: Player, rhs: Player) -> Bool {
  return lhs.colour == rhs.colour && lhs.home == rhs.home
}

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

  let controller: GameController
  let pieceToPosition: [Piece:Position]
  let positionToPiece: [Position:Piece]
  let capturedPeices: [Piece]
    
  init(controller: GameController, startingPieces: [Piece]) {
    self.controller = controller
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
  
  init(controller: GameController, newPositions: [Piece:Position], newCaptures: [Piece]) {
    self.controller = controller
    self.pieceToPosition = newPositions
    var positionToPiece : [Position:Piece] = [:]
    for (piece, position) in newPositions {
      positionToPiece[position] = piece
    }
    self.positionToPiece = positionToPiece
    self.capturedPeices = newCaptures
  }
}

extension GameState : Equatable {}
public func ==(lhs: GameState, rhs: GameState) -> Bool {
  return lhs.pieceToPosition == rhs.pieceToPosition &&
      lhs.capturedPeices == rhs.capturedPeices
}

// Mark: Outcome

public struct Outcome {
    let performedMoves: Dictionary<Player, Move>
    let finalState: GameState
}

// Mark: MoveMatrix

public struct MoveMatrix {
  let availableMoves: [Piece: [Move]]
  let threatenedPositions: [Position: Set<Piece>]
}

// Mark: GameController

public protocol GameController {
  var boards: Int { get }
  var boardWidth: Int { get }
  var boardHeight: Int { get }
  var players : Set<Player> { get }
  var pieces : [Piece] { get }
  var initialState: GameState { get }
  func generateMoves(_ piece: Piece, gameState: GameState) -> [Move]
  func resolveMoves(_ gameState: GameState, moveChoices: Dictionary<Player, Move>) -> Outcome
}

// Mark: Game

public struct Game {
  let gameController: GameController
  let outcomes: Array<Outcome>
  var currentState: GameState {
    get {
      if let outcome = self.outcomes.last {
        return outcome.finalState
      } else {
        return self.gameController.initialState
      }
    }
  }
  
  fileprivate init (gameController: GameController, outcomes: Array<Outcome>) {
    self.gameController = gameController
    self.outcomes = outcomes
  }

  init(gameController: GameController) {
    let initialOutcome = Outcome(
      performedMoves: [:],
          finalState: gameController.initialState)
    self = Game(gameController:gameController, outcomes:[initialOutcome])
  }
    
  func withOutcome(_ outcome: Outcome) -> Game {
    var newOutcomes = self.outcomes
    newOutcomes .append(outcome)
   return Game(gameController: self.gameController, outcomes: newOutcomes)
  }
}
