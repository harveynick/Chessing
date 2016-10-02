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
      label.textColor = self.isSelected ? teamColor?.withAlphaComponent(0.5) : teamColor
    }
  }
  
  override var isSelected: Bool {
    didSet {
      label.textColor = self.isSelected ? teamColor?.withAlphaComponent(0.5) : teamColor
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

// Mark: ChessBoardCell

class ChessThreatCell : UICollectionViewCell {
  static let reuseIdentifier = "ChessThreatCell"
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.layer.borderColor = UIColor.orange.cgColor
    self.layer.borderWidth = 1.0
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// Mark - ChessCollectionViewLayout

class ChessCollectionViewLayout : UICollectionViewLayout {
  
  fileprivate var boardRects : [CGRect]?
  fileprivate var peiceRects : [CGRect]?
  fileprivate var gameState: GameState
  
  init(gameState: GameState) {
    self.gameState = gameState
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
    let gameController = self.gameState.controller
    let size = collectionView.bounds.size;
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
    
    var boardRects = Array<CGRect>()
    var peiceRects = Array<CGRect>()
    for i in 0 ..< 64 {
      let column = i % 8;
      let row = (i - column) / 8
      boardRects.append(rectForRow(row, column: column))
    }
    for peice in self.gameState.controller.pieces {
      if let position = self.gameState.pieceToPosition[peice] {
        peiceRects.append(rectForRow(Int(position.row), column: Int(position.column)))
      } else {
        // handle taken peices
      }
    }
    self.boardRects = boardRects
    self.peiceRects = peiceRects
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
      guard let boardRects = self.boardRects else {
        return nil
      }
      let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      attributes.frame = boardRects[(indexPath as NSIndexPath).item]
      attributes.alpha = 0.0
      return attributes;
    }
  }
}

class ChessCollectionViewController : UICollectionViewController {
  
  var game : Game
  
  init(game : Game) {
    self.game = game
    var currentSate : GameState
    if let outcome = game.outcomes.last {
      currentSate = outcome.finalState
    } else {
      currentSate = game.gameController.initialState
    }
    super.init(collectionViewLayout: ChessCollectionViewLayout(gameState: currentSate))
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
    let gameController = self.game.gameController
    if section == SectionType.board.rawValue ||  section == SectionType.threat.rawValue {
      return gameController.boards * gameController.boardHeight * gameController.boardWidth
    } else {
      return gameController.pieces.count;
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if ((indexPath as NSIndexPath).section == SectionType.board.rawValue) {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChessBoardCell.reuseIdentifier, for: indexPath)
      let gameController = self.game.gameController
      let column = (indexPath as NSIndexPath).item % gameController.boardWidth;
      let row = ((indexPath as NSIndexPath).item - column) / gameController.boardHeight
      cell.contentView.backgroundColor = ((row + column) % 2 == 0) ? UIColor(white: 0.95, alpha: 1) : UIColor(white: 0.9, alpha: 1)
      return cell
    } else if ((indexPath as NSIndexPath).section == SectionType.piece.rawValue) {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChessPieceCell.reuseIdentifier, for: indexPath)
      let pieceCell = cell as! ChessPieceCell
      let piece = self.game.gameController.pieces[(indexPath as NSIndexPath).item]
      pieceCell.designation = kPrettyDesignations[String(piece.type)]
      pieceCell.teamColor = piece.player.colour == "B" ? UIColor.blue : UIColor.red
      return cell
    } else {
      return collectionView.dequeueReusableCell(withReuseIdentifier: ChessThreatCell.reuseIdentifier, for: indexPath)
    }
  }
  
  /// Mark: UICollectionViewDelegate
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    NSLog("\(indexPath)")
  }
}
