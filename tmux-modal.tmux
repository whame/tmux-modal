#!/usr/bin/env bash

# SPDX-License-Identifier: MIT

set -euo pipefail

# Check Bash version. We use features introduced in Bash 4.0.
if [ ${BASH_VERSINFO[0]} -lt 4 ]; then
    echo "ERROR: Bash version is too old." \
         "Please upgrade to version 4.0 or newer"
    exit 95
fi

unbind() {
    readarray -t BINDINGS <<< $(tmux list-keys | grep -E "$1" || true)
    for line in "${BINDINGS[@]}"; do
        if [ -z "$line" ]; then
            continue
        fi

        local lineArr=($line)
        local kt=${lineArr[2]}
        local kbd=${lineArr[3]}

        # Check if keybinding contains any "special" characters.
        case "$kbd" in
            '"'*'"')
                # Keybindings that contain characters that need to be escaped,
                # are quoted in the output of `tmux list-keys`. For example,
                # `M-#` and `M-$` are listed as `"M-#"` and `"M-$"`. Before
                # giving it to `tmux unbind-key`, we therefore need to strip the
                # surrounding quotes.
                kbd=$(sed -e 's/^"\(.\+\)"$/\1/' <<< "$kbd")
                ;;&
            *"\\"*)
                # Some characters are escaped as well, e.g. `M-"`, `#` and `$`
                # are listed as `"M-\""`, `\#` and `\$`, respectively.
                # Backslashes needs to be removed before running `tmux
                # unbind-key`.
                kbd=$(sed -e "s/\\\\\(.\)/\1/g" <<< "$kbd")
                ;;&
            *";"*)
                # Semicolons are escaped and they need to be that for `tmux
                # unbind-key`. Above we removed all backslashes, therefore we
                # add it here for this special character.
                # TODO: Are there any other special characters that need to be
                # escaped?
                kbd=$(sed -e "s/;/\\\\;/g" <<< "$kbd")
                ;;
        esac

        tmux unbind-key -T $kt $kbd
    done
}

parse_yn_opt() {
    if [ "$1" != on ] && [ "$1" != off ]; then
        echo Option "\"$2\"": Invalid value \""$1"\"
        echo Valid values are \"on\" or \"off\"
        return 22
    fi
}

# The "START/END KEYBINDINGS" comment lines are parsed by the Makefile to
# auto-generate the default user configuration file.

# START KEYBINDINGS
# These are the default keybindings for tmux-modal. This file will be used by
# the main script `tmux-modal.tmux` when tmux loads. Users can however load
# their own custom keybindings file by copying this file, make any changes and
# then tell tmux-modal to load the custom file instead with tmux option
# `modal-keybindings-conf`. For example, put this is in your `.tmux.conf`:
#
#     set -g @modal-keybindings-conf /path/to/my-tmux-modal-keybindings.conf
#
# The syntax is the same as for tmux keybindings:
#
#     KBD_CMD_EXIT=Escape
#     KBD_WIN_RESIZE_UP=S-Up
#     KBD_GOTO_WIN_NEXT=C-n
#     KBD_GOTO_SESS_PREV=M-p
#
# This binds `Esc`, `Shift-Up`, `Ctrl-n` and `Alt-p`, to `KBD_CMD_EXIT` (exit
# modal command mode), `KBD_WIN_RESIZE_UP` (window resize up),
# `KBD_GOTO_WIN_NEXT` (go to next window) and `KBD_GOTO_SESS_PREV` (go to
# previous session), respectively.
#
# Each keybinding variable below has an accompanying comment line. Comment lines
# that starts with a single '#' are "root" commands. Two '#'s means that this is
# a "sub-command" to the previous root command. Three '#'s means that it is a
# sub-command to the previous sub-command, and so on. If a 'q' is followed by a
# '#' in the comment line, it indicates that this command is "sticky", i.e. it
# needs to be exited explicitly (with `KBD_QUIT`).
#
# For example, `KBD_WIN_GOTO_1` is a sub-command to `KBD_WIN` and is used with
# `w 1`. `KBD_PASTE` can be used directly after entering the modal mode, i.e.
# `M-m y`. While `KBD_WIN_RESIZE_RIGHT` is used with `w r l` and is a sticky
# command (since `KBD_WIN_RESIZE`'s comment line is `##q`) and must be exited
# with 'q' (see the `README` for more details).

