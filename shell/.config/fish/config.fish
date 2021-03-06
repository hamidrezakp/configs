abbr -a c cargo
abbr -a e nvim
abbr -a vim nvim
abbr -a o xdg-open
abbr -a g git
abbr -a gc 'git checkout'
abbr -a ga 'git add -p'
abbr -a vimdiff 'nvim -d'
abbr -a ct 'cargo t'
abbr -a gah 'git stash; and git pull --rebase; and git stash pop'
abbr -a pr 'gh pr create -t (git show -s --format=%s HEAD) -b (git show -s --format=%B HEAD | tail -n+3)'
complete --command yay --wraps pacman

if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
			exec startx
    end
end

if status --is-interactive
	if test -d ~/dev/others/base16/templates/fish-shell
		set fish_function_path $fish_function_path ~/dev/others/base16/templates/fish-shell/functions
		builtin source ~/dev/others/base16/templates/fish-shell/conf.d/base16.fish
	end
	if test -z "$TMUX"
		set ID ( tmux ls | grep -vm1 attached | cut -d: -f1 ) # get the id of a deattached session
		if test -z $ID # if not available create a new one
			exec tmux new-session
		else
			exec tmux attach-session -t $ID # if available attach to it
		end
	end
end

if command -v yay > /dev/null
	abbr -a p 'yay'
	abbr -a up 'yay -Syu'
else
	abbr -a p 'sudo pacman'
	abbr -a up 'sudo pacman -Syu'
end

if command -v exa > /dev/null
	abbr -a l 'exa'
	abbr -a ls 'exa'
	abbr -a ll 'exa -l'
	abbr -a lll 'exa -la'
else
	abbr -a l 'ls'
	abbr -a ll 'ls -l'
	abbr -a lll 'ls -la'
end

if test -f /usr/share/autojump/autojump.fish;
	source /usr/share/autojump/autojump.fish;
end

function ssh
	switch $argv[1]
	case "*.amazonaws.com"
		env TERM=xterm /usr/bin/ssh $argv
	case "ubuntu@"
		env TERM=xterm /usr/bin/ssh $argv
	case "*"
		/usr/bin/ssh $argv
	end
end

function apass
	if test (count $argv) -ne 1
		pass $argv
		return
	end

	asend (pass $argv[1] | head -n1)
end

function qrpass
	if test (count $argv) -ne 1
		pass $argv
		return
	end

	qrsend (pass $argv[1] | head -n1)
end

function asend
	if test (count $argv) -ne 1
		echo "No argument given"
		return
	end

	adb shell input text (echo $argv[1] | sed -e 's/ /%s/g' -e 's/\([[()<>{}$|;&*\\~"\'`]\)/\\\\\1/g')
end

function qrsend
	if test (count $argv) -ne 1
		echo "No argument given"
		return
	end

	qrencode -o - $argv[1] | feh --geometry 500x500 --auto-zoom -
end

function limit
	numactl -C 0,1,2 $argv
end

function remote_alacritty
	# https://gist.github.com/costis/5135502
	set fn (mktemp)
	infocmp alacritty > $fn
	scp $fn $argv[1]":alacritty.ti"
	ssh $argv[1] tic "alacritty.ti"
	ssh $argv[1] rm "alacritty.ti"
end

function remarkable
	if test (count $argv) -lt 1
		echo "No files given"
		return
	end

	ip addr show up to 10.11.99.0/29 | grep enp2s0f0u3 >/dev/null
	if test $status -ne 0
		# not yet connected
		echo "Connecting to reMarkable internal network"
		sudo dhcpcd enp2s0f0u3
	end
	for f in $argv
		echo "-> uploading $f"
		curl --form "file=@\""$f"\"" http://10.11.99.1/upload
		echo
	end
	sudo dhcpcd -k enp2s0f0u3
end

# Type - to move up to top parent dir which is a repository
function d
	while test $PWD != "/"
		if test -d .git
			break
		end
		cd ..
	end
end

# Fish git prompt
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate ''
set __fish_git_prompt_showupstream 'none'
set -g fish_prompt_pwd_dir_length 3

# colored man output
# from http://linuxtidbits.wordpress.com/2009/03/23/less-colors-for-man-pages/
setenv LESS_TERMCAP_mb \e'[01;31m'       # begin blinking
setenv LESS_TERMCAP_md \e'[01;38;5;74m'  # begin bold
setenv LESS_TERMCAP_me \e'[0m'           # end mode
setenv LESS_TERMCAP_se \e'[0m'           # end standout-mode
setenv LESS_TERMCAP_so \e'[38;5;246m'    # begin standout-mode - info box
setenv LESS_TERMCAP_ue \e'[0m'           # end underline
setenv LESS_TERMCAP_us \e'[04;38;5;146m' # begin underline

setenv FZF_DEFAULT_COMMAND 'fd --type file --follow'
setenv FZF_CTRL_T_COMMAND 'fd --type file --follow'
setenv FZF_DEFAULT_OPTS '--height 20%'

setenv EDITOR 'nvim'

abbr -a nova 'env OS_PASSWORD=(pass www/mit-openstack | head -n1) nova'
abbr -a glance 'env OS_PASSWORD=(pass www/mit-openstack | head -n1) glance'

#setenv OS_USERNAME jfrg@csail.mit.edu
#setenv OS_TENANT_NAME usersandbox_jfrg
#setenv OS_AUTH_URL https://nimbus.csail.mit.edu:5001/v2.0
#setenv OS_IMAGE_API_VERSION 1
#setenv OS_VOLUME_API_VERSION 2

function penv -d "Set up environment for the PDOS openstack service"
	env OS_PASSWORD=(pass www/mit-openstack | head -n1) OS_TENANT_NAME=pdos OS_PROJECT_NAME=pdos $argv
end
function pvm -d "Run nova/glance commands against the PDOS openstack service"
	switch $argv[1]
	case 'image-*'
		penv glance $argv
	case 'c'
		penv cinder $argv[2..-1]
	case 'g'
		penv glance $argv[2..-1]
	case '*'
		penv nova $argv
	end
end

# Fish should not add things to clipboard when killing
# See https://github.com/fish-shell/fish-shell/issues/772
set FISH_CLIPBOARD_CMD "cat"

function fish_user_key_bindings
	bind \cz 'fg>/dev/null ^/dev/null'
	if functions -q fzf_key_bindings
		fzf_key_bindings
	end
	fish_default_key_bindings -M insert
	fish_vi_key_bindings insert
end

function fish_prompt
	set_color blue
	if [ $PWD != $HOME ]
		set_color brblack
		echo -n ':'
		set_color yellow
		echo -n (basename $PWD)
	end
	set_color green
	printf '%s ' (__fish_git_prompt)
	set_color red
	echo -n '> '
	set_color normal
end

function fish_mode_prompt
	switch $fish_bind_mode
		case default
			set_color --bold red
			echo ' N '
		case insert
			set_color --bold brblack
			echo ' I '
		case replace_one
			set_color --bold green
			echo ' R '
		case visual
			set_color --bold brmagenta
			echo ' V '
		case '*'
			set_color --bold red
			echo ' ? '
	end
end


function fish_greeting
end
