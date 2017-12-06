# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.

    #build_zlib
    build_libpng
    build_jpeg
    #build_simple gettext 0.19.8.1 http://ftp.gnu.org/gnu/gettext/ tar.gz
    build_gettext
    build_simple libffi 3.2.1 ftp://sourceware.org/pub/libffi/ tar.gz --enable-portable-binary
    build_glib 2.54.2 http://ftp.gnome.org/pub/GNOME/sources/glib/2.54/ tar.xz
    #build_simple pkg-config 0.29.2 http://pkgconfig.freedesktop.org/releases/ tar.gz
    build_simple libogg 1.3.2 http://downloads.xiph.org/releases/ogg/ tar.gz
    build_simple libvorbis 1.3.5 http://downloads.xiph.org/releases/vorbis/ tar.gz
    #build_flac 1.3.2 http://downloads.xiph.org/releases/flac/ tar.xz disable-cpplibs
    build_simple libsmf 1.3 http://download.sourceforge.net/libsmf/ tar.gz
    #build_soundtouch 2.0.0 http://www.surina.net/soundtouch/ tar.gz
    build_soundtouch
    build_simple freetype 2.8.1 http://download.savannah.gnu.org/releases/freetype/ tar.bz2
    build_simple SDL 1.2.15 http://www.libsdl.org/release/ tar.gz
    build_simple SDL_mixer 1.2.12 http://www.libsdl.org/projects/SDL_mixer/release/ tar.gz
    build_simple SDL_ttf 2.0.11 http://www.libsdl.org/projects/SDL_ttf/release/ tar.gz
    build_simple SDL_image 1.2.12 http://www.libsdl.org/projects/SDL_image/release/ tar.gz
}

function fetch_xz {
    # Fetch input archive name from input URL
    # Parameters
    #    url - URL from which to fetch archive
    #    archive_fname (optional) archive name
    #
    # If `archive_fname` not specified then use basename from `url`
    # If `archive_fname` already present at download location, use that instead.
    local url=$1
    if [ -z "$url" ];then echo "url not defined"; exit 1; fi
    local archive_fname=${2:-$(basename $url)}
    local arch_sdir="${ARCHIVE_SDIR:-archives}"
    # Make the archive directory in case it doesn't exist
    mkdir -p $arch_sdir
    local out_archive_xz="${arch_sdir}/${archive_fname}"
    local out_archive_tar=${out_archive_xz%.*}
    # Fetch the archive if it does not exist
    if [ ! -f "$out_archive_xz" ]; then
        curl -L $url > $out_archive_xz
    fi
    # Unpack archive, refreshing contents
    rm_mkdir arch_tmp
    (cd arch_tmp && unxz ../$out_archive_xz && tar xf ../$out_archive_tar && rsync --delete -avh * ..)
}


function build_gettext {
    yum install -y gettext-devel
    touch gettext-stamp
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
    fetch_xz $url/$archive
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
    fetch $url/$archive
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
    if [ -e soundtouch-stamp ]; then return; fi
    rpm -Uvh http://repository.it4i.cz/mirrors/repoforge/redhat/el5/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el5.rf.x86_64.rpm
    #rpm -Uvh http://repository.it4i.cz/mirrors/repoforge/redhat/el5/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el5.rf.i386.rpm
    yum install -y soundtouch-devel
    touch soundtouch-stamp
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    sources_dir=$(dirname $(python -c 'import fretwork; print(fretwork.__file__)'))
    echo $sources_dir
    ls $sources_dir
    #(cd $sources_dir && python setup.py test)
    python -c 'import sys; import fretwork; from fretwork.mixstream import *'
}
