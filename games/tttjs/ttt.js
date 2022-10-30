var ttt = {
  // (A) RESET THE GAME
  board : [], // array to hold the current game
  reset : () => {
    let container = document.getElementById("ttt-game");
    container.innerHTML = "";
    ttt.board = [];
    for (let id=0; id<9; id++) {
      let square = document.createElement("div");
      square.innerHTML = "&nbsp;";
      square.id = "ttt-" + id;
      square.onclick = () => { ttt.play(id); };
      container.appendChild(square);
      ttt.board.push(null);
    }
  },

  // (B) HELPER FUNCTION - SET "O" OR "X" ON A SQUARE
  // PLAYER IS "O", COMPUTER IS "X"
  //  id : target square
  //  by : 0 for player, 1 for computer
  set : (id, by) => {
    let square = document.getElementById("ttt-"+id);
    square.innerHTML = by==0 ? "O" : "X" ;
    square.classList.add((by==0 ? "player" : "computer"));
    square.onclick = "";
    ttt.board[id] = by;
  },

  // (C) PLAY - WHEN THE PLAYER SELECTS A SQUARE
  //  id : id of chosen square
  play : (id) => {
    // (C1) PLAYER'S MOVE - MARK SQUARE WITH "O"
    ttt.set(id, 0);

    // (C2) NO MORE MOVES AVAILABLE - NO WINNER
    if (ttt.board.indexOf(null) == -1) {
      alert("No winner");
      ttt.reset();
    }

    // (C3) COMPUTER'S MOVE - MARK SQUARE WITH "X"
    else { ttt.set(ttt.dumbAI(), 1); }
    // else { ttt.set(ttt.notBadAI(), 1); } // USE NOT BAD AI IF YOU WANT

    // (C4) WHO WON?
    win = null;

    // (C4-1) HORIZONTAL ROW CHECKS
    for (let i=0; i<9; i+=3) {
      if (ttt.board[i]!=null && ttt.board[i+1]!=null && ttt.board[i+2]!=null) {
        if ((ttt.board[i] == ttt.board[i+1]) && (ttt.board[i+1] == ttt.board[i+2])) { win = ttt.board[i]; }
      }
      if (win !== null) { break; }
    }

    // (C4-2) VERTICAL ROW CHECKS
    if (win === null) {
      for (let i=0; i<3; i++) {
        if (ttt.board[i]!=null && ttt.board[i+3]!=null && ttt.board[i+6]!=null) {
          if ((ttt.board[i] == ttt.board[i+3]) && (ttt.board[i+3] == ttt.board[i+6])) { win = ttt.board[i]; }
          if (win !== null) { break; }
        }
      }
    }

    // (C4-3) DIAGONAL ROW CHECKS
    if (win === null) {
      if (ttt.board[0]!=null && ttt.board[4]!=null && ttt.board[8]!=null) {
        if ((ttt.board[0] == ttt.board[4]) && (ttt.board[4] == ttt.board[8])) { win = ttt.board[4]; }
      }
    }
    if (win === null) {
      if (ttt.board[2]!=null && ttt.board[4]!=null && ttt.board[6]!=null) {
        if ((ttt.board[2] == ttt.board[4]) && (ttt.board[4] == ttt.board[6])) { win = ttt.board[4]; }
      }
    }

    // (C4-4) WE HAVE A WINNER
    if (win !== null) {
      alert("WINNER - " + (win==0 ? "Player" : "Computer"));
      ttt.reset();
    }
  },

  // (D) DUMB COMPUTER AI, RANDOMLY CHOOSES AN OPEN SLOT
  dumbAI : () => {
    let open = [];
    for (let i=0; i<9; i++) { if (ttt.board[i] === null) { open.push(i); }}
    return open[(Math.floor(Math.random() * (open.length-1)))];
  },

  // (E) AI WITH A LITTLE MORE INTELLIGENCE
  notBadAI : () => {
    // (E1) HELPER FUNCTION, CHECK POSSIBLE WINNING ROW
    //  first : first square number
    //  direction : "R"ow, "C"ol, "D"iagonal
    //  pc : 0 for player, 1 for computer
    let check = (first, direction, pc) => {
      let second = 0, third = 0;
      if (direction=="R") {
        second = first + 1;
        third = first + 2;
      } else if (direction=="C") {
        second = first + 3;
        third = first + 6;
      } else {
        second = 4;
        third = first==0 ? 8 : 6;
      }

      if (ttt.board[first]===null && ttt.board[second]==pc && ttt.board[third]==pc) {
        return first;
      } else if (ttt.board[first]==pc && ttt.board[second]===null && ttt.board[third]==pc) {
        return second;
      } else if (ttt.board[first]==pc && ttt.board[second]==pc && ttt.board[third]===null) {
        return third;
      }
      return null;
    };

    // (E2) PRIORITY #1 - GO FOR THE WIN
    let move = null;

    // (E2-1) CHECK HORIZONTAL ROWS
    for (let i=0; i<9; i+=3) {
      move = check(i, "R", 1);
      if (move!==null) { return move; }
    }

    // (E2-2) CHECK VERTICAL COLUMNS
    for (let i=0; i<3; i++) {
      move = check(i, "C", 1);
      if (move!==null) { return move; }
    }

    // (E2-3) CHECK DIAGONAL
    move = check(0, "D", 1); if (move!==null) { return move; }
    move = check(2, "D", 1); if (move!==null) { return move; }

    // (E3) PRIORITY #2 - BLOCK PLAYER FROM WINNING
    // (E3-1) CHECK HORIZONTAL ROWS
    for (let i=0; i<9; i+=3) {
      move = check(i, "R", 0);
      if (move!==null) { return move; }
    }

    // (E3-2) CHECK VERTICAL COLUMNS
    for (let i=0; i<3; i++) {
      move = check(i, "C", 0);
      if (move!==null) { return move; }
    }

    // (E3-3) CHECK DIAGONAL
    move = check(0, "D", 0); if (move!==null) { return move; }
    move = check(2, "D", 0); if (move!==null) { return move; }

    // (E4) RANDOM MOVE IF NOTHING
    return ttt.dumbAI();
  }
};
window.addEventListener("load", ttt.reset);
