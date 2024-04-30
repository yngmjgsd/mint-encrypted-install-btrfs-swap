# mint-encrypted-install-btrfs-swap for Linux Mint 21.3

This is a partially-automated version of [Naldi Stefano's
tutorial](https://community.linuxmint.com/tutorial/view/2061), which was
partly based on blog posts by Pavel Kogan
[here](http://www.pavelkogan.com/2014/05/23/luks-full-disk-encryption/)
and
[here](http://www.pavelkogan.com/2015/01/25/linux-mint-encryption/). Also, the original script that is avilable [here](https://github.com/calliecameron/mint-encrypted-install). All credit goes to them for figuring out how to do it. I edited and tested it with BTRFS+SWAP setup (no LVM here, unneded when you use BTRFS). There are benefits of this setup such as:

- BTRFS snapshots
- Timeshift can be used to make snapshots instead of RSYNC
- [timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) script can be used to take BTRFS snapshots of your system right before removing/upgrading packages
- [grub-btrfs](https://github.com/Antynea/grub-btrfs) script can be used to make GRUB boot your system from the snapshots

The **Linux Mint 21.3 installer (codename: Virginia)** has an option for installing on LVM inside
an encrypted LUKS container, but this is only offered if you want to erase
the whole disk (no dual boot), and also leaves the **`/boot`** partition
unencrypted. If you want to encrypt everything including **`/boot`**, or want to
install any sort of encrypted system alongside another OS for dual boot [1],
you have to configure the bootloader and initramfs manually -- which is
time-consuming and easy to get wrong. This script guides you through the
process, and automates as many of the commands as possible, making it much
easier to set up.

This is still an advanced configuration, though, and assumes you are
comfortable with the terminal, shell scripts, partitioning, and installing
and managing normal non-encrypted Linux systems. If in doubt, read the tutorial
linked above, and above all, *PLEASE BE CAREFUL*. Typing anything wrong here
could erase your hard drive! Make sure you test anything in a virtual machine
before trying it on your real machine.

I also suggest that you do not use it against the drives where the existing OSes are installed (unless, until you practice with the script and know how to use it before that). It is better to practice inside a virtual machine before doing it on a real system.

[1] You can install multiple Linux systems *inside* the same encrypted
container (using different logical volumes as **`/`**), and the bootloader will
pick those up just fine. But if you want to dual-boot alongside something
else (e.g. Windows), that has to use an unencrypted partition outside the
container.


## Usage

Boot the Linux Mint 21.3 live USB as normal. But instead of running the 'Install Linux Mint' launcher on the desktop, open a terminal and run the following commands:

    sudo apt-get -y install git
    git clone https://github.com/calliecameron/mint-encrypted-install
    cd mint-encrypted-install
    ./mint-encrypted-install.sh

This will guide you through the rest of the process.