# Enter modal command mode.
KBD_CMD=M-m

# Exit modal command mode.
KBD_CMD_EXIT=M-m

# Quit command. This is used to exit command modes that don't require prefix
# (e.g. "w r" used for resizing panes).
KBD_QUIT=q

# Enter copy mode.
KBD_COPY_MODE=c

# Paste buffer (e.g. from copy mode).
KBD_PASTE=y

# Open the tmux command prompt.
KBD_CMD_PROMPT=:

# Window command prefix.
KBD_WIN=w

## Select window 0 (window command alias for KBD_GOTO_WIN_0).
KBD_WIN_GOTO_0=0

## Select window 1 (window command alias for KBD_GOTO_WIN_1).
KBD_WIN_GOTO_1=1

## Select window 2 (window command alias for KBD_GOTO_WIN_2).
KBD_WIN_GOTO_2=2

## Select window 3 (window command alias for KBD_GOTO_WIN_3).
KBD_WIN_GOTO_3=3

## Select window 4 (window command alias for KBD_GOTO_WIN_4).
KBD_WIN_GOTO_4=4

## Select window 5 (window command alias for KBD_GOTO_WIN_5).
KBD_WIN_GOTO_5=5

## Select window 6 (window command alias for KBD_GOTO_WIN_6).
KBD_WIN_GOTO_6=6

## Select window 7 (window command alias for KBD_GOTO_WIN_7).
KBD_WIN_GOTO_7=7

## Select window 8 (window command alias for KBD_GOTO_WIN_8).
KBD_WIN_GOTO_8=8

## Select window 9 (window command alias for KBD_GOTO_WIN_9).
KBD_WIN_GOTO_9=9

## Select window with tree view (window command alias for KBD_GOTO_WIN_TREE).
KBD_WIN_GOTO_TREE=t

## Select window with index (window command alias for KBD_GOTO_WIN_INDEX).
KBD_WIN_GOTO_INDEX=i

## Select left pane.
KBD_WIN_PANE_LEFT=h

## Select right pane.
KBD_WIN_PANE_RIGHT=l

## Select above pane.
KBD_WIN_PANE_UP=k

## Select below pane.
KBD_WIN_PANE_DOWN=j

## Delete window pane.
KBD_WIN_PANE_DEL=d

## Select previous window (window command alias for KBD_GOTO_WIN_PREV).
KBD_WIN_PREV=H

## Select next window (window command alias for KBD_GOTO_WIN_NEXT).
KBD_WIN_NEXT=L

## Delete window.
KBD_WIN_DEL=D

## Create new window.
KBD_WIN_CREATE=c

## Select last window (window command alias for KBD_GOTO_WIN_LAST).
KBD_WIN_LAST=o

## Zoom pane.
KBD_WIN_ZOOM=z

## Break pane.
KBD_WIN_BREAK=b

## Display pane numbers.
KBD_WIN_NR=n

## Rename window.
KBD_WIN_RENAME=,

##q Pane command prefix (same bindings as KBD_WIN but without the prefix).
KBD_WIN_PANE=w

## Split command prefix.
KBD_WIN_SPLIT=s

### Split window pane right.
KBD_WIN_SPLIT_RIGHT=l

### Split window pane down.
KBD_WIN_SPLIT_DOWN=j

## Move command prefix.
KBD_WIN_MOVE=m

### Move window pane up.
KBD_WIN_MOVE_UP=k

### Move window pane down.
KBD_WIN_MOVE_DOWN=j

## Arrange command prefix.
KBD_WIN_ARRANGE=a

### Arrange window layout 1 ("even-horizontal").
KBD_WIN_ARRANGE_1=1

### Arrange window layout 2 ("even-vertical").
KBD_WIN_ARRANGE_2=2

