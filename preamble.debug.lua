local _, fluffy = ...

function fluffy.print_debug(msg)
    if not fluffy.debug_output then return; end

    print(msg);
end