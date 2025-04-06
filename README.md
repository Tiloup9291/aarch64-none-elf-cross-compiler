# aarch64-none-elf-cross-compiler
YAACCT, Yet Another Aarch64 Cross-Compiler Toolchain.
## Preamble
Yes, you might ask yourself why you fall again on another aarch64-non-elf cross-compiler. Well, i had a need to build code for an aarch64 cpu running baremetal from my development PC with x86_64. I also need a lesser standard C library, so the choice fall for newlib.<br><br>
My development PC use a standard Linux Distro (Fedora). And also, i was starting from scratch. I followed a lot of tutorials only to realized they don't work for my case or are broken. A lot of them consider you are already running with newlib from your build host. What about it is not?<br><br>
That was my case!<br><br>
So, here is my reminder for myself and everyone finding it.<br><br>
My article will try to cover the steps starting from your base distro, to a 2 stage cross compiler building, to finally be able to cross-compile for target aarch64-none-elf with newlib from a x86_64 build host.<br><br>
The native distro gcc will be your bootstrap compiler and the native distro glibc will be the stage 1 library. Than, we will build binutils cross x86_64<->aarch64 to make the stage 1 compiler. Next we will build the stage 2 newlib library and finally build the stage 2 compiler with the help of the stage 1 compiler and stage 2 newlib. <br><br>
A complete from scratch toolchain as the following steps :
- 1. make linker and assembler for your host build
- 2. make a bootstrap compiler
- 3. make stage 1 library for headers
- 4. make linker and assembler for your target
- 5. make stage 1 cross-compiler
- 6. make stage 2 cross-library for libs and headers
- 7. make stage 2 cross-compiler.<br><br>

Since we need a toolchain from scratch but starting from an official distro, steps 1 to 3 are already make! :) <br><br>
All stage 2 resources are what you need to cross-compile sources code from your host build machine to your target.<br><br>
Additionnally, each cross build output give you tools for your host build architecture and your target architecture.<br><br>
So, instead of a three entities toolchain: build machine - host machine - target machine, we have a two entities toolchain : build and host machine - target machine.

## Prerequisites and compatibilities
To initially follow my architecture :<br>
- fedora 40, kernel 6.8.5-301<br>
- "build-essential" from official repo with package manager (dnf): `sudo dnf install @development-tools` <br>
- libtool from official repo with package manager (dnf): `sudo dnf install libtool` <br>
- glibc multilib from official repo with package manager (dnf): `sudo dnf install glibc-devel glibc-static libstdc++-devel libstdc++-static`<br>

---
# Build tree
```
~/cross-compiler
    |
    |----sources
    |
    |----host-tools
    |
    |----build
```
## Sources
Change directory to the sources directory.<br>
For this toolchain, we will need : binutils, gcc, gmp, isl, expat, mpfr, mpc and newlib.<br>
I like to download sources with wget! :)
```bash
wget https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.xz
wget https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz
wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
wget https://repo.or.cz/isl.git/snapshot/80035e4c3fcbebf13a70752111f03d48a5e46dda.tar.gz
wget https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.gz
wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz
wget https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
wget https://sourceware.org/pub/newlib/newlib-4.5.0.20241231.tar.gz
```
### Extract
Extract each source with `tar -xf <name of the tarball with suffix>`, add option z for .gz tarball.<br>
Each tarball will add a new folder inside your sources directory with the name of the resource the archive contained.<br>
Inside the folder of each resource, add a build folder for the configuration and building process.<br>
```
~/cross-compiler
    |
    |----sources
    |      |
    |      |----binutils-*
    |      |      |----build
    |      |      |----*
    |      |
    |      |----gcc-*
    |      |      |----build
    |      |      |----*
    |      |
    |      |----<all others resources>-*
    |      |
    |      |----<all tarball>.tar.**
    |
    |----host-tools
    |
    |----build
```

