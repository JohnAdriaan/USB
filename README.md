#USB

##USB sticks

USB sticks should be just as bootable as any other storage medium - as long as the BIOS supports it!

To that end, I've decided to collect a number of Master Boot Records (MBRs) for USB sticks that I own. Each `*.mbr` will simply be the 512-byte MBR at the beginning of each stick. If there's a `*.asm` with the same name, then it's a disassembly (courtesy of [NASM](http://www.nasm.us/)'s `ndisasm.exe` - edited with my comments.

For a very few cases, there may also be a Volume Boot Record (`*.vbr`).
