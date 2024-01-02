#!/bin/sh
## based on: https://gist.github.com/eminence/85961d47244a140fde89314837d0db0a

set -e # Immediately exit if any command has non-0 exit status

wd=`pwd`
dl_dir=$wd/downloads

download () {
    filename=`basename $1`
    mkdir -p $dl_dir
    if [ -e $dl_dir/$filename ]; then
        echo "$filename already downloaded, skipping."
        return 0
    fi
    echo "Downloading $filename:"
    curl -o $dl_dir/$filename -L $1
}

echo -n "Will download things into $dl_dir. This includes cross-compiling tools, which are chunky (100MB+ download). OK? [y/N] "
read do_dl
if [ "$do_dl" == "y" ]; then
    # Deps
    download https://www.zlib.net/zlib-1.2.13.tar.gz
    download https://invisible-island.net/datafiles/release/ncurses.tar.gz
    download https://github.com/openssl/openssl/releases/download/openssl-3.1.1/openssl-3.1.1.tar.gz
    download https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
    download https://github.com/protocolbuffers/protobuf/releases/download/v21.12/protobuf-all-21.12.tar.gz
    # The good stuff
    download https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz
    download https://github.com/mobile-shell/mosh/releases/download/mosh-1.4.0/mosh-1.4.0.tar.gz
    # Cross-compiler tools
    download https://musl.cc/riscv64-linux-musl-cross.tgz

    echo -e "\nHere's what was downloaded:"
    file downloads/* | grep -v "directory"
 
    echo -e "\nUnpacking..."
    (cd downloads; ls *.tgz *.tar.gz | parallel tar -zxf)
else
  echo -e "\nSkipping download, presumably you already did it.\n"
fi 

    zlib_src_dir="$wd/$(ls -d downloads/*/ | grep zlib    )";    echo $zlib_src_dir
 ncurses_src_dir="$wd/$(ls -d downloads/*/ | grep ncurses )";    echo $ncurses_src_dir
 openssl_src_dir="$wd/$(ls -d downloads/*/ | grep openssl )";    echo $openssl_src_dir
libevent_src_dir="$wd/$(ls -d downloads/*/ | grep libevent)";    echo $libevent_src_dir
protobuf_src_dir="$wd/$(ls -d downloads/*/ | grep protobuf)";    echo $protobuf_src_dir

    tmux_src_dir="$wd/$(ls -d downloads/*/ | grep tmux    )";    echo $tmux_src_dir
    mosh_src_dir="$wd/$(ls -d downloads/*/ | grep mosh    )";    echo $mosh_src_dir

          xc_dir="$wd/$(ls -d downloads/*/ | grep riscv64 )";    echo $xc_dir


install_dir=$wd/prefix


echo "------------------------------------------------------------------------"
echo "Ready to start building the packages?"
echo "Everything will be installed to $install_dir"
echo "Temporary build dir: $wd"
echo "Press enter to continue, or ctrl-c to exit"
read c

export PATH="$PATH:$install_dir/bin"
export PATH="$PATH:$xc_dir/bin"

export  CC=riscv64-linux-musl-gcc 
export CXX=riscv64-linux-musl-g++

export CFLAGS="-I$install_dir/include -fPIC"
export CXXFLAGS=$CFLAGS
export LDFLAGS="-L$install_dir/lib -Wl,-rpath,$install_dir/lib"
export PKG_CONFIG_PATH="$install_dir/lib/pkgconfig"
export LD_LIBRARY_PATH="$install_dir/lib"

MAKEOPTS=-j4


echo -e "\nNext package to build: zlib.\nPress enter to continue, or "s" to skip."
read c
if [ "$c" != "s" ]; then
    cd $zlib_src_dir
    make clean || echo
    ./configure --prefix=$install_dir \
        --static
    make $MAKEOPTS && make install
fi

echo -e "\nNext package to build: OpenSSL.\nPress enter to continue, or "s" to skip."
read c
if [ "$c" != "s" ]; then
    cd $openssl_src_dir
    make clean || echo
    ./config linux64-riscv64 no-shared --prefix=$install_dir \
        -fPIC 
    make $MAKEOPTS && make install
fi

