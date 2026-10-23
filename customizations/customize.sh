#Enable colors in bash
echo "export TERM=xterm-256color" >> ~/.bashrc


#Enable History, mouse, and color in tmux
cat << 'EOF' >> ~/.tmux.conf
set -g history-file ~/.tmux_history
set -g mouse on

set -g default-terminal "tmux-256color"
set-option -sa terminal-overrides ",xterm*:Tc"

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-processes 'watch'

# Always keep on bottom:
run '~/.tmux/plugins/tpm/tpm'
EOF

#Install tmux plugins
#`gawk` needs to be installed for this to work
#	See: https://github.com/tmux-plugins/tpm/issues/325
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins


#Enable color, mouse, and Dracula Theme in VIM
#Requires 'git' package and Dracula theme

mkdir -p ~/.vim/pack/themes/start
cd ~/.vim/pack/themes/start
git clone https://github.com/dracula/vim.git dracula

cat << EOF >> ~/.vim/vimrc
set mouse=a

set tabstop=2
set autoindent
set hlsearch

set termguicolors
set background=dark
syntax enable
packadd! dracula
colorscheme dracula
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
alias less='less --mouse'
EOF
