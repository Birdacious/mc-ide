# How-to (OC2, for Minecraft 1.18)
To get internet to connect from your in-game computer to your IRL computer, try one of these two OC2 forks:
* https://github.com/Paranoidlabs/oc2/tree/develop
* https://github.com/Ktlo/oc2/tree/internet-card

I used the second b/c I couldn't figure out how to use the first.
The [OC2's main branch](https://github.com/fnuecke/oc2) is a few commits ahead, but you can merge either fork into main and it works fine.

Guide on how to connect to the internet using Ktlo's fork:
1. Make a computer in-game, put an internet card in.
2. Install Mosh normally for your IRL computer
3. Build Mosh for riscv64-musl with the given script and import the `mosh-client` into your in-game hard-drive. (Found in `.../.minecraft/saves/<world>/oc2-blobs/`. The weird files inside are your in-game drives, which are real filesystems that can be mounted!) You will need an extra drive separate from the one Sedna Linux is installed on, or there won't be enough space. Insert a new blank drive in your in-game computer, find it in `/dev/vdb`, `mke2fs` it, then mount it to use it.
4. Also import your IRL terminfo entries `/usr/bin/terminfo/m/mosh*` into your in-game computer's `/usr/bin/terminfo/m/`.
5. Run the following on your in-game computer (need to re-run every reboot, I recommend making a shell script):
```
ip link set eth0 up
ip addr add 192.168.2.1
ip route add default via 192.168.2.2
(explanation here: https://github.com/fnuecke/oc2/pull/63#issuecomment-1166291060)
```
I also recommend `ping`ing your IRL IP to verify you have internet access.
6. Also run the following in-game, because by default it points to the wrong place: `export TERMINFO=/usr/lib/terminfo`
7. IRL, run `mosh-server`. You'll see `MOSH CONNECT 60001 <secret_key>`.
8. In-game, run `MOSH_KEY=<secret_key> ./mosh-client <your_IRL_IP> 60001`

If mosh doesn't connect, try again / verify `mosh-server` didn't timeout or something / make sure you typed the key correctly. It can take a couple tries to connect.

# Alternatives
OC2's built-in `ssh` works, but Mosh is _much_ more responsive because 1) instead of TCP it uses UDP which allows frame skipping 2) it runs a predictive model of the server to make early guesses about what effect your keystrokes will have.

# Ideas for better performance?
Typing is still not as responsive as the pipe trick for OC1, but OC2 runs a bona-fide Linux VM in Minecraft (I know, right?!) and we have to connect over a server, both of which add overhead. You can mount an OC2 drive filesystem in a real terminal and edit them, but it doesn't update in real-time in-game like OC1 does—you have to reboot the in-game computer. Maybe you could get better speeds using a network filesystem somehow, or by doing something silly like editing the VM in memory. I stopped searching for a 1.18 solution beyond Mosh because I grew more interested in 1.12.
