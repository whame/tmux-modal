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

# Always sticky commands.
ALWAYS_STICKY_OPT=@modal-always-sticky
ALWAYS_STICKY_VAL=$(tmux show-options -g -v -q $ALWAYS_STICKY_OPT)
if [ -z "$ALWAYS_STICKY_VAL" ]; then
    ALWAYS_STICKY_VAL=off
elif ! parse_yn_opt "$ALWAYS_STICKY_VAL" $ALWAYS_STICKY_OPT; then
    exit 22
fi

# Show command keys (key tables) in status bar.
SHOW_CMD_KEYS_OPT=@modal-show-cmd-keys
SHOW_CMD_KEYS_VAL=$(tmux show-options -g -v -q $SHOW_CMD_KEYS_OPT)
if [ -z "$SHOW_CMD_KEYS_VAL" ]; then
    SHOW_CMD_KEYS_VAL=off
elif ! parse_yn_opt "$SHOW_CMD_KEYS_VAL" $SHOW_CMD_KEYS_OPT; then
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

BIND_KEY_KBD_WIN="bind-key -T $KT_CMD $KBD_WIN switch-client -T $KT_WIN"
if [ "$ALWAYS_STICKY_VAL" == on ]; then
    # Enter sticky window-pane directly.
    BIND_KEY_KBD_WIN="bind-key -T $KT_CMD $KBD_WIN"
    BIND_KEY_KBD_WIN+=" set-option key-table $KT_WIN_PANE"
fi

cat << EOF >> "$KBD_FILE"

$BIND_KEY_KBD_WIN

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
bind-key -T $KT_WIN_PANE $KBD_WIN_RESIZE set-option key-table $KT_WIN_RESIZE

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

# Prepend left status bar with KT_CMD_ICON if our key tables are in use.
# Determine this by checking if current key table starts with our prefix.
KT_CMD_ICON="[=]"
STATUS_LEFT=`
`'#{'`
  `'?#{==:'$KT_PREFIX'-,'`
     `'#{='$((${#KT_PREFIX} + 1))':client_key_table}'`
    `'},'`
   `$KT_CMD_ICON' ,'`
`'}'

if [ "$SHOW_CMD_KEYS_VAL" == on ]; then
    # Check which key table is in use and use corresponding "icon" in the left
    # status bar. The icons are derived from the keybindings.
    KT_WIN_ICON="[$KBD_WIN]"
    KT_WIN_PANE_ICON="[$KBD_WIN$KBD_WIN_PANE]"
    KT_WIN_SPLIT_ICON="[$KBD_WIN$KBD_WIN_SPLIT]"
    KT_WIN_MOVE_ICON="[$KBD_WIN$KBD_WIN_MOVE]"
    KT_WIN_ARRANGE_ICON="[$KBD_WIN$KBD_WIN_ARRANGE]"
    KT_WIN_RESIZE_ICON="[$KBD_WIN$KBD_WIN_RESIZE]"

    KT_SESS_ICON="[$KBD_SESS]"

    KT_GOTO_ICON="[$KBD_GOTO]"
    KT_GOTO_WIN_ICON="[$KBD_GOTO$KBD_GOTO_WIN]"
    KT_GOTO_SESS_ICON="[$KBD_GOTO$KBD_GOTO_SESS]"

    # Seems to be the only way to to do if-elseif-...-else in tmux format
    # syntax...
    STATUS_LEFT=`
    `'#{'`
      `'?#{==:'$KT_CMD','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_CMD_ICON' ,'`
    `'#{'`
      `'?#{==:'$KT_WIN','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_WIN_ICON' ,'`
    `'#{'`
      `'?#{==:'$KT_WIN_PANE','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_WIN_PANE_ICON' ,'`
    `'#{'`
     `'?#{==:'$KT_WIN_SPLIT','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_WIN_SPLIT_ICON' ,'`
    `'#{'`
     `'?#{==:'$KT_WIN_MOVE','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_WIN_MOVE_ICON' ,'`
    `'#{'`
     `'?#{==:'$KT_WIN_ARRANGE','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_WIN_ARRANGE_ICON' ,'`
    `'#{'`
     `'?#{==:'$KT_WIN_RESIZE','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_WIN_RESIZE_ICON' ,'`
    `'#{'`
     `'?#{==:'$KT_SESS','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_SESS_ICON' ,'`
    `'#{'`
     `'?#{==:'$KT_GOTO','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_GOTO_ICON' ,'`
    `'#{'`
     `'?#{==:'$KT_GOTO_WIN','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_GOTO_WIN_ICON' ,'`
    `'#{'`
     `'?#{==:'$KT_GOTO_SESS','`
         `'#{client_key_table}'`
        `'},'`
       `$KT_GOTO_SESS_ICON' ,'`
    `'}}}}}}}}}}}'
fi

# We want to set the left status bar once; do it only if we can't find our
# status string in current status (otherwise we would create several icons next
# to each other, which could happen if this is run back to back multiple times
# somehow).
CURRENT_STATUS_LEFT=$(tmux show-options -g -v status-left)
if ! grep -q -F "$STATUS_LEFT" <<< "$CURRENT_STATUS_LEFT"; then
    tmux set-option -g status-left "$STATUS_LEFT""$CURRENT_STATUS_LEFT"
fi
