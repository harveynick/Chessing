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
  case Board, Piece, Count
}

// Mark: ChessBoardCell

class ChessBoardCell : UICollectionViewCell {
  static let reuseIdentifier = "ChessBoardCell"
}

// Mark: ChessPieceCell

class ChessPieceCell : UICollectionViewCell {
  static let reuseIdentifier = "ChessPieceCell"
  
  private let label : UILabel
  
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
  
  override init(frame: CGRect) {
    label = UILabel(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
    label.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue)
    label.textAlignment = .Center
    label.font = UIFont.systemFontOfSize(32)
    label.adjustsFontSizeToFitWidth = true
    super.init(frame: frame)
    self.addSubview(label)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

// Mark - ChessCollectionViewLayout

class ChessCollectionViewLayout : UICollectionViewLayout {
  
  private var boardRects : [CGRect]?
  private var peiceRects : [CGRect]?
  private var gameState: GameState
  
  init(gameState: GameState) {
    self.gameState = gameState
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
    return true;
  }
  
  override func prepareLayout() {
    super.prepareLayout();
    guard let collectionView = self.collectionView else {
      return;
    }
    let gameController = self.gameState.controller
    let size = collectionView.bounds.size;
    let minDimension = min(size.width, size.height)
    let tileSize = floor(minDimension / 8)
    let leftPadding = floor((size.width - (tileSize * 8)) / 2)
    let topPadding = floor((size.height - (tileSize * 8)) / 2)
    
    func rectForRow(row: Int, column: Int) -> CGRect {
      return CGRectMake(leftPadding + CGFloat(column) * tileSize,
                        topPadding + CGFloat(row) * tileSize,
                        tileSize,
                        tileSize);
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
  
  override func collectionViewContentSize() -> CGSize {
    guard let boardRects = self.boardRects, boardRect = boardRects.last else {
      return CGSizeZero
    }
    return CGSizeMake(CGRectGetMaxX(boardRect), CGRectGetMaxY(boardRect))
  }
  
  override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let boardRects = self.boardRects, peiceRects = self.peiceRects else {
      return nil
    }
    var attributes = Array<UICollectionViewLayoutAttributes>()
    for (i, boardRect) in boardRects.enumerate() {
      if (CGRectIntersectsRect(rect, boardRect)) {
        let indexPath = NSIndexPath(forItem:i, inSection:SectionType.Board.rawValue)
        if let localAttributes = self.layoutAttributesForItemAtIndexPath(indexPath) {
          attributes.append(localAttributes)
        }
      }
    }
    for (i, peiceRect) in peiceRects.enumerate() {
      if (CGRectIntersectsRect(rect, peiceRect)) {
        let indexPath = NSIndexPath(forItem:i, inSection:SectionType.Piece.rawValue)
        if let localAttributes = self.layoutAttributesForItemAtIndexPath(indexPath) {
          attributes.append(localAttributes)
        }
      }
    }
    return attributes
  }
  
  override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    if (indexPath.section == SectionType.Board.rawValue) {
      guard let boardRects = self.boardRects else {
        return nil
      }
      let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
      attributes.frame = boardRects[indexPath.item]
      return attributes;
    } else {
      guard let peiceRects = self.peiceRects else {
        return nil
      }
      let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
      attributes.frame = peiceRects[indexPath.item]
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
    collectionView.backgroundColor = UIColor.whiteColor()
    collectionView.registerClass(ChessBoardCell.self, forCellWithReuseIdentifier: ChessBoardCell.reuseIdentifier)
    collectionView.registerClass(ChessPieceCell.self, forCellWithReuseIdentifier: ChessPieceCell.reuseIdentifier)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
    
  /// Mark: UICollectionViewDataSource
    
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return SectionType.Count.rawValue;
  }
    
  override func collectionView(collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    let gameController = self.game.gameController
    if section == SectionType.Board.rawValue {
      return Int(gameController.boards * gameController.boardHeight * gameController.boardWidth)
    } else {
      return gameController.pieces.count;
    }
  }
  
  override func collectionView(collectionView: UICollectionView,
                               cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    if (indexPath.section == SectionType.Board.rawValue) {
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ChessBoardCell.reuseIdentifier, forIndexPath: indexPath)
      let gameController = self.game.gameController
      let column = UInt(indexPath.item) % gameController.boardWidth;
      let row = (UInt(indexPath.item) - column) / gameController.boardHeight
      cell.contentView.backgroundColor = ((row + column) % 2 == 0) ? UIColor(white: 0.95, alpha: 1) : UIColor(white: 0.9, alpha: 1)
      return cell
    } else {
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ChessPieceCell.reuseIdentifier, forIndexPath: indexPath)
      let pieceCell = cell as! ChessPieceCell
      let piece = self.game.gameController.pieces[indexPath.item]
      pieceCell.designation = kPrettyDesignations[String(piece.type)]
      pieceCell.teamColor = piece.player.colour == "B" ? UIColor.blueColor() : UIColor.redColor()
      return cell
    }
  }
  
  /// Mark: UICollectionViewDelegate
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    NSLog("\(indexPath)")
  }
}
