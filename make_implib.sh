#!/bin/bash

# see https://stackoverflow.com/a/53838952/5222966
# Given libxyz-1.dll, create import library libxyz-1.lib
# make_implib i386 usr/i686-w64-mingw32/sys-root/mingw/bin/libgnutls-30.dll
make_implib() {
    local machine=$1 dll="$2" dlla=$3 dllname dllaname name deffile libfile

    working_dir=$(dirname "${dll}")
    dllname="${dll##*/}"
    dllaname="${dlla##*/}"
    name="${dllaname#lib}"
    deffile="${working_dir}/lib/${name}.def"
    libfile="${working_dir}/lib/${name}.lib"
    echo $dll
    echo $dllname
    echo $deffile
    echo $libfile

    # Extract exports from the .edata section, writing results to the .def file.
    LC_ALL=C objdump -p "$dll" | awk -vdllname="$dllname" '
    /^\[Ordinal\/Name Pointer\] Table$/ {
        print "LIBRARY " dllname
        print "EXPORTS"
        p = 1; next
    }
    p && /^\t\[ *[0-9]+\] [a-zA-Z0-9_]+$/ {
        gsub("\\[|\\]", "");
        print "    " $2 " @" $1;
        ++p; next
    }
    p > 1 && /^$/ { exit }
    p { print "; unexpected objdump output:", $0; exit 1 }
    END { if (p < 2) { print "; cannot find export data section"; exit 1 } }
    ' > "$deffile"

    # Create .lib suitable for MSVC. Cannot use binutils dlltool as that creates
    # an import library (like the one found in lib/*.dll.a) that results in
    # broken executables. For example, assume executable foo.exe that uses fnA
    # (from liba.dll) and fnB (from libb.dll). Using link.exe (14.00.24215.1)
    # with these broken .lib files results in an import table that lists both
    # fnA and fnB under both liba.dll and libb.dll. Use of llvm-dlltool creates
    # the correct archive that uses Import Headers (like official MS tools).
    llvm-dlltool -m "$machine" -d "$deffile" -l "$libfile"
    rm -f "$deffile"
}



# bin/*.dll
# lib/*.a
# lib/*.dll.a
# lib/*.lib
# lib/*.exp
# lib/*.def
# lib/pkgconfig/*.pc

# vorbisfile:
# bin/libvorbisfile-3.dll   dll / output of dlltool
# lib/vorbisfile.pc         pc
# lib/libvorbisfile.dll.a   implib / dlla
# lib/vorbisfile.def        def
# lib/vorbisfile.exp        exp
# lib/vorbisfile.lib        lib

arch=$1
working_dir=$2
implibs=`ls ${working_dir}/lib/libvorbisfile.dll.a`
#implibs=`ls ${working_dir}/lib/*.dll.a`
for implib in $implibs
do
    echo "*** ${implib}"

    # get dll names from the dll.a
    dll_a_name="${implib##*/}"
    dllnames=`dlltool -I ${implib}`

    # make the lib file
    for dll in $dllnames
    do
        # make implib
        make_implib $arch "$working_dir/bin/$dll" $dll_a_name
    done
done
