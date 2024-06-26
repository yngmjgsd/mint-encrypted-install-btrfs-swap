#!/bin/bash

function enter-to-continue() {
    echo &&
    read -r -p "Press ENTER to continue..." &&
    echo &&
    echo
}

function yn-y() {
    # Y is the default
    local REPLY
    read -p "${1} [Y/n] " -r
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 1
    else
        return 0
    fi
}

function yn-n() {
    # N is the default
    local REPLY
    read -p "${1} [y/N] " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

function read-existing-path() {
    read -r -p "${1}: " name || fail
    if [ -z "${name}" ] || [ ! -e "${name}" ]; then
        echo "That file doesn't exist!" 1>&2
        exit 1
    else
        echo "${name}"
    fi
}

function fail() {
    echo -e "\e[31mSomething went wrong!\e[0m"
    exit 1
}


cat <<EOF &&
This script will guide you through the installation of Linux Mint 21.3 (codename: Virginia),
fully encrypted (including /boot) using BTRFS inside LUKS. This works for both
single- and dual-boot setups. UEFI is required; it doesn't support BIOS. You
can use this either to set up encryption from scratch, or to install/reinstall
another Linux inside an encrypted container that you set up in a previous run
of the script.

You *MUST* be running this on the Linux Mint 21.3 live USB, before installing. Bad things
could happen if you run this on an installed Linux system.

Based on a tutorial by Naldi Stefano:
https://community.linuxmint.com/tutorial/view/2061

This is an advanced configuration that assumes you are comfortable with the
terminal, shell scripts, partitioning, LUKS, and installing and managing
normal non-encrypted Linux systems. If not, read the tutorial above and make
sure you know what you are doing before continuing!

*PLEASE BE CAREFUL*! If you give incorrect inputs to this script, you could end
up erasing your hard drive. Whatever you want to use it for, test it in a
virtual machine first!
EOF

enter-to-continue &&


# Not completely foolproof, but should do the job...
if ! lsb_release -a 2>/dev/null | grep 'virginia' &>/dev/null || ! type ubiquity &>/dev/null; then
    cat <<EOF


You are not running on the Linux Mint 21.3 installer live
USB. Cannot go any further.
EOF
    exit 1
fi


if [ ! -e '/sys/firmware/efi' ]; then
    cat <<EOF
Your firmware is BIOS. This script only supports UEFI. If you intended to boot
in UEFI mode but booted in BIOS mode instead, reboot in the correct mode.
EOF
    exit 1
fi


cat <<EOF
To install with UEFI firmware, you must be connected to the internet. Please
make sure you are connected to the internet before continuing. If you cannot
connect, type 'n' at the prompt, and this script will exit.

EOF
if ! yn-y "Are you connected to the internet?"; then
    exit 0
fi


USE_TRIM=''
echo
echo
if yn-n "Are you installing on an SSD (rather than a hard disk)?"; then
    cat <<EOF

You can choose to enable TRIM on your SSD. Doing this may improve performance,
but at the cost of slightly reduced security. Read more at
https://wiki.archlinux.org/index.php/Dm-crypt/Specialties, section
'Discard/TRIM support for solid state drives (SSD)'.

As indicated by the warnings on that page, check that your SSD actually
supports TRIM before trying to enable it.

EOF
    if yn-n "Enable TRIM?"; then
        USE_TRIM='t'
    fi
fi


# Tutorial step 1 - disable the check that stops the installer from installing
# if there is no non-encrypted boot partition. The lines responsible are at the
# bottom of the config file, so we just remove them.
INSTALLER_CONFIG='/lib/partman/check.d/07crypto_check_mountpoints'
LINE="$(awk '/Is there a \/boot partition for encrypted root/ {print FNR}' "${INSTALLER_CONFIG}")"
# shellcheck disable=SC2015
test -n "${LINE}" &&
TMPFILE="$(mktemp)" &&
head -n "${LINE}" "${INSTALLER_CONFIG}" > "${TMPFILE}" &&
sudo mv "${TMPFILE}" "${INSTALLER_CONFIG}" || fail


# Tutorial step 2, part 1 - start the installer
KEYFILE='crypto_keyfile.bin'
# shellcheck disable=SC2015
cat <<EOF &&


The graphical installer is about to open. When it does, proceed as far as the
'Installation type' page, and select 'Something else'. Click next.

You now have two options, depending on what you want to do:


-------------------------------------------------------------------------------
1. Creating a new encrypted container (e.g. on a machine where you have never
done this before)

Leave the installer open and open a new terminal.

Ensure appropriate partitions exist, e.g. using cfdisk (don't use the installer
for this, it'll set up the encrypted partition incorrectly):

Make sure an EFI system partition exists.
 - if you are dual-booting, this was probably already created by the previous
   OS, in which case you don't need to do anything
 - otherwise you need to create a 512 MB partition with type 'EFI System'
   at the beginning of the disk, and format it using 'mkfs.fat'.
Take a note of the name of this partition (e.g. something like /dev/sda1 for
hard disks, or /dev/nvme0n1p1 for NVME SSDs), you will need it later.

Create new partitions with the desired properties for the encrypted container
(type should be 'Linux filesystem'), and set up encryption (encrypted using LUKS1, 
couldn't make it work with LUKS2 probably due to GRUB version). These partitions will be used for
the system (/) and swap:

    sudo cryptsetup luksFormat --type luks1 /dev/<partition_used_for_system>
    sudo cryptsetup open /dev/<partition> <partition_used_for_system>_crypt
    sudo cryptsetup luksFormat --type luks1 /dev/<partition_used_for_swap>
    sudo cryptsetup open /dev/<partition> <partition_used_for_swap>_crypt

This will open the encrypted containers on /dev/mapper/<partition_used_for_system>_crypt and /dev/mapper/<partition_used_for_swap>_crypt. Keep a
note of this - you will need it later. You can also list all the partitions, their types and UUIDs
with the following command:

    sudo blkid

Click 'Back' to return to the 'Installation Type' page.

Leave the installer open and switch back to this terminal.


-------------------------------------------------------------------------------
OR

2. Installing or reinstalling inside an existing encrypted container (e.g. one
created by a previous run of this script)

Click 'Back' in the installer to return to the 'Installation Type' page.

Leave the installer open and open a new terminal.

Open the encrypted volume(s) with:

    sudo cryptsetup open /dev/<partition> <partition>_crypt

where <partition> should be replaced by the appropriate partition. If you are
using this option, you will already know which partition to use.

If you have an existing keyfile from a previous installation in one of the
filesystems inside the encrypted partition, which can already be used to unlock
the container and which you want to reuse, open another terminal now and copy
it to ~/${KEYFILE}

Otherwise, a new keyfile will be created.


-------------------------------------------------------------------------------

Next, create filesystems on top of OS decrypted device and SWAP decrypted device. The ubiquty thinks that these are separate drives, 
so it will ask you to partition them (don't need that cause you do not use LVM). If you create the filesystem in advance then you will be able 
to format them again on one of the installer steps.

    sudo mkfs.btrfs /dev/mapper/<partition_used_for_system>_crypt
    sudo mkswap /dev/mapper/<partition_used_for_swap>_crypt

Press ENTER and the installer will open, and do as instructed above.
EOF

enter-to-continue || fail
sh -c 'ubiquity -b gtk_ui' &

# shellcheck disable=SC2015
cat <<EOF &&
Once you have done all that, press ENTER again to continue.
EOF

enter-to-continue || fail

# Let's assume that /dev/sda or /dev/nvme0n1p1 is an EFI system partition here

CRYPTDEV_OS="$(read-existing-path "Enter the path of the encrypted system device that you noted earlier; this will be something like /dev/mapper/sda2_crypt or /dev/mapper/nvme0n1p2_crypt, but the number may be different. MAKE SURE this is right, or the next set of instructions will probably make you erase your drive!")"
echo
CRYPTPART_OS="$(read-existing-path "Enter the path of the physical OS partition the encrypted container was created on; e.g. if the encrypted container is /dev/mapper/sda2_crypt, then this will be /dev/sda2 (i.e. the 'sda2' part matches), or if the encrypted container is /dev/mapper/nvme0n1p2_crypt, then this will be /dev/nvme0n1p2 (i.e. the 'nvme0n1p2' part matches)")"
echo
CRYPTDEV_SW="$(read-existing-path "Enter the path of the encrypted swap device that you noted earlier; this will be something like /dev/mapper/sda3_crypt or /dev/mapper/nvme0n1p3_crypt, but the number may be different. MAKE SURE this is right, or the next set of instructions will probably make you erase your drive!")"
echo
CRYPTPART_SW="$(read-existing-path "Enter the path of the physical swap partition the encrypted container was created on; e.g. if the encrypted container is /dev/mapper/sda3_crypt, then this will be /dev/sda3 (i.e. the 'sda3' part matches), or if the encrypted container is /dev/mapper/nvme0n1p3_crypt, then this will be /dev/nvme0n1p3 (i.e. the 'nvme0n1p3' part matches)")"
echo

UEFIBOOT="$(read-existing-path "Enter the path of the UEFI boot partition that you noted earlier; this will be something like /dev/sda1 or /dev/nvme0n1p1")"
echo
read -r -p "Enter the number of the UEFI boot partition that you noted earlier, e.g. if the partition is /dev/sda1 on a hard disk, enter 1, or /dev/nvme0n1p1 on an NVME SSD, enter 1 too: " UEFINUMBER || fail
if [ -z "${UEFINUMBER}" ]; then
    echo 'Invalid partition number'
    fail
fi

# shellcheck disable=SC2015
cat <<EOF &&

In the installer select the required partitions for /, swap and efi. Make sure to format / as btrfs!
This script mounts @ subvolume of BTRFS OS volume, if you don't format btrfs here then it will fail.

If this is clear, come back to this terminal and press ENTER to
continue.
EOF

enter-to-continue &&


# Tutorial step 2, part 2
cat <<EOF &&
Switch back into the installer. Select 'Something else' and click 'Continue'.
You may need to do 'Back' and 'Something else', 'Continue' several times before
your volumes show up.

Set up your partitions. Using the example names from the previous steps, you
will want to use:

/dev/mapper/<partition_used_for_system>_crypt as BTRFS journalling file system, formatted, and
mounted at /

/dev/mapper/<partition_used_for_swap>_crypt as swap area

(If there is a box at the bottom asking where to install the bootloader,
something has gone wrong! The installation will probably fail). Keep in mind that the script must be used to run the installer. The script 
changes a few configuration files before the installer runs to disable bootloader installation.

Click 'Install now', and continue with the rest of the installer.

When the installer finishes, click 'Continue testing', come back to this
terminal, and press ENTER to continue.

Waiting for installer to finish...
EOF

wait &&
enter-to-continue || fail


# Tutorial step 3
# shellcheck disable=SC2015
ROOTDEV="${CRYPTDEV_OS}" &&

sudo mount -o subvol=@ "${ROOTDEV}" /mnt &&
sudo mount --bind /dev /mnt/dev &&
sudo mount --bind /dev/pts /mnt/dev/pts &&
sudo mount --bind /sys /mnt/sys &&
sudo mount --bind /proc /mnt/proc &&
sudo mount --bind /run /mnt/run &&
sudo mount "${UEFIBOOT}" /mnt/boot/efi &&

# Since we don't tell the installer to install a bootloader, it doesn't know
# what kind we need. It therefore by default installs the packages for a bios
# bootloader - but we need the efi ones instead. We also have to make this
# config change before installing the package, or the package installation
# will fail.
sudo sed -i '10a GRUB_ENABLE_CRYPTODISK=y' /mnt/etc/default/grub &&
sudo chroot /mnt apt-get update &&
sudo chroot /mnt apt-get -y install grub-efi || fail

if [ -f "${HOME}/${KEYFILE}" ]; then
    sudo cp "${HOME}/${KEYFILE}" "/mnt/${KEYFILE}" || fail
else
    # shellcheck disable=SC2015
    sudo dd bs=512 count=4 if=/dev/urandom of="/mnt/${KEYFILE}" &&
    sudo cryptsetup luksAddKey "${CRYPTPART_OS}" "/mnt/${KEYFILE}" &&
    sudo cryptsetup luksAddKey "${CRYPTPART_SW}" "/mnt/${KEYFILE}" || fail
fi

# shellcheck disable=SC2015
sudo chmod 000 "/mnt/${KEYFILE}" &&
sudo chmod -R go-rwx /mnt/boot &&

echo "KEYFILE_PATTERN=\"/${KEYFILE}\"" | sudo tee -a /mnt/etc/cryptsetup-initramfs/conf-hook &&
echo "UMASK=0077" | sudo tee -a /mnt/etc/initramfs-tools/initramfs.conf || fail

if [ -n "${USE_TRIM}" ]; then
    echo "$(basename "${CRYPTDEV_OS}") UUID=$(sudo blkid -s UUID -o value "${CRYPTPART_OS}") /${KEYFILE} luks,discard" | sudo tee -a /mnt/etc/crypttab &>/dev/null &&
    echo "$(basename "${CRYPTDEV_SW}") UUID=$(sudo blkid -s UUID -o value "${CRYPTPART_SW}") /${KEYFILE} luks,discard" | sudo tee -a /mnt/etc/crypttab &>/dev/null || fail
else
    echo "$(basename "${CRYPTDEV_OS}") UUID=$(sudo blkid -s UUID -o value "${CRYPTPART_OS}") /${KEYFILE} luks" | sudo tee -a /mnt/etc/crypttab &>/dev/null && 
    echo "$(basename "${CRYPTDEV_SW}") UUID=$(sudo blkid -s UUID -o value "${CRYPTPART_SW}") /${KEYFILE} luks" | sudo tee -a /mnt/etc/crypttab &>/dev/null || fail
fi

# shellcheck disable=SC2015
sudo chroot /mnt locale-gen --purge --no-archive &&
sudo chroot /mnt update-initramfs -u &&

sudo sed -i.bak 's/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/' /mnt/etc/default/grub &&
sudo sed -i.bak 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/' /mnt/etc/default/grub || fail

if [ -n "${USE_TRIM}" ]; then
     sudo sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash cryptdevice=${CRYPTPART_OS}:$(basename "${CRYPTDEV_OS}"):allow-discards\"|" /mnt/etc/default/grub || fail
else
     sudo sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash cryptdevice=${CRYPTPART_OS}:$(basename "${CRYPTDEV_OS}")\"|" /mnt/etc/default/grub || fail
fi

# shellcheck disable=SC2015
sudo chroot /mnt update-grub &&
sudo chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --boot-directory=/boot --modules="all_video boot btrfs cat chain configfile crypto cryptodisk disk diskfilter echo efifwsetup efinet ext2 fat font gettext gcry_arcfour gcry_blowfish gcry_camellia gcry_cast5 gcry_crc gcry_des gcry_dsa gcry_idea gcry_md4 gcry_md5 gcry_rfc2268 gcry_rijndael gcry_rmd160 gcry_rsa gcry_seed gcry_serpent gcry_sha1 gcry_sha256 gcry_sha512 gcry_tiger gcry_twofish gcry_whirlpool gfxmenu gfxterm gfxterm_background gzio halt hfsplus iso9660 jpeg keystatus loadenv loopback linux linuxefi lsefi lsefimmap lsefisystab lssal luks lvm mdraid09 mdraid1x memdisk minicmd normal part_apple part_msdos part_gpt password_pbkdf2 png raid5rec raid6rec reboot search search_fs_uuid search_fs_file search_label sleep squash4 test true video zfs zfscrypt zfsinfo" --recheck &&

sudo umount /mnt/boot/efi /mnt/proc /mnt/dev/pts /mnt/dev /mnt/sys /mnt/run /mnt &&

cat <<EOF &&


Congratulations! The installation is now finished.

You should now be able to reboot and should be prompted for the password to
unlock the encrypted partition at boot.

For extra tips, see the appendices of the tutorial at:
https://community.linuxmint.com/tutorial/view/2061

For other scripts you can use to update the bootloader or to fix things if you
lose the ability to boot the system, see this script's original repository at:
https://github.com/calliecameron/mint-encrypted-install
EOF

enter-to-continue || fail

