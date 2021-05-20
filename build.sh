#!bash

##
# Build decNumber as static and shared library.
#
# This script assumes Unix or MinGW environment.
#
# Requires bash shell (string list stuff, mostly).
#
# Clang: nothing to do, compiles clean.
# GCC: only use -O2, and apply patches.
#
# The build and install directories will be created if they do not exist.
#
# TODO: DECLITEND must be defined as 0 for big-endian systems.
#
# TODO: For MSVC, W3 and W4 complain, W2 will compile clean.
# cl /W2 /O2 /nologo

INSTALL_DIR="install"
BUILD_DIR="build"
STATIC_LIB="libdecnum.a"
SHARED_LIB="libdecnum.so"
DECNUM_DIR="decNumber-icu-368"

# Clang build
CC=clang
CFLAGS="-Wall -Wextra -O3"

# GCC build
#CC=gcc
#CFLAGS="-Wall -Wextra -O2"

# decBasic.c and decCommon.c are included by other sources.
# Same name for .c, .h, and .o files.
SRCS=(
  decContext
  decNumber
  decimal32
  decimal64
  decimal128
  decSingle
  decDouble
  decQuad
  decPacked
)

if [ ! -d ${INSTALL_DIR} ]; then
  mkdir -p ${INSTALL_DIR}
fi

if [ ! -d ${BUILD_DIR} ]; then
  mkdir -p ${BUILD_DIR}
fi

ORIG_DIR=`pwd`
cd ${BUILD_DIR}

# Compile.
for i in "${SRCS[@]}"; do
  echo "${CC} ${CFLAGS} -c ${i}.c" ; ${CC} ${CFLAGS} -c ${ORIG_DIR}/${DECNUM_DIR}/${i}.c
done

if [ -f ${STATIC_LIB} ]; then
  rm ${STATIC_LIB}
fi

if [ -f ${SHARED_LIB} ]; then
  rm ${SHARED_LIB}
fi


# There is probably a better way to make a list of .o files.
OBJLIST=""
for i in "${SRCS[@]}"; do
  OBJLIST="${OBJLIST} ${i}.o"
done

# Make the static lib.
echo "Making static lib ${STATIC_LIB}"
ar -cq ${STATIC_LIB} ${OBJLIST}

# Make a shared lib.
echo "Making shared lib ${SHARED_LIB}"
${CC} -fPIC --shared -o ${SHARED_LIB} ${OBJLIST}


# Install.
cd ${ORIG_DIR}

echo "Installing ${STATIC_LIB} to ${INSTALL_DIR}"
cp ${BUILD_DIR}/${STATIC_LIB} ${INSTALL_DIR}

echo "Installing ${SHARED_LIB} to ${INSTALL_DIR}"
cp ${BUILD_DIR}/${SHARED_LIB} ${INSTALL_DIR}

echo "Installing headers to ${INSTALL_DIR}"
for i in "${SRCS[@]}"; do
  cp ${DECNUM_DIR}/${i}.h ${INSTALL_DIR}
done