---
# Building the toolchain
## 1. GMP
Change directory to the build directory of your GMP.<br>
My configuration was : `../configure --disable-maintainer-mode --disable-shared --prefix=~/cross-compiler/host-tools --host=x86_64-none-linux-gnu`<br>
Than build : `make -j$(nproc) && make install && make distclean && rm -rf config.cache`<br>
GMP will be install in the host-tools directory of the toolchain.
## 2. MPFR
Change directory to the build directory of your MPFR.<br>
My configuration was : `../configure --disable-maintainer-mode --disable-shared --prefix=~/cross-compiler/host-tools --with-gmp=~/cross-compiler/host-tools`<br>
Than build : `make -j$(nproc) && make install && make distclean && rm -rf config.cache`<br>
MPFR will be install in the host-tools directory of the toolchain.
## 3. MPC
Change directory to the build directory of your MPC.<br>
My configuration was : `../configure --disable-maintainer-mode --disable-shared --prefix=~/cross-compiler/host-tools --with-gmp=~/cross-compiler/host-tools --with-mpfr=~/cross-compiler/host-tools`<br>
Than build : `make -j$(nproc) && make install && make distclean && rm -rf config.cache`<br>
MPC will be install in the host-tools directory of the toolchain.
## 4. ISL
Change directory to the root extracted folder of ISL. ISL probably need you to run his autogen script : `./autogen.sh`<br>
Additionnaly, i had to add a flag (LT_INIT) in the configure.ac script initialization section.<br>
Change directory to the build directory of your ISL.<br>
My configuration was : `../configure -disable-maintainer-mode --disable-shared --prefix=~/cross-compiler/host-tools --with-gmp-prefix=~/cross-compiler/host-tools`<br>
Than build : `make -j$(nproc) && make install && make distclean && rm -rf config.cache`<br>
ISL will be install in the host-tools directory of the toolchain.
## 5. BINUTILS (the fun begin here)
Change directory to the build directory of your BINUTILS.<br>
My configuration was : `-enable-64-bit-bfd --enable-targets=arm-none-eabi,aarch64-none-linux-gnu,aarch64-none-elf --enable-initfini-array --disable-nls --without-x --disable-gdbtk --without-tcl --without-tk --enable-plugins --disable-gdb --without-gdb --target=aarch64-none-elf --prefix=~/cross-compiler/build --with-bugurl="JohnDoe" --with-sysroot=~/cross-compiler/build/aarch64-none-elf --without-debuginfod`<br>
Than build : `make -j$(nproc) && make install && make distclean && rm -rf config.cache`<br>
BINUTILS will be install in the build directory of the toolchain.
## Intermission. Update PATH variable
Before going any further, we need to update the PATH environment variable. Because from now on, you want to use the tools that you installed and that you will continue to install in your toolchain directory instead of using your native distro tools. So add the absolute path of the toolchain of your build host bin folder in your ~/.bashrc and update the variable. Add `/home/path/to/the/cross-compiler/build/bin` to your ~/.bashrc. And update `source ~/.bashrc`
## 6. LIBEXPAT
Change directory to the build directory of your EXPAT.<br>
My configuration was : `--prefix=~/cross-compiler/host-tools --without-docbook --without-xmlwf`<br>
Than build : `make -j$(nproc) && make install && make distclean && rm -rf config.cache`<br>
EXPAT will be install in the host-tools directory of the toolchain.
## 7. GCC (stage 1)
Change directory to the build directory of your GCC.<br>
My configuration was : `--with-gmp=~/cross-compiler/host-tools --with-mpfr=~/cross-compiler/host-tools --with-mpc=~/cross-compiler/host-tools --with-isl=~/cross-compiler/host-tools --target=aarch64-none-elf --prefix=~/cross-compiler/build --disable-shared --disable-nls --disable-threads --disable-tls --enable-checking=release --enable-languages=c --without-cloog --without-isl --without-headers --with-gnu-as --with-gnu-ld --with-bugurl="JohnDoe"`<br>
Than build : `make -j$(nproc) all-gcc && make -j$(nproc) all-target-libgcc && make install-gcc && make install-target-libgcc && make distclean && rm -rf config.cache`<br>
GCC will be install in the build directory of the toolchain. Note 1 : i don't want threads support in my target, i will implement them. Note 2 : you will probably need to remove completely the sources root extracted directory of gcc and extract it again and make another build folder inside it. i'm pretty sure the make distclean don't remove everything and you will need fresh configuration for stage 2 later.
## 8. NEWLIB (stage 2)
Change directory to the build directory of your NEWLIB.<br>
My configuration was : `--target=aarch64-none-elf --disable-newlib-supplied-syscalls --enable-newlib-retargetable-locking --enable-newlib-reent-check-verify --enable-newlib-io-long-long --enable-newlib-io-long-double --enable-newlib-io-c99-formats --enable-newlib-register-fini --enable-newlib-mb --prefix=~/cross-compiler/build --with-bugurl="JohnDoe"`<br>
Than build : `make -j$(nproc) && make install && make distclean && rm -rf config.cache`<br>
NEWLIB will be install in the build directory of the toolchain.
## 9. GCC (stage 2)
Change directory to the build directory of your GCC.<br>
My configuration was : `-target=aarch64-none-elf --prefix=~/cross-compiler/build --with-gmp=~/cross-compiler/host-tools --with-mpfr=~/cross-compiler/host-tools --with-mpc=~/cross-compiler/host-tools --with-isl=~/cross-compiler/host-tools --disable-shared --disable-nls --disable-threads --disable-tls --enable-checking=release --enable-languages=c,c++,fortran --with-newlib --with-gnu-as --with-headers=yes --with-gnu-ld --with-native-system-header-dir=/usr/include --with-sysroot=~/cross-compiler/build/aarch64-none-elf --with-bugurl="JohnDoe"`<br>
Than build : `make -j$(nproc) all-gcc && make -j$(nproc) all-target-libgcc && make install-gcc && make install-target-libgcc && make distclean && rm -rf config.cache`<br>
GCC will be install in the build directory of the toolchain.

