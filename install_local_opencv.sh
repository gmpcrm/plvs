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

export OPENCV_VERSION="4.5.5"   # Use a compatible OpenCV version. Adjust if necessary.

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
        print_red "Warning: CUDA not found and will not be used!"
        CUDA_ON=OFF
    fi 
fi 

# Force CUDA off for Orange Pi unless you have CUDA installed
CUDA_ON=OFF

echo CUDA_ON: $CUDA_ON

# Pre-installing required packages 

sudo apt-get update

# Install base packages
sudo apt-get install -y pkg-config libtbb-dev libeigen3-dev
sudo apt-get install -y zlib1g-dev libjpeg-dev libwebp-dev libpng-dev libtiff5-dev
sudo apt-get install -y libglew-dev libopenblas-dev
sudo apt-get install -y curl software-properties-common unzip
sudo apt-get install -y build-essential cmake 
sudo apt-get install -y yasm libgtk2.0-dev libgtk-3-dev

# Install video and audio codecs and formats
sudo apt-get install -y libv4l-dev libdc1394-22-dev libtheora-dev libvorbis-dev \
                            libxvidcore-dev libx264-dev \
                            libopencore-amrnb-dev libopencore-amrwb-dev libxine2-dev

# For FFmpeg support
sudo apt-get install -y ffmpeg libavcodec-dev libavformat-dev libavutil-dev libpostproc-dev libswscale-dev

# Now let's download and compile OpenCV and opencv_contrib
cd $TARGET_FOLDER
if [ ! -f opencv/install/lib/libopencv_core.so ]; then
    if [ ! -d opencv ]; then
      wget https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip
      sleep 1
      unzip $OPENCV_VERSION.zip
      rm $OPENCV_VERSION.zip
      cd opencv-$OPENCV_VERSION

      wget https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.zip -O opencv_contrib.zip
      sleep 1
      unzip opencv_contrib.zip
      rm opencv_contrib.zip

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
    if [ "$machine" == "aarch64" ] || [ "$machine" == "arm64" ]; then
        echo "Building for arm64 on Ubuntu 20.04"
        cmake \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="`pwd`/../install" \
          -DOPENCV_EXTRA_MODULES_PATH="`pwd`/../opencv_contrib-$OPENCV_VERSION/modules" \
          -DWITH_QT=OFF \
          -DWITH_GTK=ON \
          -DWITH_OPENGL=OFF \
          -DWITH_TBB=ON \
          -DWITH_V4L=ON \
          -DWITH_FFMPEG=ON \
          -DWITH_GSTREAMER=ON \
          -DWITH_CUDA=$CUDA_ON \
          -DBUILD_opencv_cudacodec=OFF \
          -DENABLE_NEON=ON \
          -DENABLE_FAST_MATH=ON \
          -DBUILD_DOCS=OFF \
          -DBUILD_TESTS=OFF \
          -DBUILD_PERF_TESTS=OFF \
          -DINSTALL_PYTHON_EXAMPLES=OFF \
          -DINSTALL_C_EXAMPLES=OFF \
          -DBUILD_EXAMPLES=OFF \
          -DWITH_OPENCL=OFF \
          ..
    else
        echo "Building default configuration"
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
          -DWITH_CUDA=OFF \
          -DBUILD_opencv_cudacodec=OFF \
          -DENABLE_FAST_MATH=ON \
          -DBUILD_DOCS=OFF \
          -DBUILD_TESTS=OFF \
          -DBUILD_PERF_TESTS=OFF \
          -DINSTALL_PYTHON_EXAMPLES=OFF \
          -DINSTALL_C_EXAMPLES=OFF \
          -DBUILD_EXAMPLES=OFF \
          ..
    fi
    make -j$(nproc)
    make install 
fi

cd $STARTING_DIR

echo "...done with OpenCV"
