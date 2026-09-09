if status is-interactive
    set -g __faah_sound ~/.config/fish/sounds/faah.oga
    # Fallback to freedesktop error sound if custom file missing
    if not test -f $__faah_sound
        set -g __faah_sound /usr/share/sounds/freedesktop/stereo/dialog-error.oga
    end

    set -g __faah_flash_lock /tmp/faah-flash-(id -u).lock

    function __faah_flash_border
        command -v hyprctl &>/dev/null; or return

        # Skip if a flash is already in progress (lock younger than 2s)
        if test -e $__faah_flash_lock
            set -l age (math (date +%s) - (stat -c %Y $__faah_flash_lock 2>/dev/null; or echo 0))
            test $age -lt 2; and return
        end
        touch $__faah_flash_lock

        # Capture current active border so we can restore exactly (handles gradients)
        set -l orig (hyprctl getoption -j general:col.active_border 2>/dev/null \
            | string match -rg '"custom":\s*"([^"]+)"')
        if test -z "$orig"
            rm -f $__faah_flash_lock
            return
        end

        # Re-build with 0x prefix on hex tokens so round-trip matches current value
        set -l restore
        for part in (string split ' ' -- $orig)
            if string match -rq '^[0-9a-fA-F]{6,8}$' -- $part
                set -a restore "0x$part"
            else
                set -a restore $part
            end
        end

        hyprctl keyword general:col.active_border "rgba(ff3333ff)" &>/dev/null
        sleep 0.5
        hyprctl keyword general:col.active_border (string join ' ' $restore) &>/dev/null
        rm -f $__faah_flash_lock
    end

    function __faah_on_error --on-event fish_postexec
        set -l code $status
        # Skip success, Ctrl-C (130), and Ctrl-Z (148)
        if test $code -eq 0 -o $code -eq 130 -o $code -eq 148
            return
        end
        paplay $__faah_sound &>/dev/null &
        disown 2>/dev/null
        __faah_flash_border &
        disown 2>/dev/null
    end
end