---
# Test
Make a simple hello.c text file and compile with `aarch64-none-elf-gcc hello.c -o hello.elf`:
```c
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```
Damn, it failed! the compiler is crying. Yes, because we remove all syscalls OS dependencies. You will need to implement those functions before building NEWLIB. That's the fun part, its your architecture. What is happening is the cross-compiler trying to add syscalls function to allocate memory(_sbrk), exit process (_exit), position buffer cursor(_lseek), read(_read) and write(_write) with prinft from the string to the stdout(_isatty,_fstat) and close the file descriptor(_close). You can add option `-nostartfiles` to gcc to stop the linker of adding syscall function to jump in/out to the process and allocate memory. But it will fail again because of printf. You have two choice : 1. implement all newlib syscalls or 2. use inline assembly. Lets try with inline assembly :
```c
#include <stdint.h>

int main() {
    const char *message = "Hello, World!\n";
    asm volatile (
        "mov x0, 1;"                  // File descriptor 1 (stdout)
        "mov x1, %0;"                 // Address of the message
        "mov x2, 14;"                 // Length of the message (14 bytes)
        "mov x8, 64;"                 // sys_write system call number (64)
        "svc 0;"                       // Make the system call
        :
        : "r"(message)                // Input: the message string
        : "x0", "x1", "x2", "x8"      // Clobbered registers
    );

    return 0;
}
```
Compile and don't add process control : `aarch64-none-elf-gcc hello.c -o hello.elf -nostartfiles`<br>
Boom! Compiled! Complete! Yes?<br><br>Well, no! You still make a syscall 64 with svc. So, i hope you have a supervior function that can manage this call or an OS. You now have 3 choices : 1. implement newlib syscall baremetal or OS API dependant 2. use inline assembly baremetal or OS API dependant 3. make an OS. The good news is the cross-compiler works! See you next time. ;) During this time, here is the proof of concept with a `readelf -C hello.elf` :
```
00000000  7f 45 4c 46 02 01 01 00  00 00 00 00 00 00 00 00  |.ELF............|
00000010  02 00 b7 00 01 00 00 00  00 00 40 00 00 00 00 00  |..........@.....|
00000020  40 00 00 00 00 00 00 00  a8 02 01 00 00 00 00 00  |@...............|
00000030  00 00 00 00 40 00 38 00  01 00 40 00 07 00 06 00  |....@.8...@.....|
00000040  01 00 00 00 05 00 00 00  00 00 01 00 00 00 00 00  |................|
00000050  00 00 40 00 00 00 00 00  00 00 40 00 00 00 00 00  |..@.......@.....|
00000060  47 00 00 00 00 00 00 00  47 00 00 00 00 00 00 00  |G.......G.......|
00000070  00 00 01 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000080  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00010000  ff 43 00 d1 00 00 00 90  00 e0 00 91 e0 07 00 f9  |.C..............|
00010010  e3 07 40 f9 20 00 80 d2  e1 03 03 aa c2 01 80 d2  |..@. ...........|
00010020  08 08 80 d2 01 00 00 d4  00 00 80 52 ff 43 00 91  |...........R.C..|
00010030  c0 03 5f d6 00 00 00 00  48 65 6c 6c 6f 2c 20 57  |.._.....Hello, W|
00010040  6f 72 6c 64 21 0a 00 47  43 43 3a 20 28 47 4e 55  |orld!..GCC: (GNU|
00010050  29 20 31 34 2e 32 2e 30  00 00 00 00 00 00 00 00  |) 14.2.0........|
00010060  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00010070  00 00 00 00 00 00 00 00  00 00 00 00 03 00 01 00  |................|
00010080  00 00 40 00 00 00 00 00  00 00 00 00 00 00 00 00  |..@.............|
00010090  00 00 00 00 03 00 02 00  38 00 40 00 00 00 00 00  |........8.@.....|
000100a0  00 00 00 00 00 00 00 00  00 00 00 00 03 00 03 00  |................|
000100b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
000100c0  01 00 00 00 04 00 f1 ff  00 00 00 00 00 00 00 00  |................|
000100d0  00 00 00 00 00 00 00 00  09 00 00 00 00 00 02 00  |................|
000100e0  38 00 40 00 00 00 00 00  00 00 00 00 00 00 00 00  |8.@.............|
000100f0  0c 00 00 00 00 00 01 00  00 00 40 00 00 00 00 00  |..........@.....|
00010100  00 00 00 00 00 00 00 00  1e 00 00 00 10 00 02 00  |................|
00010110  47 00 41 00 00 00 00 00  00 00 00 00 00 00 00 00  |G.A.............|
00010120  0f 00 00 00 10 00 02 00  47 00 41 00 00 00 00 00  |........G.A.....|
00010130  00 00 00 00 00 00 00 00  1d 00 00 00 10 00 02 00  |................|
00010140  47 00 41 00 00 00 00 00  00 00 00 00 00 00 00 00  |G.A.............|
00010150  5b 00 00 00 10 00 00 00  00 00 00 00 00 00 00 00  |[...............|
00010160  00 00 00 00 00 00 00 00  29 00 00 00 10 00 02 00  |........).......|
00010170  47 00 41 00 00 00 00 00  00 00 00 00 00 00 00 00  |G.A.............|
00010180  35 00 00 00 12 00 01 00  00 00 40 00 00 00 00 00  |5.........@.....|
00010190  34 00 00 00 00 00 00 00  3a 00 00 00 10 00 02 00  |4.......:.......|
000101a0  48 00 41 00 00 00 00 00  00 00 00 00 00 00 00 00  |H.A.............|
000101b0  42 00 00 00 10 00 02 00  47 00 41 00 00 00 00 00  |B.......G.A.....|
000101c0  00 00 00 00 00 00 00 00  49 00 00 00 10 00 02 00  |........I.......|
000101d0  48 00 41 00 00 00 00 00  00 00 00 00 00 00 00 00  |H.A.............|
000101e0  4e 00 00 00 10 00 02 00  00 00 08 00 00 00 00 00  |N...............|
000101f0  00 00 00 00 00 00 00 00  55 00 00 00 10 00 02 00  |........U.......|
00010200  47 00 41 00 00 00 00 00  00 00 00 00 00 00 00 00  |G.A.............|
00010210  00 68 65 6c 6c 6f 2e 63  00 24 64 00 24 78 00 5f  |.hello.c.$d.$x._|
00010220  5f 62 73 73 5f 73 74 61  72 74 5f 5f 00 5f 5f 62  |_bss_start__.__b|
00010230  73 73 5f 65 6e 64 5f 5f  00 5f 5f 62 73 73 5f 73  |ss_end__.__bss_s|
00010240  74 61 72 74 00 6d 61 69  6e 00 5f 5f 65 6e 64 5f  |tart.main.__end_|
00010250  5f 00 5f 65 64 61 74 61  00 5f 65 6e 64 00 5f 73  |_._edata._end._s|
00010260  74 61 63 6b 00 5f 5f 64  61 74 61 5f 73 74 61 72  |tack.__data_star|
00010270  74 00 00 2e 73 79 6d 74  61 62 00 2e 73 74 72 74  |t...symtab..strt|
00010280  61 62 00 2e 73 68 73 74  72 74 61 62 00 2e 74 65  |ab..shstrtab..te|
00010290  78 74 00 2e 72 6f 64 61  74 61 00 2e 63 6f 6d 6d  |xt..rodata..comm|
000102a0  65 6e 74 00 00 00 00 00  00 00 00 00 00 00 00 00  |ent.............|
000102b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
000102e0  00 00 00 00 00 00 00 00  1b 00 00 00 01 00 00 00  |................|
000102f0  06 00 00 00 00 00 00 00  00 00 40 00 00 00 00 00  |..........@.....|
00010300  00 00 01 00 00 00 00 00  34 00 00 00 00 00 00 00  |........4.......|
00010310  00 00 00 00 00 00 00 00  04 00 00 00 00 00 00 00  |................|
00010320  00 00 00 00 00 00 00 00  21 00 00 00 01 00 00 00  |........!.......|
00010330  02 00 00 00 00 00 00 00  38 00 40 00 00 00 00 00  |........8.@.....|
00010340  38 00 01 00 00 00 00 00  0f 00 00 00 00 00 00 00  |8...............|
00010350  00 00 00 00 00 00 00 00  08 00 00 00 00 00 00 00  |................|
00010360  00 00 00 00 00 00 00 00  29 00 00 00 01 00 00 00  |........).......|
00010370  30 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |0...............|
00010380  47 00 01 00 00 00 00 00  12 00 00 00 00 00 00 00  |G...............|
00010390  00 00 00 00 00 00 00 00  01 00 00 00 00 00 00 00  |................|
000103a0  01 00 00 00 00 00 00 00  01 00 00 00 02 00 00 00  |................|
000103b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
000103c0  60 00 01 00 00 00 00 00  b0 01 00 00 00 00 00 00  |`...............|
000103d0  05 00 00 00 07 00 00 00  08 00 00 00 00 00 00 00  |................|
000103e0  18 00 00 00 00 00 00 00  09 00 00 00 03 00 00 00  |................|
000103f0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00010400  10 02 01 00 00 00 00 00  62 00 00 00 00 00 00 00  |........b.......|
00010410  00 00 00 00 00 00 00 00  01 00 00 00 00 00 00 00  |................|
00010420  00 00 00 00 00 00 00 00  11 00 00 00 03 00 00 00  |................|
00010430  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00010440  72 02 01 00 00 00 00 00  32 00 00 00 00 00 00 00  |r.......2.......|
00010450  00 00 00 00 00 00 00 00  01 00 00 00 00 00 00 00  |................|
00010460  00 00 00 00 00 00 00 00                           |........|
00010468

```
