# Configuration for popup window in tmux
set -g @popup_width 80
set -g @popup_height 80
set -g @popup_window_name "popup"

# Function to toggle a popup window session
popup_window() {
  if [ "$(tmux display-message -p -F "#{session_name}")" = "$(tmux show -gqv @popup_window_name)" ]; then
    tmux detach-client
  else
    tmux popup -d '#{pane_current_path}' -xC -yC -w "$(tmux show -gqv @popup_width)" -h "$(tmux show -gqv @popup_height)" -E "tmux attach -t $(tmux show -gqv @popup_window_name) || tmux new -s $(tmux show -gqv @popup_window_name)"
  fi
}