### Arrange window layout 3 ("main-horizontal").
KBD_WIN_ARRANGE_3=3

### Arrange window layout 4 ("main-vertical").
KBD_WIN_ARRANGE_4=4

##q Resize command prefix.
KBD_WIN_RESIZE=r

### Resize pane left one step.
KBD_WIN_RESIZE_LEFT=h

### Resize pane right one step.
KBD_WIN_RESIZE_RIGHT=l

### Resize pane down one step.
KBD_WIN_RESIZE_DOWN=j

### Resize pane up one step.
KBD_WIN_RESIZE_UP=k

### Resize pane left multiple steps.
KBD_WIN_RESIZE_MULTI_LEFT=H

### Resize pane right multiple steps.
KBD_WIN_RESIZE_MULTI_RIGHT=L

### Resize pane down multiple steps.
KBD_WIN_RESIZE_MULTI_DOWN=J

### Resize pane up multiple steps.
KBD_WIN_RESIZE_MULTI_UP=K

# Session command prefix.
KBD_SESS=s

## Detach session.
KBD_SESS_DETACH=d

## Select previous session (session command alias for KBD_GOTO_SESS_PREV).
KBD_SESS_PREV=h

## Select next session (session command alias for KBD_GOTO_SESS_NEXT).
KBD_SESS_NEXT=l

## Select session with a tree view (session command alias for
## KBD_GOTO_SESS_TREE).
KBD_SESS_TREE=t

## Delete session.
KBD_SESS_DEL=D

# "Go to" command prefix.
KBD_GOTO=g

## Go to window command prefix.
KBD_GOTO_WIN=w

### Go to window 0.
KBD_GOTO_WIN_0=0

### Go to window 1.
KBD_GOTO_WIN_1=1

### Go to window 2.
KBD_GOTO_WIN_2=2

### Go to window 3.
KBD_GOTO_WIN_3=3

### Go to window 4.
KBD_GOTO_WIN_4=4

### Go to window 5.
KBD_GOTO_WIN_5=5

### Go to window 6.
KBD_GOTO_WIN_6=6

### Go to window 7.
KBD_GOTO_WIN_7=7

### Go to window 8.
KBD_GOTO_WIN_8=8

### Go to window 9.
KBD_GOTO_WIN_9=9

### Go to window with tree view.
KBD_GOTO_WIN_TREE=t

### Go to window with index.
KBD_GOTO_WIN_INDEX=i

### Go to previous window.
KBD_GOTO_WIN_PREV=h

### Go to next window.
KBD_GOTO_WIN_NEXT=l

### Go to last window.
KBD_GOTO_WIN_LAST=o

## Go to session command prefix.
KBD_GOTO_SESS=s

### Go to previous session.
KBD_GOTO_SESS_PREV=h

### Go to next session.
KBD_GOTO_SESS_NEXT=l

### Go to session with tree view.
KBD_GOTO_SESS_TREE=t
# END KEYBINDINGS

KT_PREFIX="ktm"
KT_CMD=$KT_PREFIX-cmd

# Reset all our key tables before binding. There might be remnant from previous
# bindings, e.g. from KBD_CONF_FILE (if for instance reloading tmux
# configuration file or running this explicitly).
unbind "^bind-key +-T +$KT_PREFIX-"
unbind "^bind-key +-T +root +.+ +set-option key-table $KT_CMD"

# Parse options.

# Source custom (overriding) keybinding file.
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONF_OPT=@modal-keybindings-conf
KBD_CONF_FILE=$(tmux show-options -g -v -q $CONF_OPT)
if [ -z "$KBD_CONF_FILE" ]; then
    KBD_CONF_FILE="$CURRENT_DIR/keybindings.conf"
fi

if [ ! -f "$KBD_CONF_FILE" ]; then
    echo Option $CONF_OPT: File \""$KBD_CONF_FILE"\" not found
    exit 2
fi

source "$KBD_CONF_FILE"

