//
//  GameUI.swift
//  Simultaneus Chess
//
//  Created by Nicholas Adam Johnson on 31/07/2016.
//  Copyright © 2016 Nicholas Adam Johnson. All rights reserved.
//

import Foundation
import UIKit

let kPrettyDesignations = [ "R": "♜", "N": "♞", "B" : "♝", "Q" : "♛", "K" : "♚", "P": "♟" ]

enum SectionType : Int {
  case board, piece, threat, count
}

// Mark: ChessBoardCell

class ChessBoardCell : UICollectionViewCell {
  static let reuseIdentifier = "ChessBoardCell"
}

// Mark: ChessPieceCell

class ChessPieceCell : UICollectionViewCell {
  static let reuseIdentifier = "ChessPieceCell"
  
  fileprivate let label : UILabel
  
  var designation : String? {
    didSet {
      label.text = designation
    }
  }
  
  var teamColor : UIColor? {
    didSet {
      label.textColor = teamColor
    }
  }
  
  override var isSelected: Bool {
    didSet {
      label.font = UIFont.systemFont(ofSize: self.isSelected ? 40 : 32)
    }
  }
  
  override var isHighlighted: Bool {
    didSet {
      label.font = UIFont.systemFont(ofSize: self.isHighlighted ? 40 : 32)
    }
  }
  
  override init(frame: CGRect) {
    label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
    label.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.flexibleWidth.rawValue | UIViewAutoresizing.flexibleHeight.rawValue)
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 32)
    label.adjustsFontSizeToFitWidth = true
    super.init(frame: frame)
    self.addSubview(label)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

// Mark: ChessThreatCell

