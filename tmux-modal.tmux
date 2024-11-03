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

# Source default and custom (overriding) keybinding file.
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KBD_CONF_FILE="$CURRENT_DIR/keybindings.conf"

source "$KBD_CONF_FILE"

KBD_CONF_OPT=@modal-keybindings-conf
KBD_CONF_VAL=$(tmux show-options -g -v -q $KBD_CONF_OPT)
if [ -n "$KBD_CONF_VAL" ]; then
    if [ ! -f "$KBD_CONF_VAL" ]; then
        echo Option $KBD_CONF_OPT: File \""$KBD_CONF_VAL"\" not found
        exit 2
    fi

    source "$KBD_CONF_VAL"
fi

# Source default and custom (overriding) command file.
CMD_CONF_FILE="$CURRENT_DIR/commands.conf"

source "$CMD_CONF_FILE"

CMD_CONF_OPT=@modal-commands-conf
CMD_CONF_VAL=$(tmux show-options -g -v -q $CMD_CONF_OPT)
if [ -n "$CMD_CONF_VAL" ]; then
    if [ ! -f "$CMD_CONF_VAL" ]; then
        echo Option $CMD_CONF_OPT: File \""$CMD_CONF_VAL"\" not found
        exit 2
    fi

    source "$CMD_CONF_VAL"
fi

# Check usage of y/n-commands.
YESNO_OPT=@modal-yesno-cmd
YESNO_OPT_VAL=$(tmux show-options -g -v -q $YESNO_OPT)
if [ -n "$YESNO_OPT_VAL" ]; then
    echo "WARNING: Option $YESNO_OPT has been deprecated." \
         "Please use option $CMD_CONF_OPT instead"
fi

if [ -z "$YESNO_OPT_VAL" ]; then
    YESNO_OPT_VAL=off
elif ! parse_yn_opt "$YESNO_OPT_VAL" $YESNO_OPT ; then
    exit 22
fi

if [ $YESNO_OPT_VAL == on ]; then
    CMD_WIN_PANE_DEL='confirm-before -p "kill-pane #P? (y/n)" kill-pane'
    CMD_WIN_DEL='confirm-before -p "kill-window #W? (y/n)" kill-window'
    CMD_SESS_DEL='confirm-before -p "kill-session #S? (y/n)" kill-session'
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

# Modal mode status bar icon.
KT_CMD_ICON_OPT=@modal-cmd-icon
KT_CMD_ICON_VAL=$(tmux show-options -g -v -q $KT_CMD_ICON_OPT)
if [ -z "$KT_CMD_ICON_VAL" ]; then
    KT_CMD_ICON_VAL="[=]"
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

bind-key -T $KT_CMD $KBD_COPY_MODE $CMD_COPY_MODE

bind-key -T $KT_CMD $KBD_PASTE $CMD_PASTE

bind-key -T $KT_CMD $KBD_CMD_PROMPT $CMD_CMD_PROMPT
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

bind-key -T $KT_WIN $KBD_WIN_GOTO_0 $CMD_WIN_GOTO_0
bind-key -T $KT_WIN $KBD_WIN_GOTO_1 $CMD_WIN_GOTO_1
bind-key -T $KT_WIN $KBD_WIN_GOTO_2 $CMD_WIN_GOTO_2
bind-key -T $KT_WIN $KBD_WIN_GOTO_3 $CMD_WIN_GOTO_3
bind-key -T $KT_WIN $KBD_WIN_GOTO_4 $CMD_WIN_GOTO_4
bind-key -T $KT_WIN $KBD_WIN_GOTO_5 $CMD_WIN_GOTO_5
bind-key -T $KT_WIN $KBD_WIN_GOTO_6 $CMD_WIN_GOTO_6
bind-key -T $KT_WIN $KBD_WIN_GOTO_7 $CMD_WIN_GOTO_7
bind-key -T $KT_WIN $KBD_WIN_GOTO_8 $CMD_WIN_GOTO_8
bind-key -T $KT_WIN $KBD_WIN_GOTO_9 $CMD_WIN_GOTO_9
bind-key -T $KT_WIN $KBD_WIN_GOTO_TREE $CMD_WIN_GOTO_TREE
bind-key -T $KT_WIN $KBD_WIN_GOTO_INDEX $CMD_WIN_GOTO_INDEX

