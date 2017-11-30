# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    yum install -y \
        SDL \
        SDL-devel \
        SDL_image-devel \
        SDL_mixer-devel \
        SDL_ttf-devel \
        libvorbis-devel
    yum info SDL-devel
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    python setup.py test
}
