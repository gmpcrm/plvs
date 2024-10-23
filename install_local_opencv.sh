#!/usr/bin/env bash
# Author: Luigi Freda 

# ====================================================

function print_blue(){
    printf "\033[34;1m"
    printf "$@ \n"
    printf "\033[0m"
}

function print_red(){
    printf "\033[31;1m"
    printf "$@ \n"
    printf "\033[0m"
}

function check_package(){
    package_name=$1
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $package_name |grep "install ok installed")
    if [ "" == "$PKG_OK" ]; then
      echo 1
    else
      echo 0
    fi
}

function install_package(){
    do_install=$(check_package $1)
    if [ $do_install -eq 1 ] ; then
        sudo apt-get install -y $1
    fi 
}

function install_packages(){
    for var in "$@"
    do
        install_package "$var"
    done
}

function get_usable_cuda_version(){
    version="$1"
    if [[ "$version" != *"cuda"* ]]; then
        version="cuda-${version}"      
    fi 
    if [[ $version =~ ^[a-zA-Z0-9-]+\.[0-9]+\.[0-9]+$ ]]; then
        if [ ! -d /usr/local/$version ]; then 
            version="${version%.*}"  
        fi     
    fi    
    echo $version
}

# ====================================================

export TARGET_FOLDER=Thirdparty

export OPENCV_VERSION="4.10.0"   # OpenCV version to download and install. See tags in https://github.com/opencv/opencv 

# ====================================================
print_blue  "Configuring and building $TARGET_FOLDER/opencv ..."

set -e

STARTING_DIR=`pwd`
version=$(lsb_release -a 2>&1)

if [ ! -d $TARGET_FOLDER ]; then 
    mkdir $TARGET_FOLDER
fi 

# Set CUDA 
#export CUDA_VERSION="cuda-11.8"  
# must be an installed CUDA path in /usr/local; 
# if available, you can use the simple path "/usr/local/cuda" which should be a symbolic link to the last installed cuda version

CUDA_ON=OFF
if [[ -n "$CUDA_VERSION" ]]; then
    CUDA_VERSION=$(get_usable_cuda_version $CUDA_VERSION)
    echo using CUDA $CUDA_VERSION
    if [ ! -d /usr/local/$CUDA_VERSION ]; then 
        echo CUDA $CUDA_VERSION does not exist
        CUDA_ON=OFF
    else
        CUDA_ON=ON
    fi 
else
    if [ -d /usr/local/cuda ]; then
        CUDA_VERSION="cuda"
        echo using CUDA $CUDA_VERSION
        CUDA_ON=ON        
    else
        print_red "Warning: CUDA $CUDA_VERSION not found and will not be used!"
        CUDA_ON=OFF
    fi 
fi 

#forece CUDA off
CUDA_ON=OFF

echo CUDA_ON: $CUDA_ON
export PATH=/usr/local/$CUDA_VERSION/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/$CUDA_VERSION/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# Pre-installing required packages 

# Update the sources.list if Ubuntu 16.04 is detected
if [[ $version == *"16.04"* ]] ; then
    print_red "Warning: Ubuntu 16.04 (Xenial) is no longer supported."
    print_blue "Modifying /etc/apt/sources.list to use old-releases.ubuntu.com"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d%H%M%S)
    sudo sed -i 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//http:\/\/old-releases.ubuntu.com\/ubuntu\//g' /etc/apt/sources.list
    sudo sed -i 's/http:\/\/security\.ubuntu\.com\/ubuntu\//http:\/\/old-releases.ubuntu.com\/ubuntu\//g' /etc/apt/sources.list
fi

