---
title: "Game of Life"
author: "T S Robinson"
date: "03/01/2021"
output: 
  html_document: 
    keep_md: yes
---



![](tsr_short.gif)

This is an R implementation of John Conway's Game of Life (GoL) simulation.

The game is played on a two-dimensional matrix where every cell is either 'alive' or 'dead'. During each round of the game (epoch), the following rules are applied simultaneously to each cell:

1. If a cell is 'alive' and surrounded (horizontally, vertically, or diagonally) by 2 or 3 live cells, then it survives into the next epoch
2. If a cell is currently 'dead' but surrounded by 2 live cells, then it becomes alive in the next epoch
3. Otherwise, cells become/remain dead

The game must be seeded by presenting a starting array of dead and alive cells. For example, we can load my initials as a series of live cells into a $25 \times 25$ grid, convert to a matrix, then plot (black squares indicate alive cells):


```r
seeding <- read_csv("gol_tsr.csv", col_names = FALSE)
```

```
## 
## ── Column specification ────────────────────────────────────────────────────────
## cols(
##   .default = col_double()
## )
## ℹ Use `spec()` for the full column specifications.
```

```r
# Remove names 
names(seeding) <- NULL
rownames(seeding) <- NULL
board_seeded <- as.matrix(seeding)

# Plot initial game board
plot_board(board_seeded)
```

![](README_files/figure-html/seed-1.png)<!-- -->

## Running GoL

The mechanics behind this implementation of the GoL can be found in `functions.R`.

Here, we simply run the game for 150 epochs (i.e. 150 successive applications of the rules listed above). The `run_game` function returns a list of the board states after each epoch. The `animate_game` function converts and saves this list of matrices as a gif. 


```r
# Play the game for 120 epochs
tsr <- run_game(board_seeded, epochs = 150)
```

```
## 
##  End of game!
```

```r
# Animate the game
tsr_gif <- animate_game(tsr,
                        name = "tsr.gif", 
                        initial_board = board_seeded)
```

And here's the full result: 

![](tsr.gif)