bind-key -T $KT_WIN $KBD_WIN_PANE_LEFT $CMD_WIN_PANE_LEFT
bind-key -T $KT_WIN $KBD_WIN_PANE_RIGHT $CMD_WIN_PANE_RIGHT
bind-key -T $KT_WIN $KBD_WIN_PANE_UP $CMD_WIN_PANE_UP
bind-key -T $KT_WIN $KBD_WIN_PANE_DOWN $CMD_WIN_PANE_DOWN
bind-key -T $KT_WIN $KBD_WIN_PANE_DEL $CMD_WIN_PANE_DEL
bind-key -T $KT_WIN $KBD_WIN_PREV $CMD_WIN_PREV
bind-key -T $KT_WIN $KBD_WIN_NEXT $CMD_WIN_NEXT
bind-key -T $KT_WIN $KBD_WIN_DEL $CMD_WIN_DEL
bind-key -T $KT_WIN $KBD_WIN_CREATE $CMD_WIN_CREATE
bind-key -T $KT_WIN $KBD_WIN_LAST $CMD_WIN_LAST
bind-key -T $KT_WIN $KBD_WIN_ZOOM $CMD_WIN_ZOOM
bind-key -T $KT_WIN $KBD_WIN_BREAK $CMD_WIN_BREAK
bind-key -T $KT_WIN $KBD_WIN_NR $CMD_WIN_NR
bind-key -T $KT_WIN $KBD_WIN_RENAME $CMD_WIN_RENAME

bind-key -T $KT_WIN $KBD_WIN_PANE set-option key-table $KT_WIN_PANE
bind-key -T $KT_WIN $KBD_WIN_SPLIT switch-client -T $KT_WIN_SPLIT
bind-key -T $KT_WIN $KBD_WIN_MOVE switch-client -T $KT_WIN_MOVE
bind-key -T $KT_WIN $KBD_WIN_ARRANGE switch-client -T $KT_WIN_ARRANGE
bind-key -T $KT_WIN $KBD_WIN_RESIZE set-option key-table $KT_WIN_RESIZE
EOF

# window-pane.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_0 $CMD_WIN_GOTO_0
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_1 $CMD_WIN_GOTO_1
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_2 $CMD_WIN_GOTO_2
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_3 $CMD_WIN_GOTO_3
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_4 $CMD_WIN_GOTO_4
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_5 $CMD_WIN_GOTO_5
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_6 $CMD_WIN_GOTO_6
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_7 $CMD_WIN_GOTO_7
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_8 $CMD_WIN_GOTO_8
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_9 $CMD_WIN_GOTO_9
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_TREE $CMD_WIN_GOTO_TREE
bind-key -T $KT_WIN_PANE $KBD_WIN_GOTO_INDEX $CMD_WIN_GOTO_INDEX

bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_LEFT $CMD_WIN_PANE_LEFT
bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_RIGHT $CMD_WIN_PANE_RIGHT
bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_UP $CMD_WIN_PANE_UP
bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_DOWN $CMD_WIN_PANE_DOWN
bind-key -T $KT_WIN_PANE $KBD_WIN_PANE_DEL $CMD_WIN_PANE_DEL
bind-key -T $KT_WIN_PANE $KBD_WIN_PREV $CMD_WIN_PREV
bind-key -T $KT_WIN_PANE $KBD_WIN_NEXT $CMD_WIN_NEXT
bind-key -T $KT_WIN_PANE $KBD_WIN_DEL $CMD_WIN_DEL
bind-key -T $KT_WIN_PANE $KBD_WIN_CREATE $CMD_WIN_CREATE
bind-key -T $KT_WIN_PANE $KBD_WIN_LAST $CMD_WIN_LAST
bind-key -T $KT_WIN_PANE $KBD_WIN_ZOOM $CMD_WIN_ZOOM
bind-key -T $KT_WIN_PANE $KBD_WIN_BREAK $CMD_WIN_BREAK
bind-key -T $KT_WIN_PANE $KBD_WIN_NR $CMD_WIN_NR
bind-key -T $KT_WIN_PANE $KBD_WIN_RENAME $CMD_WIN_RENAME

bind-key -T $KT_WIN_PANE $KBD_WIN_SPLIT switch-client -T $KT_WIN_SPLIT
bind-key -T $KT_WIN_PANE $KBD_WIN_MOVE switch-client -T $KT_WIN_MOVE
bind-key -T $KT_WIN_PANE $KBD_WIN_ARRANGE switch-client -T $KT_WIN_ARRANGE
bind-key -T $KT_WIN_PANE $KBD_WIN_RESIZE set-option key-table $KT_WIN_RESIZE

bind-key -T $KT_WIN_PANE $KBD_QUIT set-option key-table $KT_CMD
bind-key -T $KT_WIN_PANE $KBD_CMD_EXIT set-option key-table root
EOF