if [[ ! -d $TARGET_FOLDER/opencv ]]; then
    sudo apt-get update
    # Install base packages
    sudo apt-get install -y pkg-config libtbb-dev libeigen3-dev
    sudo apt-get install -y zlib1g-dev libjpeg-dev libwebp-dev libpng-dev libtiff5-dev
    sudo apt-get install -y libglew-dev libopenblas-dev
    sudo apt-get install -y curl software-properties-common unzip
    sudo apt-get install -y build-essential cmake 
    sudo apt-get install -y yasm libgtk2.0-dev

    # Install video and audio codecs and formats
    sudo apt-get install -y libv4l-dev libdc1394-22-dev libtheora-dev libvorbis-dev \
                            libxvidcore-dev libx264-dev \
                            libopencore-amrnb-dev libopencore-amrwb-dev libxine2-dev

    # For FFmpeg support
    DO_INSTALL_FFMPEG=$(check_package ffmpeg)
    if [ $DO_INSTALL_FFMPEG -eq 1 ] ; then
        echo "Installing ffmpeg and its dependencies"
        sudo apt-get install -y ffmpeg libavcodec-dev libavformat-dev libavutil-dev libpostproc-dev libswscale-dev
    fi

    if [[ "$CUDA_ON" == "ON" ]]; then 
        install_packages libcudnn8 libcudnn8-dev
    fi 

    if [[ $version == *"16.04"* ]] ; then
        # Specific packages for Ubuntu 16.04
        sudo apt-get install -y libpng12-dev libjasper-dev 
        if [ "$(uname -m)" == "aarch64" ]; then
            echo "Configuring for arm64 on Xenial..."
            sudo apt-get install -y libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libv4l-dev libgtk-3-dev
        fi
    fi
fi

# Now let's download and compile OpenCV and opencv_contrib
cd $TARGET_FOLDER
if [ ! -f opencv/install/lib/libopencv_core.so ]; then
    if [ ! -d opencv ]; then
      wget https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip
      sleep 1
      unzip $OPENCV_VERSION.zip
      rm $OPENCV_VERSION.zip
      cd opencv-$OPENCV_VERSION

      wget https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.zip
      sleep 1
      unzip $OPENCV_VERSION.zip
      rm $OPENCV_VERSION.zip

      cd ..
      mv opencv-$OPENCV_VERSION opencv
    fi
    echo "Entering OpenCV directory"
    cd opencv
    mkdir -p build
    mkdir -p install
    cd build
    echo "I am in "$(pwd)
    machine="$(uname -m)"
    if [[ "$version" == *"16.04"* && "$machine" == "aarch64" ]]; then
        echo "Building for arm64 on Xenial"
        cmake \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="`pwd`/../install" \
          -DOPENCV_EXTRA_MODULES_PATH="`pwd`/../opencv_contrib-$OPENCV_VERSION/modules" \
          -DWITH_QT=ON \
          -DWITH_GTK=OFF \
          -DWITH_OPENGL=ON \
          -DWITH_TBB=ON \
          -DWITH_V4L=ON \
          -DWITH_FFMPEG=ON \
          -DWITH_CUDA=$CUDA_ON \
          -DWITH_CUBLAS=$CUDA_ON \
          -DWITH_CUFFT=$CUDA_ON \
          -DCUDA_FAST_MATH=$CUDA_ON \
          -DBUILD_opencv_cudacodec=OFF \
          -DENABLE_FAST_MATH=1 \
          -DBUILD_DOCS=OFF \
          -DBUILD_TESTS=OFF \
          -DBUILD_PERF_TESTS=OFF \
          -DINSTALL_PYTHON_EXAMPLES=OFF \
          -DINSTALL_C_EXAMPLES=OFF \
          -DBUILD_EXAMPLES=OFF \
          -Wno-deprecated-gpu-targets ..
    elif [ "$machine" == "x86_64" ]; then
        echo "Building x86_64 config"
        cmake \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="`pwd`/../install" \
          -DOPENCV_EXTRA_MODULES_PATH="`pwd`/../opencv_contrib-$OPENCV_VERSION/modules" \
          -DWITH_QT=ON \
          -DWITH_GTK=OFF \
          -DWITH_OPENGL=ON \
          -DWITH_TBB=ON \
          -DWITH_V4L=ON \
          -DWITH_FFMPEG=ON \
          -DWITH_CUDA=$CUDA_ON \
          -DWITH_CUBLAS=$CUDA_ON \
          -DWITH_CUFFT=$CUDA_ON \
          -DCUDA_FAST_MATH=$CUDA_ON \
          -DBUILD_opencv_cudacodec=OFF \
          -DENABLE_NEON=ON \
          -DENABLE_FAST_MATH=ON \
          -DBUILD_DOCS=OFF \
          -DBUILD_TESTS=OFF \
          -DBUILD_PERF_TESTS=OFF \
          -DINSTALL_PYTHON_EXAMPLES=OFF \
          -DINSTALL_C_EXAMPLES=OFF \
          -DBUILD_EXAMPLES=OFF \
          -Wno-deprecated-gpu-targets ..
    fi
    make -j$(nproc)
    make install 
fi

cd $STARTING_DIR

echo "...done with OpenCV"
