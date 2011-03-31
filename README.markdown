
            __      __
           /\ \  __/\ \__
       __  \_\ \/\_\ \ ,_\  ____    __  _ __  __  __    __   _ __
     /'__`\/'_` \/\ \ \ \/ /',__\ /'__`\\`'__\\ \/\ \ /'__`\\`'__\
    /\  __/\ \L\ \ \ \ \ \/\__, `\\  __/ \ \/\ \ \_/ |\  __/ \ \/
    \ \____\\___,_\ \_\ \__\\____/ \____\ \_\ \ \___/\ \____\ \_\
     \/____//__,_ /\/_/\/__//___/ \/____/\/_/  \/__/  \/____/\/_/

                                       guns <sung@metablu.com>


# Your favorite editor, as a local web service!

For use with [Textaid][1], on OS X with included applescript, or with any other
http client.

Everything works, and core tests are in place. More information forthcoming.


### TODO

 * Improve applescript reliability
 * Avoid dynamic creation of Editor subclasses in `Editserver::` namespace
   (a consequence of an earlier design decision)
 * Special case: OS X's `Terminal.app` as `editor['terminal']`


[1]: https://chrome.google.com/webstore/detail/ppoadiihggafnhokfkpphojggcdigllp