# Check usage of y/n-commands.
YESNO_OPT=@modal-yesno-cmd
YESNO_OPT_VAL=$(tmux show-options -g -v -q $YESNO_OPT)
if [ -z "$YESNO_OPT_VAL" ]; then
    YESNO_OPT_VAL=off
elif ! parse_yn_opt "$YESNO_OPT_VAL" $YESNO_OPT ; then
    exit 22
fi

if [ $YESNO_OPT_VAL == off ]; then
    KILL_PANE=kill-pane
    KILL_WINDOW=kill-window
    KILL_SESSION=kill-session
else
    KILL_PANE='confirm-before -p "kill-pane #P? (y/n)" kill-pane'
    KILL_WINDOW='confirm-before -p "kill-window #W? (y/n)" kill-window'
    KILL_SESSION='confirm-before -p "kill-session #S? (y/n)" kill-session'
fi

# Start with modal command keytable.
START_OPT=@modal-on-start
START_OPT_VAL=$(tmux show-options -g -v -q $START_OPT)
if [ -z "$START_OPT_VAL" ]; then
    START_OPT_VAL=off
elif ! parse_yn_opt "$START_OPT_VAL" $START_OPT; then
    exit 22
fi

# Create keybinding file to be sourced by tmux.

KBD_FILE="$CURRENT_DIR/.kbd.conf"

# Copy user's current root keytable to KT_CMD. We filter out any bindings that
# conflict with KBD_CMD.
tmux list-keys -T root | \
    grep -E -v " +root +$KBD_CMD +" | \
    grep -E -v " +set-option key-table $KT_CMD" | \
    sed -e "s/\(^bind-key -T\) root/\1 $KT_CMD/g" > $KBD_FILE

cat << EOF >> "$KBD_FILE"

bind-key -T root $KBD_CMD set-option key-table $KT_CMD
bind-key -T $KT_CMD $KBD_CMD_EXIT set-option key-table root

bind-key -T $KT_CMD $KBD_COPY_MODE copy-mode

bind-key -T $KT_CMD $KBD_PASTE paste-buffer

bind-key -T $KT_CMD $KBD_CMD_PROMPT command-prompt
EOF

# window.
KT_WIN=$KT_PREFIX-window
KT_WIN_PANE=$KT_PREFIX-window-pane
KT_WIN_SPLIT=$KT_PREFIX-window-split
KT_WIN_MOVE=$KT_PREFIX-window-move
KT_WIN_ARRANGE=$KT_PREFIX-window-arrange
KT_WIN_RESIZE=$KT_PREFIX-window-resize
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_CMD $KBD_WIN switch-client -T $KT_WIN

bind-key -T $KT_WIN $KBD_WIN_GOTO_0 select-window -t :0
bind-key -T $KT_WIN $KBD_WIN_GOTO_1 select-window -t :1
bind-key -T $KT_WIN $KBD_WIN_GOTO_2 select-window -t :2
bind-key -T $KT_WIN $KBD_WIN_GOTO_3 select-window -t :3
bind-key -T $KT_WIN $KBD_WIN_GOTO_4 select-window -t :4
bind-key -T $KT_WIN $KBD_WIN_GOTO_5 select-window -t :5
bind-key -T $KT_WIN $KBD_WIN_GOTO_6 select-window -t :6
bind-key -T $KT_WIN $KBD_WIN_GOTO_7 select-window -t :7
bind-key -T $KT_WIN $KBD_WIN_GOTO_8 select-window -t :8
bind-key -T $KT_WIN $KBD_WIN_GOTO_9 select-window -t :9
bind-key -T $KT_WIN $KBD_WIN_GOTO_TREE choose-tree -Zw
bind-key -T $KT_WIN $KBD_WIN_GOTO_INDEX \
    command-prompt -p index "select-window -t ':%%'"

