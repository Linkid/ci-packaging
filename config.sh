# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.

    #build_zlib
    build_libpng
    build_jpeg
    #build_simple gettext 0.19.8.1 http://ftp.gnu.org/gnu/gettext/ tar.gz
    #build_glib 2.54.2 http://ftp.gnome.org/pub/GNOME/sources/glib/2.54/ tar.xz
    #build_simple pkg-config 0.29.2 http://pkgconfig.freedesktop.org/releases/ tar.gz
    build_simple libogg 1.3.2 http://downloads.xiph.org/releases/ogg/ tar.gz
    build_simple libvorbis 1.3.5 http://downloads.xiph.org/releases/vorbis/ tar.gz
    build_flac 1.3.2 http://downloads.xiph.org/releases/flac/ tar.xz disable-cpplibs
    build_simple libsmf 1.3 http://download.sourceforge.net/libsmf/ tar.gz
    #build_soundtouch 2.0.0 http://www.surina.net/soundtouch/ tar.gz
    build_soundtouch 1.3.0 http://www.surina.net/soundtouch/ zip
    build_soundtouch 1.3.1 http://www.surina.net/soundtouch/ zip
    build_soundtouch 1.4.0 http://www.surina.net/soundtouch/ zip
    build_soundtouch 1.5.0 http://www.surina.net/soundtouch/ zip
    build_simple freetype 2.8.1 http://download.savannah.gnu.org/releases/freetype/ tar.bz2
    build_simple SDL 1.2.15 http://www.libsdl.org/release/ tar.gz
    build_simple SDL_mixer 1.2.12 http://www.libsdl.org/projects/SDL_mixer/release/ tar.gz
    build_simple SDL_ttf 2.0.11 http://www.libsdl.org/projects/SDL_ttf/release/ tar.gz
    build_simple SDL_image 1.2.12 http://www.libsdl.org/projects/SDL_image/release/ tar.gz
}

function build_glib {
    build_xz

    local name="glib"
    local version=$1
    local url=$2
    local ext=${3:-tar.gz}
    local configure_args=${@:4}
    if [ -e "${name}-stamp" ]; then
        return
    fi
    local name_version="${name}-${version}"
    local archive=${name_version}.${ext}
    fetch_unpack $url/$archive
    tar Jxf $archive
    (cd $name_version \
        && ./configure --prefix=$BUILD_PREFIX $configure_args \
        && make -C glib \
        && make -C gthread \
        && make -C glib install \
        && make -C gthread install)
    touch "${name}-stamp"
}

function build_flac {
    build_xz

    local name="flac"
    local version=$1
    local url=$2
    local ext=${3:-tar.gz}
    local configure_args=${@:4}
    if [ -e "${name}-stamp" ]; then
        return
    fi
    local name_version="${name}-${version}"
    local archive=${name_version}.${ext}
    fetch_unpack $url/$archive
    unxz $archive
    tar xf $name_version.tar
    (cd $name_version \
        && sed -i -e 's/AM_PATH_XMMS/true; dnl &/' configure.in \
        && autoreconf -fiv \
        && ./configure --prefix=$BUILD_PREFIX $configure_args \
        && make \
        && make install)
    touch "${name}-stamp"
}


function build_soundtouch {
    yum install -y \
        automake \
        autoconf \
        libtool \
        libtool-ltdl \
        libtool-ltdl-devel
    COMMON_AUTOCONF_FLAGS="--prefix=$BUILD_PREFIX --disable-static --enable-shared CPPFLAGS=-I$BUILD_PREFIX/include LDFLAGS=-L$BUILD_PREFIX/lib"
    local name="soundtouch"
    local version=$1
    local url=$2
    local ext=${3:-tar.gz}
    local configure_args=${@:4}
    if [ -e "${name}-stamp" ]; then
        return
    fi
    local name_version="${name}-${version}"
    local archive=${name_version}.${ext}
    #&& ./configure --prefix=$BUILD_PREFIX $configure_args \
    fetch_unpack $url/$archive
    (cd $name \
        && ./bootstrap \
        && ./configure $COMMON_AUTOCONF_FLAGS $configure_args \
        && make LDFLAGS=-no-undefined \
        && make install)
    #yum install -y soundtouch
    touch "${name}-stamp"
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    python setup.py test
}
