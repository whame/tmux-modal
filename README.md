tmux-modal
==========

Execute complex tmux commands in just a few keystrokes. tmux-modal introduces a
modal mode (e.g. like in Vim text editor) in tmux that is designed to be
efficient, easy to remember and comfortable.

## Examples

Hit `M-m` (`Alt-m` in tmux terminology) first to enter the modal command mode.
The status bar will show `[=]` to indicate that we are now in the modal mode
(hit `M-m` again to exit back to "normal" mode). Here are some quick examples
what one can do with tmux-modal (see the [keybindings](#keybindings) for a
complete list).

**Navigation**

Easily move between panes and windows:

![navigation-demo](https://user-images.githubusercontent.com/9569246/152884650-0daa8e87-4eff-4f36-b4b4-b693c3bdef28.gif)

- `w l` to select the right pane
- `w j` to select the pane below
- `w 1` to select window 1
- `w o` to go back to other/last windows

**Management**

Create and delete windows with a breeze. Split, delete, zoom, move and break
panes and much more in just a few keystrokes:

![management-gif](https://user-images.githubusercontent.com/9569246/152884665-781279cd-c615-44f7-aaa0-8826e72c558c.gif)

- `w c` to create a new window
- `w D` to  delete window
- `w s k` to  split window pane right
- `w s j` to  split window pane below
- `w d` to delete a pane
- `w z` to zoom in/out of a pane

**Sticky commands**

Use sticky commands to do more, repeatedly. Sticky commands enters a _specific_
modal mode with specialized keybindings (see [keybindings](#keybindings) for a
more detailed explanation and a full list of available commands).

![sticky-window-gif](https://user-images.githubusercontent.com/9569246/152884680-79e0dcd1-7d72-4120-9fab-44f9e5e211ae.gif)

Hit `w w` to enter sticky window command:

- `s j` to split window pane below
- `k` to select the above pane
- `d` to delete a pane
- `c` to create window
- `0` to select window 0

Hit `w r` to enter sticky resize window command:

![sticky-resize-gif](https://user-images.githubusercontent.com/9569246/152884687-29d6fff8-122e-4fa7-aeab-cc4d5ef1b198.gif)

- `k` to resize the window pane one step upwards
- `l` to resize the window pane one step to the right
- `J` to resize the window pane multiple steps downwards
- `H` to resize the window pane multiple steps to the left

## Install

### Tmux Plugin Manager

Using [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) is the
recommended way to install tmux-modal. Just add it as a plugin in your
`~/.tmux.conf`:

```
set -g @plugin 'whame/tmux-modal'
```

Then hit `prefix` + `I` to install it (see the documentaion for Tmux Plugin
Manager for more details).

### Manually

You can also clone and manually install tmux-modal. Put this at the end of your
`~/.tmux.conf`:

```
run /path/to/cloned/tmux-modal/tmux-modal.tmux
```

Note however that in this case you have to manually sync the cloned repository
in order to get bug fixes, new features etc.

## Keybindings

The following are the default keybindings of tmux-modal. (Note that these are
customizable, as well as the command executed for each! See option
[`@modal-keybindings-conf`](#custom-keybindings) and
[`@modal-commands-conf`](#custom-commands), respectively.)

### Main

| Keybinding | Description                         | tmux Command     |
|------------|-------------------------------------|------------------|
| `M-m`      | Enter modal command mode.           | -                |
| `M-m`      | Exit modal command mode.            | -                |
| `y`        | Paste buffer (e.g. from copy mode). | `paste-buffer`   |
| `c`        | Enter copy-mode.                    | `copy-mode`      |
| `q`        | Quit sticky command.                | -                |
| `:`        | Open tmux command mode.             | `command-prompt` |

### Window

| Keybinding | Description                                                 | tmux Command                                       |
|------------|-------------------------------------------------------------|----------------------------------------------------|
| `w w`      | Enter sticky window command mode.                           | -                                                  |
| `w 0`      | Go to window 0. This is an alias for `g w 0`.               | `select-window -t :0`                              |
| `w 1`      | Go to window 1. This is an alias for `g w 1`.               | `select-window -t :1`                              |
| `w 2`      | Go to window 2. This is an alias for `g w 2`.               | `select-window -t :2`                              |
| `w 3`      | Go to window 3. This is an alias for `g w 3`.               | `select-window -t :3`                              |
| `w 4`      | Go to window 4. This is an alias for `g w 4`.               | `select-window -t :4`                              |
| `w 5`      | Go to window 5. This is an alias for `g w 5`.               | `select-window -t :5`                              |
| `w 6`      | Go to window 6. This is an alias for `g w 6`.               | `select-window -t :6`                              |
| `w 7`      | Go to window 7. This is an alias for `g w 7`.               | `select-window -t :7`                              |
| `w 8`      | Go to window 8. This is an alias for `g w 8`.               | `select-window -t :8`                              |
| `w 9`      | Go to window 9. This is an alias for `g w 9`.               | `select-window -t :9`                              |
| `w t`      | Select window with tree view. This is an alias for `g w t`. | `choose-tree -Zw`                                  |
| `w i`      | Select window with index. This is an alias for `g w i`.     | `command-prompt -p index "select-window -t ':%%'"` |
| `w h`      | Select left pane.                                           | `select-pane -L`                                   |
| `w l`      | Select right pane.                                          | `select-pane -R`                                   |
| `w k`      | Select above pane.                                          | `select-pane -U`                                   |
| `w j`      | Select below pane.                                          | `select-pane -D`                                   |
| `w d`      | Delete window pane.                                         | `kill-pane`                                        |
| `w H`      | Select previous window. This is an alias for `g w h`.       | `select-window -t :-`                              |
| `w L`      | Select next window. This is an alias for `g w l`.           | `select-window -t :+`                              |
| `w D`      | Delete window.                                              | `kill-window`                                      |
| `w c`      | Create new window.                                          | `new-window`                                       |
| `w o`      | Select other/last window.                                   | `last-window`                                      |
| `w z`      | Zoom pane.                                                  | `resize-pane -Z`                                   |
| `w b`      | Break pane into a new window.                               | `break-pane`                                       |
| `w n`      | Display pane numbers.                                       | `display-panes`                                    |
| `w ,`      | Rename window.                                              | `command-prompt -I "#W" "rename-window -- '%%'"`   |
| `w s l`    | Split window pane right.                                    | `split-window -h`                                  |
| `w s j`    | Split window pane down.                                     | `split-window`                                     |
| `w m k`    | Move window pane up.                                        | `swap-pane -U`                                     |
| `w m j`    | Move window pane down.                                      | `swap-pane -D`                                     |
| `w a 1`    | Arrange window to layout 1.                                 | `select-layout even-horizontal`                    |
| `w a 2`    | Arrange window to layout 2.                                 | `select-layout even-vertical`                      |
| `w a 3`    | Arrange window to layout 3.                                 | `select-layout main-horizontal`                    |
| `w a 4`    | Arrange window to layout 4.                                 | `select-layout main-vertical`                      |

Note that the sticky window command (`w w`) allows one to execute all of the
above commands in the table but without the initial `w`. For example, after
hitting `w w`, `s l` splits the window pane to the right, `d` deletes the window
pane, `h` selects the left pane and so on (`q` exits the sticky command). Also
see the option [`@modal-always-sticky`](#always-sticky-command) if you instead
always want to use the sticky command version (with only hitting `w` once).

#### Resize

| Keybinding | Description                        | tmux Command |
|------------|------------------------------------|--------------|
| `w r`      | Enter sticky resize window command | -            |

When in sticky resize window command, the following resizes the window (as
usual, `q` exits the sticky command).

| Keybinding | Description                                          | tmux Command       |
|------------|------------------------------------------------------|--------------------|
| `h`        | Resizes the window pane one step to the left.        | `resize-pane -L`   |
| `l`        | Resizes the window pane one step to the right.       | `resize-pane -R`   |
| `j`        | Resizes the window pane one step downwards.          | `resize-pane -D`   |
| `k`        | Resizes the window pane one step upwards.            | `resize-pane -U`   |
| `H`        | Resizes the window pane multiple steps to the left.  | `resize-pane -L 5` |
| `L`        | Resizes the window pane multiple steps to the right. | `resize-pane -R 5` |
| `J`        | Resizes the window pane multiple steps downwards.    | `resize-pane -D 5` |
| `K`        | Resizes the window pane multiple steps upwards.      | `resize-pane -U 5` |

### Session

| Keybinding | Description                                                  | tmux Command                                   |
|------------|--------------------------------------------------------------|------------------------------------------------|
| `s d`      | Detach session.                                              | `detach-client`                                |
| `s h`      | Select previous session. This is an alias for `g s h`.       | `switch-client -p`                             |
| `s l`      | Select next session. This is an alias for `g s l`.           | `switch-client -n`                             |
| `s t`      | Select session with tree view. This is an alias for `g s t`. | `choose-tree -Zs`                              |
| `s D`      | Delete session.                                              | `kill-session`                                 |
| `s ,`      | Rename session.                                              | `command-prompt -I "#S" "rename-session '%%'"` |


### Go to

#### Window

| Keybinding | Description                  | tmux Command                                       |
|------------|------------------------------|----------------------------------------------------|
| `g w 0`    | Go to window 0.              | `select-window -t :0`                              |
| `g w 1`    | Go to window 1.              | `select-window -t :1`                              |
| `g w 2`    | Go to window 2.              | `select-window -t :2`                              |
| `g w 3`    | Go to window 3.              | `select-window -t :3`                              |
| `g w 4`    | Go to window 4.              | `select-window -t :4`                              |
| `g w 5`    | Go to window 5.              | `select-window -t :5`                              |
| `g w 6`    | Go to window 6.              | `select-window -t :6`                              |
| `g w 7`    | Go to window 7.              | `select-window -t :7`                              |
| `g w 8`    | Go to window 8.              | `select-window -t :8`                              |
| `g w 9`    | Go to window 9.              | `select-window -t :9`                              |
| `g w t`    | Go to window with tree view. | `choose-tree -Zw`                                  |
| `g w i`    | Go to window with index.     | `command-prompt -p index "select-window -t ':%%'"` |
| `g w h`    | Go to previous window.       | `select-window -t :-`                              |
| `g w l`    | Go to next window.           | `select-window -t :+`                              |
| `g w o`    | Go to other/last window.     | `last-window`                                      |

#### Session

| Keybinding | Description                   | tmux Command       |
|------------|-------------------------------|--------------------|
| `g s h`    | Go to previous session.       | `switch-client -p` |
| `g s l`    | Go to next session.           | `switch-client -n` |
| `g s t`    | Go to session with tree view. | `choose-tree -Zs`  |

## Customization

### Custom keybindings

The option `@modal-keybindings-conf` can be set to load custom keybindings. The
file [`keybindings.conf`](keybindings.conf) shows the default keybindings and
can be used as a template. Thus, copy the file and modify it to your liking, and
finally set this in your `.tmux.conf` to load them:

```
set -g @modal-keybindings-conf /path/to/my-tmux-modal-keybindings.conf
```

### Custom commands

The option `@modal-commands-conf` can be set to load custom commands that will
be executed for the keybindings. The file [`commands.conf`](commands.conf) shows
the default commands and can be used as a template. Thus, copy the file and
modify it to your liking, and finally set this in your `.tmux.conf` to load
them:

```
set -g @modal-commands-conf /path/to/my-tmux-modal-commands.conf
```

### Start with modal command mode

The option `@modal-on-start` can be used to automatically enter the modal
command mode on a new tmux session. If you always want to start a new session
with the modal command mode, add the following to `.tmux.conf`:

```
set -g @modal-on-start on
```

### Always sticky command

The option `@modal-always-sticky` can be specified to always use the sticky
version instead of manually entering the sticky command first (e.g. `w w` for
sticky window command):

```
set -g @modal-always-sticky on
```

For example, with this in `.tmux.conf`, one only has to press `w` once and the
sticky window command mode will be entered directly. That is, after hitting `w`
once, you can now directly use `h`, `j`, `k` and `l` to select the window panes
(or any other window commands). Don't forget to exit the sticky command with
`q`.

### Show command keys in status bar

The option `@modal-show-cmd-keys` can be set in `.tmux.conf` to give immediate
feedback in the status bar during tmux-modal command sequences:

```
set -g @modal-show-cmd-keys on
```

The left status bar will now update to match the tmux-modal command currently in
use. For example, if you press `w` the status bar will change from the modal
command icon `[=]` to `[w]` (the window command). If you now further press `s`,
it will update to `[ws]` to signify the split window command sequence and so on.

### Yes/no prompt

**DEPRECATED**

This option is deprecated due to option
[`@modal-commands-conf`](#custom-commands) and will be removed soon. To keep the
old behavior, use option [`@modal-commands-conf`](#custom-commands) instead. For
example:

```
diff --git a/commands.conf b/commands.conf
index 1859fcb..ec4f65e 100644
--- a/commands.conf
+++ b/commands.conf
@@ -82,7 +82,7 @@ CMD_WIN_PANE_UP='select-pane -U'
 CMD_WIN_PANE_DOWN='select-pane -D'

 ## Delete window pane.
-CMD_WIN_PANE_DEL='kill-pane'
+CMD_WIN_PANE_DEL='confirm-before -p "kill-pane #P? (y/n)" kill-pane'

 ## Select previous window (window command alias for CMD_GOTO_WIN_PREV).
 CMD_WIN_PREV='select-window -t :-'
@@ -91,7 +91,7 @@ CMD_WIN_PREV='select-window -t :-'
 CMD_WIN_NEXT='select-window -t :+'

 ## Delete window.
-CMD_WIN_DEL='kill-window'
+CMD_WIN_DEL='confirm-before -p "kill-window #W? (y/n)" kill-window'

 ## Create new window.
 CMD_WIN_CREATE='new-window'
@@ -183,7 +183,7 @@ CMD_SESS_NEXT='switch-client -n'
 CMD_SESS_TREE='choose-tree -Zs'

 ## Delete session.
-CMD_SESS_DEL='kill-session'
+CMD_SESS_DEL='confirm-before -p "kill-session #S? (y/n)" kill-session'

 # "Go to" command prefix.
```

---

_Some commands might be too "dangerous" to execute directly, for example `w d`
(`kill-pane`) or `w D` (`kill-window`). The option `@modal-yesno-cmd` can
therefore be used to ask for confirmation before executing the commands (to
mimic the default tmux behavior). If you want a yes/no prompt before executing
these commands, put this in `.tmux.conf`:_

```
set -g @modal-yesno-cmd on
```