bind-key -T $KT_WIN $KBD_WIN_PANE_LEFT select-pane -L
bind-key -T $KT_WIN $KBD_WIN_PANE_RIGHT select-pane -R
bind-key -T $KT_WIN $KBD_WIN_PANE_UP select-pane -U
bind-key -T $KT_WIN $KBD_WIN_PANE_DOWN select-pane -D
bind-key -T $KT_WIN $KBD_WIN_PANE_DEL $KILL_PANE
bind-key -T $KT_WIN $KBD_WIN_PREV select-window -t :-
bind-key -T $KT_WIN $KBD_WIN_NEXT select-window -t :+
bind-key -T $KT_WIN $KBD_WIN_DEL $KILL_WINDOW
bind-key -T $KT_WIN $KBD_WIN_CREATE new-window
bind-key -T $KT_WIN $KBD_WIN_LAST last-window
bind-key -T $KT_WIN $KBD_WIN_ZOOM resize-pane -Z
bind-key -T $KT_WIN $KBD_WIN_BREAK break-pane
bind-key -T $KT_WIN $KBD_WIN_NR display-panes
bind-key -T $KT_WIN $KBD_WIN_RENAME \
    command-prompt -I "#W" "rename-window -- '%%'"

bind-key -T $KT_WIN $KBD_WIN_PANE set-option key-table $KT_WIN_PANE
bind-key -T $KT_WIN $KBD_WIN_SPLIT switch-client -T $KT_WIN_SPLIT
bind-key -T $KT_WIN $KBD_WIN_MOVE switch-client -T $KT_WIN_MOVE
bind-key -T $KT_WIN $KBD_WIN_ARRANGE switch-client -T $KT_WIN_ARRANGE
bind-key -T $KT_WIN $KBD_WIN_RESIZE set-option key-table $KT_WIN_RESIZE
EOF

# window-pane.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_0 select-window -t :0
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_1 select-window -t :1
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_2 select-window -t :2
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_3 select-window -t :3
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_4 select-window -t :4
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_5 select-window -t :5
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_6 select-window -t :6
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_7 select-window -t :7
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_8 select-window -t :8
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_9 select-window -t :9
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_TREE choose-tree -Zw
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_INDEX \
    command-prompt -p index "select-window -t ':%%'"

bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_LEFT select-pane -L
bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_RIGHT select-pane -R
bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_UP select-pane -U
bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_DOWN select-pane -D
bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_DEL $KILL_PANE
bind-key -T $KT_WIN_PANE $KBD_WIN_PREV select-window -t :-
bind-key -T $KT_WIN_PANE $KBD_WIN_NEXT select-window -t :+
bind-key -T $KT_WIN_PANE $KBD_WIN_DEL $KILL_WINDOW
bind-key -T $KT_WIN_PANE $KBD_WIN_CREATE new-window
bind-key -T $KT_WIN_PANE $KBD_WIN_LAST last-window
bind-key -T $KT_WIN_PANE $KBD_WIN_ZOOM resize-pane -Z
bind-key -T $KT_WIN_PANE $KBD_WIN_BREAK break-pane
bind-key -T $KT_WIN_PANE $KBD_WIN_NR display-panes
bind-key -T $KT_WIN_PANE $KBD_WIN_RENAME \
    command-prompt -I "#W" "rename-window -- '%%'"

bind-key -T $KT_WIN_PANE $KBD_WIN_SPLIT switch-client -T $KT_WIN_SPLIT
bind-key -T $KT_WIN_PANE $KBD_WIN_MOVE switch-client -T $KT_WIN_MOVE
bind-key -T $KT_WIN_PANE $KBD_WIN_ARRANGE switch-client -T $KT_WIN_ARRANGE

bind-key -T $KT_WIN_PANE $KBD_QUIT set-option key-table $KT_CMD
bind-key -T $KT_WIN_PANE $KBD_CMD_EXIT set-option key-table root
EOF

# window-split.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_SPLIT $KBD_WIN_SPLIT_RIGHT split-window -h
bind-key -T $KT_WIN_SPLIT $KBD_WIN_SPLIT_DOWN split-window
EOF

# window-move.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_MOVE $KBD_WIN_MOVE_UP swap-pane -U
bind-key -T $KT_WIN_MOVE $KBD_WIN_MOVE_DOWN swap-pane -D
EOF