echo -e "\nNext package to build: ncurses (without the w).\nPress enter to continue, or "s" to skip."
read c
if [ "$c" != "s" ]; then
    cd $ncurses_src_dir
    make clean || echo
    ./configure --prefix=$install_dir \
        --build=x86_64-unknown-linux-gnu --host=riscv64-unknown-linux-musl \
        --with-build-cc=/usr/bin/gcc --with-build-cpp=/usr/bin/cpp --with-build-cflags="" --with-build-cppflags="" --with-build-ldflags="" \
        --enable-ext-colors --without-shared --without-gpm
    make $MAKEOPTS && make sources
fi

echo -e "\nNext package to build: ncursesw (with a w).\nPress enter to continue, or "s" to skip."
read c
if [ "$c" != "s" ]; then
    cd $ncurses_src_dir
    make clean || echo
    ./configure --prefix=$install_dir \
        --build=x86_64-unknown-linux-gnu --host=riscv64-unknown-linux-musl \
        --with-build-cc=/usr/bin/gcc --with-build-cpp=/usr/bin/cpp --with-build-cflags="" --with-build-cppflags="" --with-build-ldflags="" \
        --enable-widec --enable-ext-colors --without-shared --without-gpm
    make $MAKEOPTS && make sources
fi

echo -e "\nNext package to build: libevent.\nPress enter to continue, or "s" to skip."
read c
if [ "$c" != "s" ]; then
    cd $libevent_src_dir
    make clean || echo
    ./autogen.sh
    ./configure --prefix=$install_dir \
        --build=x86_64-unknown-linux-gnu --host=riscv64-unknown-linux-musl \
        --disable-shared
  make $MAKEOPTS && make
fi

echo -e "\nNext package to build: protobuf (Google protocol buffers).\nPress enter to continue, or "s" to skip."
read c
if [ "$c" != "s" ]; then
    cd $protobuf_src_dir
    make clean || echo
    # In order to cross-compile this, a pre-compiled "protoc" executable of the same version on the ~host~ is needed.
    # Thus, we need to build protobuf twice, once for the host's platform and ~then~ for our target's.
    # TODO: Don't assume the user already has protoc, build a host's-platform one and use it for --with-protoc. If you're using this script and have protoc errors just ask and I'll fix this but until anyone needs it I'm lazy.
    ./configure --prefix=$install_dir \
        --build=x86_64-unknown-linux-gnu --host=riscv64-unknown-linux-musl \
        --with-protoc=protoc --disable-shared
    make $MAKEOPTS && make install
fi


echo -e "\nAlmost there! Next package to build: tmux.\nPress enter to continue, or "s" to skip."
read c
if [ "$c" != "s" ]; then
  cd $tmux_src_dir
  make clean || echo
  ./configure --prefix=$install_dir \
      --build=x86_64-unknown-linux-gnu --host=riscv64-unknown-linux-musl \
      CFLAGS="-I$install_dir/include/ncurses -I$install_dir/include -fPIC" `# Needs help finding ncurses.h`\
      --enable-static
  make $MAKEOPTS && make install
fi

echo -e "\nNow we can finally build mosh!\nPress enter to continue, or "s" to skip."
read c
if [ "$c" != "s" ]; then
    cd $mosh_src_dir
    make clean || echo 
    ./configure --prefix=$install_dir \
        --build=x86_64-unknown-linux-gnu --host=riscv64-unknown-linux-musl \
        CFLAGS="-I$install_dir/include/ncurses -I$install_dir/include" `# Doesn't like -fPIC. Also can't find ncurses.h.`\
        CXXFLAGS="-I$install_dir/include/ncurses -I$install_dir/include" \
        --with-ncursesw --enable-static-libraries
    make $MAKEOPTS && make install
    echo -e "\nMosh done!"
fi


echo "Everything done!"
echo "Installed to $install_dir"

echo "Hold on though! mosh-client is 16MB, which won't fit in OC2:"
ls -lh prefix/bin/mosh*
echo "Strip the executable of some symbols to slim it down? [Y/n]"
read c
if [ "$c" != "n" ]; then
    riscv64-linux-musl-strip --strip-unneeded prefix/bin/mosh-client
    echo "That's better:"
    ls -lh prefix/bin/mosh-client
fi
