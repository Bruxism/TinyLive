#Enable colors in bash
echo "export TERM=xterm-256color" >> ~/.bashrc


#Enable History, mouse, and color in Tmux
cat << EOF >> ~/.tmux.conf
set -g history-file ~/.tmux_history
set -g mouse on

set -g default-terminal "tmux-256color"
set-option -sa terminal-overrides ",xterm*:Tc"
EOF




#Enable color, mouse, and Dracula Theme in VIM
#Requires 'git' package and Dracula theme

mkdir -p ~/.vim/pack/themes/start
cd ~/.vim/pack/themes/start
git clone https://github.com/dracula/vim.git dracula

cat << EOF >> ~/.vim/vimrc
syntax enable
set termguicolors
set background=dark
colorscheme dracula

set mouse=a
EOF


#Automatic history syncing for each prompt
cat << EOF >> ~/.bashrc
shopt -s histappend
PROMPT_COMMAND='history -a; history -n'
export HISTSIZE=500000
export HISTFILESIZE=500000
EOF

#Set preferred aliases
cat << EOF >> ~/.bash_aliases
alias ls='ls --color=always -h --group-directories-first'
EOF
