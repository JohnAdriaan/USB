#USB

##USB sticks

USB sticks should be just as bootable as any other storage medium - as long as the BIOS supports it!

To that end, I've decided to collect a number of Master Boot Records (MBRs) for USB sticks that I own. Each `*.mbr` will simply be the 512-byte MBR at the beginning of each stick. If there's a `*.asm` with the same name, then it's a disassembly (courtesy of [NASM](http://www.nasm.us/)'s `ndisasm.exe` - edited with my comments).

For a very few cases, there may also be a Volume Boot Record (`*.vbr`).

It turns out that some USB sticks also come up as CD-ROMs, either in isolation or in addition to the drive. For those, I've added an `*.iso` file - no, not (necessarily) a complete image! I've only added sufficient (2 kiB) sectors that its peculiarities can be broken out. I'm assuming that the rest of the filesystem is 'normal'.
