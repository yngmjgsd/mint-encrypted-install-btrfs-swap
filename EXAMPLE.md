This is an example of the script execution inside a VirtualBox VM + some examples of using timeshit-autosnap-apt and grub-btrs tools. After all, why install it on BTRFS if one can't use such things?

- Partition the disk. I created ESP partition (1st one, 512MB), swap (2nd, 4GB) and root (3rd, all the remaining space on the disk). Use GPT partition table:

screenshot-001.png

- Setup crypto devices and create the filesystem on ESP

screenshot-002.png

- Create the filesystem on the root and swap devices. This is required because ubiquity installer is sketchy and treats LUKS devices as drives, not partitions. It makes no sense to create partition tables on top of them and setup BTRFS on partitions. So just format them and they will be seen in ubiquity and available for installation

screenshot-003.png

- Start the script and specify the devices. I used this scheme (a few explanations if you deal with LUKS for the first time ):

OS partitions:

1) EFI filesysten partition

ESP partition: /dev/sda1

2) OS data devices:

Crypto device: /dev/mapper/sda3_crypt # this is the block device that appears in the system when you decrypt the LUKS container 
Physical encrypted device: /dev/sda3 # this is where the encrypted data is stored

3) SWAP devices:

Crypto device: /dev/mapper/sda2_crypt # this is the block device that appears in the system when you decrypt the LUKS container
Physical encrypted device: /dev/sda2 # this is where the encrypted data is stored

screenshot-004.png

- Proceed until the point where you need to assign the filesystems. Specify swap

screenshot-005.png

- Specify root mountpoint / . Format it using BTRFS. This is mandatory! Even if you formatted it previously. This is because the installer creates @ and @home subvolumes by default. These subvolumes are required for timeshift to work (it doesn't work with the other layouts). Also, the script (yes, the very same script you're using right now) mounts /@ too to be used as / mountpoint. So, format it anyway

screenshot-006.png

- Confirm the changes

screenshot-007.png

- Once it is installed do not reboot! Click 'Continue testing' and then return to the script prompt

screenshot-008.png

- Examine the output. You will be asked to enter the password for crypted devices (two times, yes). I suggest you use the same password (makes no sense to specify different passwords for OS devices anyway). When it comes to separate /home (maybe on a different disk) you can set it up later after the installation. Or even change password for your LUKS devices. The script that you're using right now configures the system in a way to unlock all LUKS devices (two devices to be specific) with a single password.

screenshot-009.png

- Done. Hope it is alright. Reboot the system

screenshot-010.png

- Success. Enter password.

screenshot-011.png

- Looks like it has been unencrypted successfully

screenshot-012.png

- We were able to boot. Good job!

screenshot-013.png

- The system is encrypted. I suggest you install timeshift-autosnap-apt and grub-btrfs packages to use BTRFS features to the full extent

screenshot-014.png

- Timeshift makes BTRFS snapshots

screenshot-015.png

- timeshit-autosnap-apt script also creates snapshots before upgarding/removing packages

screenshot-016.png

- grub-btrs also show entries containing pre-upgrade system state

screenshot-017.png

Looks like it works and the job is done.