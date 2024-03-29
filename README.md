Use your real computer's terminal on an in-game computer from the Opencomputers (OC) Minecraft mod! If you are a vim fan, you could feasibly use Minecraft as your IDE. The year is 202X and you can now do your programming day job within Minecraft.

See the `oc1` or `oc2` folder for further instructions for your desired version. If you're OK without 1.18 mods and are on Mac/Linux, I recommend the OC1 way. This method has real-time responsiveness and feels like a real terminal, good enough that I could actually use Minecraft as my IDE. If any employer is reading this, this is a joke and I am definitely not playing Minecraft on the job.

# How it works
## [OC1](https://github.com/MightyPirates/OpenComputers) (Minecraft 1.7, 1.12)
Minecraft is full-screen while you type into a terminal window focused in the background. The in-game terminal mirrors the real one by `cat`ing a named pipe which the real terminal is dumps its contents to via `script -f`. Focusing a window in the background is done using a window manager ([dwm](https://dwm.suckless.org/) for __Linux__, or [yabai](https://github.com/koekeishiya/yabai) for __MacOS__).

## [OC2](https://github.com/fnuecke/oc2) (Minecraft 1.18)
[Mosh](https://mosh.org/) is used to connect the in-game terminal to a real shell over the internet. The tricky part is cross-compiling Mosh for RISC-V, fitting it into an in-game drive, and using an unofficial fork of OC2 which implements internet access. This works __cross-platform (Windows, MacOS, & Linux)__.

# TODO
* OC1's terminal uses r6-g8-b5 colors whereas most terminals use r6-g6-b6, so they don't match exactly. Make some sort of translation layer that maps 6-6-6 colors to the nearest 6-8-5 color?
* OC1: Implement `\e[r` escape code (set vertical scrolling region). Should be the last step before (Neo)Vim is fully usable. (OC1's scrolling logic appears to be in `lib/tty.lua` and `lib/core/full_cursor.lua`, may have to change those).
* OC1's terminal has some janky method to make the terminal cursor blink using the `\e[5m` escape code, which is not how it works in real terminals so the cursor is not visible. (OC1's `lib/cursor.lua` has cursor blinking code, and `lib/term.lua` may also be relevant.)
