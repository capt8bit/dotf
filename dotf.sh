#! /bin/sh -
#
# Copyright (c) 2019, Michael Monsivais
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

_dotf_cmd() {
	if [ "$#" -lt 2 ]; then
		return 1
	fi
	git_dir="$1"; shift
	git --work-tree "$HOME/" --git-dir "$git_dir" "$@"
	unset git_dir
}

_dotf_del() {
	while getopts r OPT; do
		case "$OPT" in
			r)
				RMFILES=1
				;;
			?)
				return 2
				;;
		esac
	done
	shift $(($OPTIND - 1))
	name="$1"

	if [ -z "$name" ] || [ ! -d "$DOTF_DIR/$name" ]; then
		return 1
	fi

	if [ -n "$RMFILES" ]; then
		_dotf_cmd "$DOTF_DIR/$name" rm -f -r "$HOME"
	fi

	rm -rf "$DOTF_DIR/${name:?Over-cautiously not removing anything.}"
	unset OPT RMFILES name
}

_dotf_error() {
	printf '%s\n' "$@"
	return 1
}

_dotf_install() {
	if [ "$#" -lt 2 ]; then
		return 1
	fi
	src="$1"
	name="$2"
	_dotf_cmd "$DOTF_DIR/$name" clone --bare "$src" "$DOTF_DIR/$name"
	_dotf_cmd "$DOTF_DIR/$name" config --local status.showUntrackedFiles no
	_dotf_cmd "$DOTF_DIR/$name" checkout -f
	unset src name
}

_dotf_new() {
	name="$1"
	if [ -z "$name" ] || [ -d "$DOTF_DIR/$name" ]; then
		return 1
	fi
	_dotf_cmd "$DOTF_DIR/$name" init
	_dotf_cmd "$DOTF_DIR/$name" config --local status.showUntrackedFiles no
	unset name
}

_dotf_use() {
	name="$1"
	if [ -z "$name" ] || [ ! -d "$DOTF_DIR/$name" ]; then
		return 1
	fi
	export DOTF_REPO="$name"
	unset name
}

dotf() {
	: "${DOTF_REPO="default"}"
	: "${DOTF_DIR="$HOME/.dotfiles"}"

	if [ ! -d "$DOTF_DIR" ]; then
		printf 'Creating dotfile directory: %s\n' "$DOTF_DIR"
		mkdir -p "$DOTF_DIR"
	fi

	case "$1" in
		'')
			printf '%s\n' "$DOTF_REPO"
			;;
		-h)
			cat <<-'EOF'
				dotf [command] [repo|git-repo|git-args]

				dotf accepts all git(1) commands, and the following custom commands:

				dotf                          Show the currently used repository
				dotf del [-d] repo            Delete a repository
				dotf install git-repo repo    Install a git repository as an available dotf repository
				dotf list                     List available dotf repositories
				dotf new repo                 Create a git repo in the respository directory
				dotf use repo                 Set the active dotf repository
			EOF
			;;
		del)
			shift
			_dotf_del "$@"
			case "$?" in
				0)
					;;
				1)
					_dotf_error 'No such repository'
					;;
				2)
					_dotf_error 'Invalid flag'
					;;
			esac
			;;
		install)
			shift
			_dotf_install "$@" || _dotf_error 'Missing arguments'
			;;
		list)
			ls -1 "$DOTF_DIR"
			;;
		new)
			shift
			_dotf_new "$@" || _dotf_error 'Missing or invalid argument'
			;;
		use)
			shift
			_dotf_use "$@" || _dotf_error 'No such repository'
			;;
		*)
			_dotf_cmd "$DOTF_DIR/$DOTF_REPO" "$@"
			;;
	esac
}
