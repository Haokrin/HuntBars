local _, fluffy = ...

function print_debug(msg)
    if not fluffy.debug_output then return; end

    print(msg);
end