# window-split.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_SPLIT $KBD_WIN_SPLIT_RIGHT $CMD_WIN_SPLIT_RIGHT
bind-key -T $KT_WIN_SPLIT $KBD_WIN_SPLIT_DOWN $CMD_WIN_SPLIT_DOWN
EOF

# window-move.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_MOVE $KBD_WIN_MOVE_UP $CMD_WIN_MOVE_UP
bind-key -T $KT_WIN_MOVE $KBD_WIN_MOVE_DOWN $CMD_WIN_MOVE_DOWN
EOF

# window-arrange.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_ARRANGE $KBD_WIN_ARRANGE_1 $CMD_WIN_ARRANGE_1
bind-key -T $KT_WIN_ARRANGE $KBD_WIN_ARRANGE_2 $CMD_WIN_ARRANGE_2
bind-key -T $KT_WIN_ARRANGE $KBD_WIN_ARRANGE_3 $CMD_WIN_ARRANGE_3
bind-key -T $KT_WIN_ARRANGE $KBD_WIN_ARRANGE_4 $CMD_WIN_ARRANGE_4
EOF

# window-resize.
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_LEFT $CMD_WIN_RESIZE_LEFT
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_RIGHT $CMD_WIN_RESIZE_RIGHT
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_DOWN $CMD_WIN_RESIZE_DOWN
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_UP $CMD_WIN_RESIZE_UP
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_MULTI_LEFT $CMD_WIN_RESIZE_MULTI_LEFT
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_MULTI_RIGHT \
         $CMD_WIN_RESIZE_MULTI_RIGHT
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_MULTI_DOWN $CMD_WIN_RESIZE_MULTI_DOWN
bind-key -T $KT_WIN_RESIZE $KBD_WIN_RESIZE_MULTI_UP $CMD_WIN_RESIZE_MULTI_UP

bind-key -T $KT_WIN_RESIZE $KBD_QUIT set-option key-table $KT_CMD
bind-key -T $KT_WIN_RESIZE $KBD_CMD_EXIT set-option key-table root
EOF

# session.
KT_SESS=$KT_PREFIX-session
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_CMD $KBD_SESS switch-client -T $KT_SESS

bind-key -T $KT_SESS $KBD_SESS_DETACH $CMD_SESS_DETACH
bind-key -T $KT_SESS $KBD_SESS_PREV $CMD_SESS_PREV
bind-key -T $KT_SESS $KBD_SESS_NEXT $CMD_SESS_NEXT
bind-key -T $KT_SESS $KBD_SESS_TREE $CMD_SESS_TREE
bind-key -T $KT_SESS $KBD_SESS_DEL $CMD_SESS_DEL
bind-key -T $KT_SESS $KBD_SESS_RENAME $CMD_SESS_RENAME
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

bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_0 $CMD_GOTO_WIN_0
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_1 $CMD_GOTO_WIN_1
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_2 $CMD_GOTO_WIN_2
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_3 $CMD_GOTO_WIN_3
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_4 $CMD_GOTO_WIN_4
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_5 $CMD_GOTO_WIN_5
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_6 $CMD_GOTO_WIN_6
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_7 $CMD_GOTO_WIN_7
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_8 $CMD_GOTO_WIN_8
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_9 $CMD_GOTO_WIN_9
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_TREE $CMD_GOTO_WIN_TREE
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_INDEX $CMD_GOTO_WIN_INDEX
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_PREV $CMD_GOTO_WIN_PREV
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_NEXT $CMD_GOTO_WIN_NEXT
bind-key -T $KT_GOTO_WIN $KBD_GOTO_WIN_LAST $CMD_GOTO_WIN_LAST
EOF

# goto-session.
KT_GOTO_SESS=$KT_PREFIX-goto-session
cat << EOF >> "$KBD_FILE"

bind-key -T $KT_GOTO $KBD_GOTO_SESS switch-client -T $KT_GOTO_SESS

bind-key -T $KT_GOTO_SESS $KBD_GOTO_SESS_PREV $CMD_GOTO_SESS_PREV
bind-key -T $KT_GOTO_SESS $KBD_GOTO_SESS_NEXT $CMD_GOTO_SESS_NEXT
bind-key -T $KT_GOTO_SESS $KBD_GOTO_SESS_TREE $CMD_GOTO_SESS_TREE
EOF

# Load the keybindings.
tmux source-file "$KBD_FILE"

if [ "$START_OPT_VAL" == on ]; then
    # Start with modal command keytable.
    tmux set-option -g key-table $KT_CMD
fi

# Prepend left status bar with KT_CMD_ICON if our key tables are in use.
# Determine this by checking if current key table starts with our prefix.
KT_CMD_ICON=$KT_CMD_ICON_VAL
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
