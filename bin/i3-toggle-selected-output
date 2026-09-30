#! /bin/env python3

# Cycle focus through all of the active outputs.


from i3ipc import Connection, Event

i3 = Connection()

focused_workspace = None
all_workspaces = i3.get_workspaces()
for w in all_workspaces:
    if w.focused:
        focused_workspace = w.name

# If we can't figure out which workspace currently has focus, then we
# can't figure out which output contains that workspace, and so we
# can't figure out which should be the next output to focus.
if not focused_workspace:
    exit(0)

all_outputs = i3.get_outputs()
output_names = []
current_output_index = None
for o in all_outputs:
    if o.active:
        if o.current_workspace == focused_workspace:
            current_output_index = len(output_names)
        output_names.append(o.name)

# Calculate the index and name of the next output.
next_output_index = (current_output_index + 1) % len(output_names)
next_output_name = output_names[next_output_index]

i3.command(f"focus output {next_output_name}")
