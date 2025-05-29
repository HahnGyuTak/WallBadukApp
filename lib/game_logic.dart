enum Player { none, playerA, playerB }

class Cell {
  Player owner = Player.none;
  bool hasPiece = false;

  Cell();
}