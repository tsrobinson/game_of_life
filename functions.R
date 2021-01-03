#### 0. INITIALISATION ####

library(tidyverse)
library(reshape2)
library(parallel)
library(gganimate)

seed_board <- function(cols, rows, p) {
  # Create a randomly seeded board with dims [rows, cols]
  # p determines the proportion of 'alive' cells in the matrix
  
  draw <- rbinom(prod(c(cols,rows)),1, p)
  
  seeded <- matrix(draw, nrow = rows)
  cat("Non-empty squares: ", sum(draw),"\n")
  
  return(seeded)
}

plot_board <- function(board, melt = TRUE) {
  # Plots a single instance of the board
  # melt determines whether to process the baord into long form
  
  if (melt) {
    board <- melt(board) %>% 
      mutate(value = factor(value, levels = c(0,1)))
  }
  
  ggplot(board, aes(x = Var2, y = Var1, fill = value)) +
    scale_fill_manual(values = c("white", "black")) + 
    # scale_color_manual(values = c("black", "white")) + 
    geom_tile() +
    labs(x = "", y = "") +
    theme_bw() +
    theme(axis.text = element_blank(),
          axis.ticks = element_blank(),
          panel.grid = element_blank(),
          panel.border = element_blank(),
          plot.title = element_text(hjust = 0.5)) + 
    guides(fill = FALSE, color = FALSE) + 
    scale_x_discrete(expand = c(0,0)) + 
    scale_y_reverse(expand = c(0,0)) %>% 
    return(.)
  
}

#### 1. RULES ####

is_alive <- function(cell) {
  # Convenience function to determine state of cell
  
  ifelse(cell == 1, TRUE, FALSE)
}

neighbouring <- function(x,y, board) {
  
  # Return number of alive cells neighbouring given x,y coordinates
  
  neighbours <- expand.grid(
    
    max(x-1,1):min(x+1,dim(board)[2]),
    max(y-1,1):min(y+1,dim(board)[2])
    
  ) %>% filter(!(Var1 == x & Var2 == y))
  
  n_alive <- apply(
    
    neighbours, 1,
    
    function(x) {
      
      is_alive(board[x[1],x[2]])
      
    }) %>% sum(.)
  
}

ruling <- function(x, y, board) {
  
  # Apply GoL rules to cell in position board[x,y]
  
  alive_neighbours <- neighbouring(x, y, board)
  
  if (is_alive(board[x, y])) { # Alive cells
    
    if (alive_neighbours %in% c(2,3)) {
      return(1)
    } else {
      return(0)
    }
    
  } else { # Dead cells
    
    if (alive_neighbours == 3) {
      return(1)
    } else {
      return(0)
    }
  }
}

#### 2. RUN GAME ####

epoch <- function(board) {
  
  # Apply ruling across all cells on board
  
  cells <- expand.grid(1:dim(board)[1], 1:dim(board)[2]) %>% 
    split(., seq(nrow(.)))
  
  new_values <- unlist(mclapply(cells, function (x) ruling(x[[1]], x[[2]], board),
                         mc.cores = 4))
  
  new_board <- matrix(new_values, nrow = dim(board)[1])
  
  return(new_board)
  
}

run_game <- function(board, epochs) {
  
  # Simulate game for n epochs
  
  board_epochs <- list()
  board_epochs[[1]] <- epoch(board)
  
  counter <- floor(epochs/10)*c(1:10)
  
  
  
  for (i in 2:epochs) {
    
    # Progress bar
    cat("\rEpoch: ",i," | ",
        paste0(rep("=", each = sum(i > counter)), collapse = ""),">",
        "(",round(100*i/epochs),"%)")
    
    # Run simulation on result of previous epoch
    board_epochs[[i]] <- epoch(board_epochs[[i-1]])
  }
  cat("\n End of game!\n")
  
  return(board_epochs)
  
}

#### 3. ANIMATE ####

animate_game <- function(game, name, initial_board = NULL, delay = TRUE) {
  
  # 
  
  epochs_long <- mclapply(game, function(x) {
    
    melt(x) %>% 
      select(Var1, Var2, value) %>% 
      mutate(value = factor(value, levels = c(0,1)))
    
  }) %>% 
    do.call("rbind",.) %>% 
    mutate(epoch = rep(1:length(game), each = prod(dim(game[[1]]))))
  
  if (!is.null(initial_board)) {
    epochs_long <- rbind(
      
      epochs_long,
      {melt(initial_board) %>% 
          mutate(value = factor(value, levels = c(0,1)),
                 epoch = 0)}
      
    )
  }
  
  anim_plot <- plot_board(epochs_long, melt = FALSE) + 
    transition_time(epoch) +
    labs(title = "Epoch: {frame_time}")
    
  anim_save(animation = anim_plot, 
            name,
            nframes = length(unique(epochs_long$epoch)) + ifelse(delay, 4, 0), 
            fps = 7,
            start_pause = ifelse(delay, 4, 0))
}
 

