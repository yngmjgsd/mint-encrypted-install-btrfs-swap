# The system installation example

This is an example of the script execution inside a VirtualBox VM + some examples of using **timeshit-autosnap-apt** and **grub-btrs** tools. After all, why install it on BTRFS if one can't use such things?

- Partition the disk. I created the ESP partition (1st one, 512MB), swap (2nd, 4GB), and root (3rd, all the remaining space on the disk). Use GPT partition table:

![1](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-001.png?raw=true)

- Setup crypto devices and create the filesystem on ESP

![2](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-002.png?raw=true)

- Create the filesystem on the root and swap devices. This is required because the **ubiquity** installer is sketchy and treats LUKS devices as drives, not partitions. It makes no sense to create partition tables on top of them and set BTRFS on partitions. So format them and they will be seen in **ubiquity** and available for installation

![3](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-003.png?raw=true)

- Start the script and specify the devices. I used this scheme (an explanation if you deal with LUKS for the first time ):

OS partitions:

1) EFI filesystem partition

ESP partition: **/dev/sda1**

2) OS data devices:

Crypto device: **/dev/mapper/sda3_crypt** # This is the block device that appears in the system when you decrypt the LUKS container.
Physical encrypted device: **/dev/sda3** # This is where the encrypted data is stored.

3) SWAP devices:

Crypto device: **/dev/mapper/sda2_crypt** # This is the block device that appears in the system when you decrypt the LUKS container.
Physical encrypted device: **/dev/sda2** # This is where the encrypted data is stored.

![4](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-004.png?raw=true)

- Go ahead and proceed until the step where you assign the filesystems. Specify swap

![5](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-005.png?raw=true)

- Specify root mount point **/**. Format it using BTRFS. This is mandatory! Even if you formatted it previously. This is because the installer creates **@** and **@home** subvolumes by default. These subvolumes are required for the **timeshift** to work (it doesn't work with the other layouts by the way). Also, the script (yes, the very same script you're using right now) mounts **/@** too to be used as **/** mount point.

![6](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-006.png?raw=true)

- Confirm the changes

![7](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-007.png?raw=true)

- Once it is installed do not reboot! Click 'Continue testing' and then return to the script prompt

![8](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-008.png?raw=true)

- Examine the output. You will be asked to enter the password for encrypted devices (two times, yes). I suggest using the same password (it makes no sense to specify different passwords for root and swap devices, it probably makes sense for separate home or other data partitions). When it comes to separate **/home** (maybe on a different disk) you can set it up later after the installation. Or even change the password for your LUKS devices. The script you're using now configures the system to unlock all LUKS devices (two devices to be specific) with a single password.

![9](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-009.png?raw=true)

- Done. I hope it is alright. Reboot the system

![10](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-010.png?raw=true)

- Success. Enter password.

![11](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-011.png?raw=true)

- It looks like it has been unencrypted successfully

![12](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-012.png?raw=true)

- We were able to boot. Good job!

![13](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-013.png?raw=true)

- The system is encrypted. I suggest you install **timeshift-autosnap-apt** and **grub-btrfs** packages to use BTRFS features to the full extent

![14](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-014.png?raw=true)

- Timeshift makes BTRFS snapshots correctly

![15](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-015.png?raw=true)

- The **timeshit-autosnap-apt** script also creates snapshots before upgrading/removing packages

![16](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-016.png?raw=true)

- **grub-btrs** also creates entries containing pre-upgrade system state

![17](https://raw.githubusercontent.com/yngmjgsd/mint-encrypted-install-btrfs-swap/master/screenshots/screenshot-017.png?raw=true)

Looks like it works and the job is done. Good luck with everything else.
