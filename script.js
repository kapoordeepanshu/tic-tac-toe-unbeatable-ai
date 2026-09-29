(() => {
  const LINES = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6],            // diagonals
  ];
  const HUMAN = 'X';
  const CPU = 'O';
  const STORAGE_KEY = 'tictactoe-state';

  const cells = [...document.querySelectorAll('.cell')];
  const statusEl = document.getElementById('status');
  const difficultyEl = document.querySelector('.difficulty');
  const scoreEls = {
    X: document.getElementById('score-x'),
    O: document.getElementById('score-o'),
    draw: document.getElementById('score-draw'),
  };
  const labelX = document.getElementById('label-x');
  const labelO = document.getElementById('label-o');

  let board = Array(9).fill(null);
  let current = 'X';
  let gameOver = false;
  let startingPlayer = 'X';
  let cpuTimer = null;

  const settings = { mode: 'pvp', level: 'hard' };
  let scores = { X: 0, O: 0, draw: 0 };

  // ---------- Persistence ----------
  function load() {
    try {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
      if (saved) {
        Object.assign(settings, saved.settings);
        Object.assign(scores, saved.scores);
      }
    } catch { /* storage unavailable — start fresh */ }
  }

  function save() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ settings, scores }));
    } catch { /* ignore */ }
  }

  // ---------- Game logic ----------
  function getWinner(b) {
    for (const line of LINES) {
      const [a, c, d] = line;
      if (b[a] && b[a] === b[c] && b[a] === b[d]) return { player: b[a], line };
    }
    return b.every(Boolean) ? { player: 'draw', line: [] } : null;
  }

  function emptyCells(b) {
    return b.reduce((acc, v, i) => (v ? acc : [...acc, i]), []);
  }

  // Minimax with depth so the CPU prefers faster wins and slower losses.
  function minimax(b, player, depth) {
    const result = getWinner(b);
    if (result) {
      if (result.player === CPU) return { score: 10 - depth };
      if (result.player === HUMAN) return { score: depth - 10 };
      return { score: 0 };
    }

    let best = { score: player === CPU ? -Infinity : Infinity, index: null };
    for (const i of emptyCells(b)) {
      b[i] = player;
      const { score } = minimax(b, player === CPU ? HUMAN : CPU, depth + 1);
      b[i] = null;
      if (player === CPU ? score > best.score : score < best.score) {
        best = { score, index: i };
      }
    }
    return best;
  }

  function cpuMove() {
    const options = emptyCells(board);
    // Easy mode: random move most of the time, occasionally a smart one.
    if (settings.level === 'easy' && Math.random() < 0.7) {
      return options[Math.floor(Math.random() * options.length)];
    }
    return minimax([...board], CPU, 0).index;
  }

  function play(index) {
    if (gameOver || board[index]) return;
    board[index] = current;

    const result = getWinner(board);
    if (result) {
      endGame(result);
    } else {
      current = current === 'X' ? 'O' : 'X';
    }
    render();

    if (!gameOver && isCpuTurn()) scheduleCpu();
  }

  function isCpuTurn() {
    return settings.mode === 'cpu' && current === CPU;
  }

  function scheduleCpu() {
    clearTimeout(cpuTimer);
    cpuTimer = setTimeout(() => play(cpuMove()), 400);
  }

  function endGame(result) {
    gameOver = true;
    scores[result.player]++;
    result.line.forEach((i) => cells[i].classList.add('win'));
    save();
  }

  function newRound() {
    clearTimeout(cpuTimer);
    board = Array(9).fill(null);
    gameOver = false;
    // Alternate who starts each round for fairness.
    startingPlayer = startingPlayer === 'X' ? 'O' : 'X';
    current = startingPlayer;
    cells.forEach((c) => c.classList.remove('win'));
    render();
    if (isCpuTurn()) scheduleCpu();
  }

  // ---------- Rendering ----------
  // pathLength="1" lets CSS animate the stroke drawing regardless of size.
  const MARKS = {
    X: '<svg class="mark mark-x" viewBox="0 0 100 100" aria-hidden="true">'
      + '<path d="M18 18 L82 82" pathLength="1"/><path d="M82 18 L18 82" pathLength="1"/></svg>',
    O: '<svg class="mark mark-o" viewBox="0 0 100 100" aria-hidden="true">'
      + '<circle cx="50" cy="50" r="34" pathLength="1" transform="rotate(-90 50 50)"/></svg>',
  };
  function nameOf(player) {
    if (settings.mode === 'cpu') return player === HUMAN ? 'You' : 'Computer';
    return `Player ${player}`;
  }

  function render() {
    const cpuThinking = !gameOver && isCpuTurn();

    cells.forEach((cell, i) => {
      const value = board[i];
      // Only touch the DOM when a cell changes so the draw animation plays once.
      if (cell.dataset.value !== (value || '')) {
        cell.innerHTML = value ? MARKS[value] : '';
        cell.dataset.value = value || '';
      }
      cell.classList.toggle('filled', Boolean(value));
      cell.disabled = gameOver || Boolean(value) || cpuThinking;
      cell.setAttribute('aria-label', `Cell ${i + 1}${value ? `, ${value}` : ', empty'}`);
    });

    const result = getWinner(board);
    if (result && result.player === 'draw') {
      statusEl.textContent = "It's a draw!";
    } else if (result) {
      const who = nameOf(result.player);
      statusEl.textContent = who === 'You' ? 'You win!' : `${who} wins!`;
    } else if (cpuThinking) {
      statusEl.textContent = 'Computer is thinking…';
    } else {
      statusEl.textContent = settings.mode === 'cpu' ? 'Your turn (X)' : `${current}'s turn`;
    }

    statusEl.classList.toggle('win', Boolean(result && result.player !== 'draw'));
    // Drives the X/O mouse cursor; cleared when nobody can move.
    document.body.dataset.turn = !result && !cpuThinking ? current.toLowerCase() : '';
    document.querySelector('.score.x').classList.toggle('turn', !result && current === 'X');
    document.querySelector('.score.o').classList.toggle('turn', !result && current === 'O');

    scoreEls.X.textContent = scores.X;
    scoreEls.O.textContent = scores.O;
    scoreEls.draw.textContent = scores.draw;
    labelX.textContent = nameOf('X');
    labelO.textContent = nameOf('O');

    difficultyEl.classList.toggle('hidden', settings.mode !== 'cpu');
    syncSegmented('[data-mode]', 'mode', settings.mode);
    syncSegmented('[data-level]', 'level', settings.level);
  }

  function syncSegmented(selector, key, value) {
    document.querySelectorAll(selector).forEach((btn) => {
      const on = btn.dataset[key] === value;
      btn.classList.toggle('active', on);
      btn.setAttribute('aria-checked', String(on));
    });
  }

  function resetMatch() {
    scores = { X: 0, O: 0, draw: 0 };
    startingPlayer = 'O'; // newRound flips this so X starts
    save();
    newRound();
  }

  // ---------- Events ----------
  cells.forEach((cell) => {
    cell.addEventListener('click', () => play(Number(cell.dataset.index)));
  });

  document.querySelectorAll('[data-mode]').forEach((btn) => {
    btn.addEventListener('click', () => {
      if (settings.mode === btn.dataset.mode) return;
      settings.mode = btn.dataset.mode;
      resetMatch(); // scores don't carry across modes
    });
  });

  document.querySelectorAll('[data-level]').forEach((btn) => {
    btn.addEventListener('click', () => {
      if (settings.level === btn.dataset.level) return;
      settings.level = btn.dataset.level;
      resetMatch();
    });
  });

  document.getElementById('new-round').addEventListener('click', newRound);
  document.getElementById('reset-score').addEventListener('click', resetMatch);

  load();
  render();
})();