# window-arrange.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_ARRANGE $KBD_WIN_ARRANGE_1 select-layout even-horizontal
bind-key -T $KT_WIN_ARRANGE $KBD_WIN_ARRANGE_2 select-layout even-vertical
bind-key -T $KT_WIN_ARRANGE $KBD_WIN_ARRANGE_3 select-layout main-horizontal
bind-key -T $KT_WIN_ARRANGE $KBD_WIN_ARRANGE_4 select-layout main-vertical
EOF

# window-resize.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_LEFT resize-pane -L
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_RIGHT resize-pane -R
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_DOWN resize-pane -D
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_UP resize-pane -U
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_MULTI_LEFT resize-pane -L 5
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_MULTI_RIGHT resize-pane -R 5
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_MULTI_DOWN resize-pane -D 5
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_MULTI_UP resize-pane -U 5

bind-key -T $KT_WIN_RESIZE $KBD_QUIT set-option key-table $KT_CMD
bind-key -T $KT_WIN_RESIZE $KBD_CMD_EXIT set-option key-table root
EOF

# session.
KT_SESS=$KT_PREFIX-session
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_CMD $KBD_SESS switch-client -T $KT_SESS

bind-key -T $KT_SESS $KBD_SESS_DETACH detach-client
bind-key -T $KT_SESS $KBD_SESS_PREV switch-client -p
bind-key -T $KT_SESS $KBD_SESS_NEXT switch-client -n
bind-key -T $KT_SESS $KBD_SESS_TREE choose-tree -Zs
bind-key -T $KT_SESS $KBD_SESS_DEL $KILL_SESSION
EOF

# goto.
KT_GOTO=$KT_PREFIX-goto
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_CMD $KBD_GOTO switch-client -T $KT_GOTO
EOF

# goto-window.
KT_GOTO_WIN=$KT_PREFIX-goto-window
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_GOTO $KBD_GOTO_WIN switch-client -T $KT_GOTO_WIN

bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_0 select-window -t :0
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_1 select-window -t :1
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_2 select-window -t :2
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_3 select-window -t :3
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_4 select-window -t :4
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_5 select-window -t :5
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_6 select-window -t :6
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_7 select-window -t :7
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_8 select-window -t :8
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_9 select-window -t :9
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_TREE choose-tree -Zw
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_INDEX \
    command-prompt -p index "select-window -t ':%%'"
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_PREV select-window -t :-
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_NEXT select-window -t :+
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_LAST last-window
EOF

# goto-session.
KT_GOTO_SESS=$KT_PREFIX-goto-session
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_GOTO $KBD_GOTO_SESS switch-client -T $KT_GOTO_SESS

bind-key -T $KT_GOTO_SESS $KBD_GOTO_SESS_PREV switch-client -p
bind-key -T $KT_GOTO_SESS $KBD_GOTO_SESS_NEXT switch-client -n
bind-key -T $KT_GOTO_SESS $KBD_GOTO_SESS_TREE choose-tree -Zs
EOF

# Load the keybindings.
tmux source-file "$KBD_FILE"

if [ "$START_OPT_VAL" == on ]; then
    # Start with modal command keytable.
    tmux set-option -g key-table $KT_CMD
fi

# Prepend left status bar with MODAL_ICON if our key tables are in use.
# Determine this by checking if current key table starts with our prefix.
MODAL_ICON="[=]"
STATUS_LEFT=`
    `'#{'`
      `'?#{==:'$KT_PREFIX'-,'`
         `'#{='$((${#KT_PREFIX} + 1))':client_key_table}'`
        `'},'`
       `$MODAL_ICON' ,'`
     `'}'

# We want to set the left status bar once; do it only if we can't find our
# status string in current status (otherwise we would create several icons next
# to each other, which could happen if this is run back to back multiple times
# somehow).
CURRENT_STATUS_LEFT=$(tmux show-options -g -v status-left)
if ! grep -q -F "$STATUS_LEFT" <<< "$CURRENT_STATUS_LEFT"; then
    tmux set-option -g status-left "$STATUS_LEFT""$CURRENT_STATUS_LEFT"
fi
