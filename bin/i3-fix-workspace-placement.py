#! /bin/env python3

from i3ipc import Connection, Event

# Look for two outputs, 'eDP-1' (laptop display), and 'DP-3' (external
# monitor at home).
#
# Move every display with a number between 20 and 30 to the external
# monitor.

i3 = Connection()

# The display to move the workspaces to.
target_display = "DP-3"

# Return true if W is a workspace that should be moved to the external
# output.  This will be true even if W is even on the correct output.
def is_workspace_to_move(w):
    return w.num >= 20 and w.num < 30

def get_current_state(i3):
    state = {}

    current_workspaces = {}
    current_outputs = {}

    all_outputs = i3.get_outputs()
    for o in all_outputs:
        if o.active:
            # Which workspace is on this output?
            current_outputs[o.name] = o.current_workspace

            # Which output is the current workspace on?
            current_workspaces[o.current_workspace] = o.name

    # We don't have all the displays we need, so exit.
    if not ("DP-3" in current_outputs and "eDP-1" in current_outputs):
        return None

    # Remember the currently focused workspace.
    state['focused'] = None
    state['per_output'] = {}
    all_workspaces = i3.get_workspaces()
    for w in all_workspaces:
        if w.focused:
            state['focused'] = w
        if w.name in current_workspaces:
            output_name = current_workspaces[w.name]
            state['per_output'][output_name] = w

    return state

def doit(i3, cmd):
    print(cmd)
    res = i3.command(cmd)
    if not res:
        print(f"i3 command failed '{cmd}'")
    return res

# Grab the current state, which workspace is on which output, etc.
current_state = get_current_state(i3)
if not current_state:
    exit(0)

# Move all workspaces to the correct display.
all_workspaces = i3.get_workspaces()
for w in all_workspaces:
    if is_workspace_to_move(w):
        if w.output != target_display:
            doit(i3, f'workspace number {w.num}')
            doit(i3, f'move workspace to output {target_display}')

# Restore the correctly focused workspace.
for output_name, w in current_state['per_output'].items():
    if not is_workspace_to_move(w):
        doit(i3, f'workspace number {w.num}')

if current_state['focused']:
    w = current_state['focused']
    doit(i3, f'workspace number {w.num}')

