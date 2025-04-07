PREFIX = $(CURDIR)
.PHONY: start continue restart
start:
	@{ \
	##Prerequisites ;\
	echo $(PREFIX) ;\
	echo $(PATH) ;\
	sudo dnf install @development-tools ;\
	sudo dnf install libtool glibc-devel glibc-static libstdc++-devel libstdc++-static ;\
	sudo -k ;\
	##Build tree ;\
	mkdir cross-compiler cross-compiler/build cross-compiler/host-tools cross-compiler/sources ;\
	##Download sources ;\
	cd cross-compiler/sources ;\
	pwd ;\
	wget https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.xz ;\
	wget https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz ;\
	wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz ;\
	wget https://repo.or.cz/isl.git/snapshot/80035e4c3fcbebf13a70752111f03d48a5e46dda.tar.gz ;\
	wget https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.gz ;\
	wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz ;\
	wget https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz ;\
	wget https://sourceware.org/pub/newlib/newlib-4.5.0.20241231.tar.gz ;\
	##Extract sources ;\
	tar -xvf binutils-2.44.tar.xz ;\
	tar -xvf gcc-14.2.0.tar.xz ;\
	tar -xvf gmp-6.3.0.tar.xz ;\
	tar -xzvf 80035e4c3fcbebf13a70752111f03d48a5e46dda.tar.gz ;\
	tar -xzvf expat-2.7.1.tar.gz ;\
	tar -xvf mpfr-4.2.2.tar.xz ;\
	tar -xzvf mpc-1.3.1.tar.gz ;\
	tar -xzvf newlib-4.5.0.20241231.tar.gz ;\
	mkdir binutils-2.44/build gcc-14.2.0/build gmp-6.3.0/build isl-80035e4/build expat-2.7.1/build mpfr-4.2.2/build mpc-1.3.1/build newlib-4.5.0.20241231/build ;\
	##GMP ;\
	cd gmp-6.3.0/build ;\
	../configure --disable-maintainer-mode --disable-shared --prefix=$(PREFIX)/cross-compiler/host-tools --host=x86_64-none-linux-gnu ;\
	make -j$(nproc) && make install && make distclean ;\
	##MPFR ;\
	cd ../../mpfr-4.2.2/build ;\
	../configure --disable-maintainer-mode --disable-shared --prefix=$(PREFIX)/cross-compiler/host-tools --with-gmp=$(PREFIX)/cross-compiler/host-tools ;\
	make -j$(nproc) && make install && make distclean ;\
	## MPC ;\
	cd ../../mpc-1.3.1/build ;\
	../configure --disable-maintainer-mode --disable-shared --prefix=$(PREFIX)/cross-compiler/host-tools --with-gmp=$(PREFIX)/cross-compiler/host-tools --with-mpfr=$(PREFIX)/cross-compiler/host-tools ;\
	make -j$(nproc) && make install && make distclean ;\
	##ISL ;\
	cd ../../isl-80035e4 ;\
	./autogen.sh ;\
	sed '4a LT_INIT' configure.ac ;\
	aclocal ;\
	autoconf ;\
	automake --add-missing ;\
	cd build ;\
	../configure --disable-maintainer-mode --disable-shared --prefix=$(PREFIX)/cross-compiler/host-tools --with-gmp-prefix=$(PREFIX)/cross-compiler/host-tools ;\
	make -j$(nproc) && make install && make distclean ;\
	##BINUTILS ;\
	cd ../../binutils-2.44/build ;\
	../configure --enable-64-bit-bfd --enable-targets=arm-none-eabi,aarch64-none-linux-gnu,aarch64-none-elf --enable-initfini-array --disable-nls --without-x --disable-gdbtk --without-tcl \
	--without-tk --enable-plugins --disable-gdb --without-gdb --target=aarch64-none-elf --prefix=$(PREFIX)/cross-compiler/build --with-bugurl="JohnDoe" \
	--with-sysroot=$(PREFIX)/cross-compiler/build/aarch64-none-elf --without-debuginfod ;\
	make -j$(nproc) && make install && make distclean ;\
	echo "**************************************ATTENTION*************************************************" ;\
	echo "Please, before continuing, update your .bashrc and PATH variable by adding $(PREFIX)/cross-compiler/build/bin as first argument" ;\
	echo "************************************************************************************************" ;\
	echo "After, come back here and do : make continue" ;\
	echo "************************************************************************************************" ;\
	}
continue:
	@{ \
	##LIBEXPAT ;\
	cd cross-compiler/sources/expat-2.7.1/build ;\
	../configure --prefix=$(PREFIX)/cross-compiler/host-tools --without-docbook --without-xmlwf ;\
	make -j$(nproc) && make install && make distclean ;\
	##GCC stage1 ;\
	cd ../../gcc-14.2.0/build ;\
	../configure --with-gmp=$(PREFIX)/cross-compiler/host-tools --with-mpfr=$(PREFIX)/cross-compiler/host-tools --with-mpc=$(PREFIX)/cross-compiler/host-tools \
	--with-isl=$(PREFIX)/cross-compiler/host-tools --target=aarch64-none-elf --prefix=$(PREFIX)/cross-compiler/build --disable-shared --disable-nls --disable-threads --disable-tls --enable-checking=release --enable-languages=c\
	--without-cloog --without-isl --without-headers --with-gnu-as --with-gnu-ld --with-bugurl="JohnDoe" ;\
	make -j$(nproc) all-gcc && make -j$(nproc) all-target-libgcc && make install-gcc && make install-target-libgcc && make distclean ;\
	cd ../.. ;\
	rm -rf gcc-14.2.0 ;\
	tar -xvf gcc-14.2.0.tar.xz ;\
	mkdir gcc-14.2.0/build ;\
	##NEWLIB ;\
	cd newlib-4.5.0.20241231/build ;\
	../configure --target=aarch64-none-elf --disable-newlib-supplied-syscalls --enable-newlib-retargetable-locking --enable-newlib-reent-check-verify --enable-newlib-io-long-long \
	--enable-newlib-io-long-double --enable-newlib-io-c99-formats --enable-newlib-register-fini --enable-newlib-mb --prefix=$(PREFIX)/cross-compiler/build --with-bugurl="JohnDoe" ;\
	make -j$(nproc) && make install && make distclean ;\
	##GCC stage 2 ;\
	cd ../../gcc-14.2.0/build ;\
	../configure --target=aarch64-none-elf --prefix=$(PREFIX)/cross-compiler/build --with-gmp=$(PREFIX)cross-compiler/host-tools --with-mpfr=$(PREFIX)/cross-compiler/host-tools \
	--with-mpc=$(PREFIX)/cross-compiler/host-tools --with-isl=$(PREFIX)/cross-compiler/host-tools --disable-shared --disable-nls --disable-threads --disable-tls --enable-checking=release \
	--enable-languages=c,c++,fortran --with-newlib --with-gnu-as --with-headers=yes --with-gnu-ld --with-native-system-header-dir=/usr/include --with-sysroot=$(PREFIX)/cross-compiler/build/aarch64-none-elf --with-bugurl="JohnDoe" ;\
	make -j$(nproc) all-gcc && make -j$(nproc) all-target-libgcc && make install-gcc && make install-target-libgcc && make distclean ;\
	}
restart:
	rm -rvf cross-compiler
	
