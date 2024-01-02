Use your real computer's terminal on an in-game computer from the Opencomputers (OC) Minecraft mod! If you are a vim fan, you could feasibly use Minecraft as your IDE. The year is 202X and you can now do your programming day job within Minecraft.

See the `oc1` or `oc2` folder for further instructions for your desired version.

# How?
## [OC1](https://github.com/MightyPirates/OpenComputers) (Minecraft 1.7, 1.12)
Minecraft is full-screen while you type into a terminal window focused in the background. The in-game terminal mirrors the real one by `cat`ing a named pipe which the real terminal is dumps its contents to via `script -f`. Focusing a window in the background is done using a window manager ([dwm](https://dwm.suckless.org/) for __Linux__, [yabai](https://github.com/koekeishiya/yabai) for __MacOS__).

__I don't know how to do this in Windows__ and have no interest to develop it, but if 1) it is possible to focus a terminal window behind the Minecraft window; 2) you know how to use Windows's named pipes; and 3) you find or create some analogue to GNU `script -f`; then this should be possible on Windows.

You could also use [`ngsh`](https://oc.cil.li/topic/1753-ngsh-an-experimental-remote-shell-bridge-between-oc-and-unix-like-oses/) ([GitLab](https://gitlab.com/polyzium/ngsh/tree/master)), which connects your in-game computer to a real shell via a Golang server. This is __cross-platform__ (supports Windows), but typing is much less responsive, even on localhost, because you have to go through a TCP server. An intensive 3D demo performed surprisingly well in this [old test video of mine](https://youtu.be/WHZzNCMJ3Aw?si=wraVSzwTXTpQ2g1j&t=170), but it took ages to Ctrl+C out because TCP doesn't allow skipping frames.)

## [OC2](https://github.com/fnuecke/oc2) (Minecraft 1.18)
[Mosh](https://mosh.org/) is used to connect the in-game terminal to a real shell over the internet. The tricky part is cross-compiling Mosh for RISC-V, fitting it into an in-game drive, and using an unofficial fork of OC2 which implements internet access. This works __cross-platform (Windows, MacOS, & Linux)__.

OC2's built-in `ssh` works, but Mosh is _much_ more responsive because 1) instead of TCP it uses UDP which allows frame skipping 2) it runs a predictive model of the server to make early guesses about what effect your keystrokes will have.

Typing is still not as responsive as the pipe trick for OC1, but OC2 runs a bona-fide Linux VM in Minecraft (I know, right?!) and we have to connect over a server, both of which add overhead. You can mount an OC2 drive filesystem in a real terminal and edit them, but it doesn't update in real-time in-game like OC1 does—you have to reboot the in-game computer. Maybe you could get better speeds using a network filesystem somehow, or by doing something silly like editing the VM in memory. I stopped searching for a 1.18 solution beyond Mosh because I grew more interested in 1.12.

---

If you're OK without 1.18 mods, I recommend the OC1 way. This method has real-time responsiveness and feels like a real terminal, good enough that I could actually use Minecraft as my IDE. If any employer is reading this, this is a joke and I am definitely not playing any Minecraft on the job.
