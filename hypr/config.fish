
source /usr/share/cachyos-fish-config/cachyos-config.fish

oh-my-posh init fish --config ~/.config/oh-my-posh/themes/catppuccin_mocha.omp.json | source

alias f='fastfetch'

# Make the command 'clear' use this function
alias clear="printf '\033[3J\033[H\033[2J'"
alias conf="cd ~/.config"
alias script="cd ~/Scripts"

# ------------------------
# Bibata Modern Classic cursor (for Hyprland + XWayland)
# ------------------------
# set -x XCURSOR_THEME "Bibata-Modern-Classic"
# set -x XCURSOR_SIZE 24
# set -x HYPRCURSOR_THEME "Bibata-Modern-Classic"
# set -x HYPRCURSOR_SIZE 24

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
