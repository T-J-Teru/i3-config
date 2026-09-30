#! /bin/env python3
import i3ipc
import sys

i3 = i3ipc.Connection()

if len(sys.argv) == 1:

    # Find the name of the output containing the currently focused
    # container, place the name of this output (i.e. monitor) in
    # CURRENT_OUTPUT.
    current_output = None
    workspaces = i3.get_workspaces()
    for w in workspaces:
        if w.focused:
            current_output = w.output
            break

    # Now loop through all the outputs and build a line to represent
    # each output, all these lines are added to RES.  However, the
    # line representing the current output is not added to RES, and is
    # instead placed in CURRENT_OUTPUT_LN.
    outputs = i3.get_outputs()
    current_output_ln = None
    res = []
    for o in outputs:
        if o.active:
            ln = "%s\t(%s)" % (o.name, o.current_workspace)
            if o.name != current_output:
                res.append (ln)
            else:
                current_output_ln = ln

    # If we have a line representing the current output (i.e. the
    # output containing the currently focused container), then add
    # this to the end of the list.
    if current_output_ln != None:
        res.append(current_output_ln + "\t(focused output)")

    # Now print the results, one per line.  Note that the line for the
    # current output should always be last, this makes sense as we
    # probably don't want to move a workspace to the current output,
    # that would be a nop.
    for r in res:
        print (r)

else:

    # Passed a line representing the output to move to.  The line
    # contains lots of fields split by a TAB character, the first
    # field is the name of the output to move the current workspace
    # too.
    output = sys.argv[1].split("\t")[0]
    i3.command("move workspace to output %s" % output)
