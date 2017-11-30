# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    yum install -y \
        SDL_image-devel \
        SDL_ttf-devel \
        libvorbis-devel
    yum info SDL-devel
    build_simple SDL 1.2.15 http://www.libsdl.org/release/ tar.gz
    build_simple SDL_mixer 1.2.12 http://www.libsdl.org/projects/SDL_mixer/release/ tar.gz
    build_simple soundtouch 2.0.0 http://www.surina.net/soundtouch/ tar.gz
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    python setup.py test
}