class ChessThreatCell : UICollectionViewCell {
  static let reuseIdentifier = "ChessThreatCell"
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
  }
  
  override var isSelected: Bool {
    didSet {
      let baseColor = self.isSelected ? UIColor.darkGray : UIColor.gray
      self.backgroundColor = baseColor.withAlphaComponent(0.5)
    }
  }
  
  override var isHighlighted: Bool {
    didSet {
      let baseColor = self.isHighlighted ? UIColor.darkGray : UIColor.gray
      self.backgroundColor = baseColor.withAlphaComponent(0.5)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// Mark - ChessCollectionViewLayout

class ChessCollectionViewLayout : UICollectionViewLayout {
  
  fileprivate var boardRects : [CGRect]?
  fileprivate var peiceRects : [CGRect]?
  fileprivate var threats : [Bool]?
  fileprivate let gameState: GameState
  fileprivate let selectedPiece: Piece?
  
  init(gameState: GameState, selectedPiece: Piece?) {
    self.gameState = gameState
    self.selectedPiece = selectedPiece
    super.init()
    self.register(ChessBoardCell.self, forDecorationViewOfKind: ChessBoardCell.reuseIdentifier)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true;
  }
  
  override func prepare() {
    super.prepare();
    guard let collectionView = self.collectionView else {
      return;
    }
    let gameController = self.gameState.rules
    let size =  UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).size;
    let minDimension = min(size.width, size.height)
    let tileSize = floor(minDimension / 8)
    let leftPadding = floor((size.width - (tileSize * 8)) / 2)
    let topPadding = floor((size.height - (tileSize * 8)) / 2)
    
    func rectForRow(_ row: Int, column: Int) -> CGRect {
      return CGRect(x: leftPadding + CGFloat(column) * tileSize,
                        y: topPadding + CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize);
    }
    
    let threatenedPositons : [Position]
    if let selectedPiece = self.selectedPiece {
      let moves = self.gameState.rules.generateMoves(selectedPiece, gameState:gameState)
      threatenedPositons = moves.map { move in move.finalPosition }
    } else {
      threatenedPositons = []
    }
    
    var boardRects = Array<CGRect>()
    var peiceRects = Array<CGRect>()
    var threats = Array<Bool>()
    for i in 0 ..< 64 {
      let column = i % 8;
      let row = (i - column) / 8
      boardRects.append(rectForRow(row, column: column))
      threats.append(threatenedPositons.contains(Position(row: row, column: column)))
    }
    for peice in self.gameState.rules.pieces {
      if let position = self.gameState.pieceToPosition[peice] {
        peiceRects.append(rectForRow(Int(position.row), column: Int(position.column)))
      } else {
        // handle taken peices
      }
    }
    self.boardRects = boardRects
    self.peiceRects = peiceRects
    self.threats = threats
  }
  
  override var collectionViewContentSize : CGSize {
    guard let boardRects = self.boardRects, let boardRect = boardRects.last else {
      return CGSize.zero
    }
    return CGSize(width: boardRect.maxX, height: boardRect.maxY)
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let boardRects = self.boardRects, let peiceRects = self.peiceRects else {
      return nil
    }
    var attributes = Array<UICollectionViewLayoutAttributes>()
    for (i, boardRect) in boardRects.enumerated() {
      if (rect.intersects(boardRect)) {
        let boardIndexPath = IndexPath(item:i, section:SectionType.board.rawValue)
        if let localAttributes = self.layoutAttributesForItem(at: boardIndexPath) {
          attributes.append(localAttributes)
        }
        let threatIndexPath = IndexPath(item:i, section:SectionType.threat.rawValue)
        if let localAttributes = self.layoutAttributesForItem(at: threatIndexPath) {
          attributes.append(localAttributes)
        }
      }
    }
    for (i, peiceRect) in peiceRects.enumerated() {
      if (rect.intersects(peiceRect)) {
        let indexPath = IndexPath(item:i, section:SectionType.piece.rawValue)
        if let localAttributes = self.layoutAttributesForItem(at: indexPath) {
          attributes.append(localAttributes)
        }
      }
    }
    return attributes
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    if ((indexPath as NSIndexPath).section == SectionType.board.rawValue) {
      guard let boardRects = self.boardRects else {
        return nil
      }
      let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      attributes.frame = boardRects[(indexPath as NSIndexPath).item]
      return attributes;
    } else if ((indexPath as NSIndexPath).section == SectionType.piece.rawValue) {
      guard let peiceRects = self.peiceRects else {
        return nil
      }
      let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      attributes.frame = peiceRects[(indexPath as NSIndexPath).item]
      return attributes;
    } else {
      guard let boardRects = self.boardRects, let threats = self.threats else {
        return nil
      }
      let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      attributes.frame = boardRects[(indexPath as NSIndexPath).item]
      attributes.alpha = threats[(indexPath as NSIndexPath).item] ? 1.0 : 0.0
      return attributes;
    }
  }
}

class ChessCollectionViewController : UICollectionViewController {
  
  var gameState : GameState
  let player : Player
  
  init(gameState : GameState, player : Player) {
    self.gameState = gameState
    self.player = player
    super.init(collectionViewLayout: ChessCollectionViewLayout(gameState:gameState, selectedPiece:nil))
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad();
    guard let collectionView  = self.collectionView else {
      return
    }
    collectionView.backgroundColor = UIColor.white
    collectionView.allowsMultipleSelection = true
    collectionView.register(ChessBoardCell.self, forCellWithReuseIdentifier: ChessBoardCell.reuseIdentifier)
    collectionView.register(ChessPieceCell.self, forCellWithReuseIdentifier: ChessPieceCell.reuseIdentifier)
    collectionView.register(ChessThreatCell.self, forCellWithReuseIdentifier: ChessThreatCell.reuseIdentifier)
  }
  
  override var prefersStatusBarHidden : Bool {
    return true
  }
    
  /// Mark: UICollectionViewDataSource
    
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return SectionType.count.rawValue;
  }
    
  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    let rules = self.gameState.rules
    if section == SectionType.board.rawValue ||  section == SectionType.threat.rawValue {
      return rules.boards * rules.boardHeight * rules.boardWidth
    } else {
      return rules.pieces.count;
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if ((indexPath as NSIndexPath).section == SectionType.board.rawValue) {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChessBoardCell.reuseIdentifier, for: indexPath)
      let gameController = self.gameState.rules
      let column = (indexPath as NSIndexPath).item % gameController.boardWidth;
      let row = ((indexPath as NSIndexPath).item - column) / gameController.boardHeight
      cell.contentView.backgroundColor = ((row + column) % 2 == 0) ? UIColor(white: 0.95, alpha: 1) : UIColor(white: 0.9, alpha: 1)
      return cell
    } else if ((indexPath as NSIndexPath).section == SectionType.piece.rawValue) {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChessPieceCell.reuseIdentifier, for: indexPath)
      let pieceCell = cell as! ChessPieceCell
      let piece = self.gameState.rules.pieces[(indexPath as NSIndexPath).item]
      pieceCell.designation = kPrettyDesignations[String(piece.type)]
      pieceCell.teamColor = (piece.player == 0) ? UIColor.blue : UIColor.red
      return cell
    } else {
      return collectionView.dequeueReusableCell(withReuseIdentifier: ChessThreatCell.reuseIdentifier, for: indexPath)
    }
  }
  
  /// Mark: UICollectionViewDelegate
  
  override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    if (indexPath as NSIndexPath).section == SectionType.threat.rawValue {
      return true
    }
    if (indexPath as NSIndexPath).section == SectionType.piece.rawValue {
      let selectedPiece = self.gameState.rules.pieces[(indexPath as NSIndexPath).item]
      return selectedPiece.player == self.player
    }
    if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems {
      for selectedIndex in indexPathsForSelectedItems {
        collectionView.deselectItem(at: selectedIndex, animated: false)
      }
      self.navigationItem.rightBarButtonItem = nil
    }
    let newLayout = ChessCollectionViewLayout(gameState:self.gameState, selectedPiece:nil)
    collectionView.setCollectionViewLayout(newLayout, animated: false)
    return false
  }
  
  override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
    if indexPath.section == SectionType.threat.rawValue {
      if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems {
        for selectedIndex in indexPathsForSelectedItems {
          if selectedIndex.section == SectionType.threat.rawValue {
            collectionView.deselectItem(at: selectedIndex, animated: false)
          }
          self.navigationItem.rightBarButtonItem = nil
        }
      }
      return
    }
    let selectedPiece : Piece?
    if (indexPath as NSIndexPath).section == SectionType.piece.rawValue {
      if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems {
       for selectedIndex in indexPathsForSelectedItems {
        if indexPath == selectedIndex {
          continue
        }
         collectionView.deselectItem(at: selectedIndex, animated: false)
       }
        self.navigationItem.rightBarButtonItem = nil
      }
      selectedPiece = self.gameState.rules.pieces[(indexPath as NSIndexPath).item]
    } else {
      selectedPiece = nil
    }
    
    let newLayout = ChessCollectionViewLayout(gameState:self.gameState, selectedPiece:selectedPiece)
    collectionView.setCollectionViewLayout(newLayout, animated: false)
  }
  
  override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
    if (indexPath as NSIndexPath).section == SectionType.threat.rawValue {
      return
    }
    let newLayout = ChessCollectionViewLayout(gameState:self.gameState, selectedPiece:nil)
    collectionView.setCollectionViewLayout(newLayout, animated: false)
  }
  
  override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    if (indexPath as NSIndexPath).section == SectionType.threat.rawValue {
      return true
    }
    if (indexPath as NSIndexPath).section == SectionType.piece.rawValue {
      let selectedPiece = self.gameState.rules.pieces[(indexPath as NSIndexPath).item]
      let moves = self.gameState.rules.generateMoves(selectedPiece, gameState:gameState)
      return moves.count > 0
    }
    return false
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if (indexPath as NSIndexPath).section == SectionType.threat.rawValue {
      self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Play", style: .plain, target: nil, action: nil)
      return
    }
    let selectedPiece : Piece?
    if (indexPath as NSIndexPath).section == SectionType.piece.rawValue {
      selectedPiece = self.gameState.rules.pieces[(indexPath as NSIndexPath).item]
    } else {
      selectedPiece = nil
    }
    let newLayout = ChessCollectionViewLayout(gameState:self.gameState, selectedPiece:selectedPiece)
    collectionView.setCollectionViewLayout(newLayout, animated: false)
  }
  
  override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    self.navigationItem.rightBarButtonItem = nil
    if (indexPath as NSIndexPath).section == SectionType.threat.rawValue {
      return
    }
    let newLayout = ChessCollectionViewLayout(gameState:self.gameState, selectedPiece:nil)
    collectionView.setCollectionViewLayout(newLayout, animated: false)
  }
}
