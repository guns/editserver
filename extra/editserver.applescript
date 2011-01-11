(*
    Edit in EditServer

    guns <sung@metablu.com>
    http://github.com/guns/editserver
    MIT LICENSE
*)

tell current application
    -- Surprisingly more reliable than other programmatic methods
    tell application "System Events"
        keystroke "a" using command down
        keystroke "c" using command down
    end tell

    set app_name to name of current application as text
    set output to do shell script "/usr/bin/env ruby -r cgi -e '
        system *%W[curl -s --data id=applescript
                           --data url=#{CGI.escape %q(" & app_name & ")}
                           --data text=#{CGI.escape %x(pbpaste)}
                           http://editserver.dev/]
        ' | pbcopy"

    tell application "System Events"
        keystroke "a" using command down
        keystroke "v" using command down
    end tell
end tell
