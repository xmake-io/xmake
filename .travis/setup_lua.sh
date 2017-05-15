#! /bin/bash

# A script for setting up environment for travis-ci testing.
# Sets up Lua and Luarocks.
# LUA must be "lua5.1", "lua5.2" or "luajit".
# luajit2.0 - master v2.0
# luajit2.1 - master v2.1

set -eufo pipefail

LUAJIT_BASE="LuaJIT-2.0.4"

source .travis/platform.sh

LUA_HOME_DIR=$TRAVIS_BUILD_DIR/install/lua

LR_HOME_DIR=$TRAVIS_BUILD_DIR/install/luarocks

mkdir $HOME/.lua

LUAJIT="no"

if [ "$PLATFORM" == "macosx" ]; then
  if [ "$LUA" == "luajit" ]; then
    LUAJIT="yes";
  fi
  if [ "$LUA" == "luajit2.0" ]; then
    LUAJIT="yes";
  fi
  if [ "$LUA" == "luajit2.1" ]; then
    LUAJIT="yes";
  fi;
elif [ "$(expr substr $LUA 1 6)" == "luajit" ]; then
  LUAJIT="yes";
fi

mkdir -p "$LUA_HOME_DIR"

if [ "$LUAJIT" == "yes" ]; then

  if [ "$LUA" == "luajit" ]; then
    curl http://luajit.org/download/$LUAJIT_BASE.tar.gz | tar xz;
  else
    git clone http://luajit.org/git/luajit-2.0.git $LUAJIT_BASE;
  fi

  cd $LUAJIT_BASE

  if [ "$LUA" == "luajit2.1" ]; then
    git checkout v2.1;
  fi

  make && make install PREFIX="$LUA_HOME_DIR"

  if [ "$LUA" == "luajit2.1" ]; then
    ln -s $LUA_HOME_DIR/bin/luajit-2.1.0-alpha $HOME/.lua/luajit
    ln -s $LUA_HOME_DIR/bin/luajit-2.1.0-alpha $HOME/.lua/lua;
  else
    ln -s $LUA_HOME_DIR/bin/luajit $HOME/.lua/luajit
    ln -s $LUA_HOME_DIR/bin/luajit $HOME/.lua/lua;
  fi;

else

  if [ "$LUA" == "lua5.1" ]; then
    curl http://www.lua.org/ftp/lua-5.1.5.tar.gz | tar xz
    cd lua-5.1.5;
  elif [ "$LUA" == "lua5.2" ]; then
    curl http://www.lua.org/ftp/lua-5.2.4.tar.gz | tar xz
    cd lua-5.2.4;
  elif [ "$LUA" == "lua5.3" ]; then
    curl http://www.lua.org/ftp/lua-5.3.1.tar.gz | tar xz
    cd lua-5.3.1;
  fi

  # Build Lua without backwards compatibility for testing
  perl -i -pe 's/-DLUA_COMPAT_(ALL|5_2)//' src/Makefile
  make $PLATFORM
  make INSTALL_TOP="$LUA_HOME_DIR" install;

  ln -s $LUA_HOME_DIR/bin/lua $HOME/.lua/lua
  ln -s $LUA_HOME_DIR/bin/luac $HOME/.lua/luac;

fi

cd $TRAVIS_BUILD_DIR

lua -v

LUAROCKS_BASE=luarocks-$LUAROCKS

curl --location http://luarocks.org/releases/$LUAROCKS_BASE.tar.gz | tar xz

cd $LUAROCKS_BASE

if [ "$LUA" == "luajit" ]; then
  ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.0" --prefix="$LR_HOME_DIR";
elif [ "$LUA" == "luajit2.0" ]; then
  ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.0" --prefix="$LR_HOME_DIR";
elif [ "$LUA" == "luajit2.1" ]; then
  ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.1" --prefix="$LR_HOME_DIR";
else
  ./configure --with-lua="$LUA_HOME_DIR" --prefix="$LR_HOME_DIR"
fi

make build && make install

ln -s $LR_HOME_DIR/bin/luarocks $HOME/.lua/luarocks

cd $TRAVIS_BUILD_DIR

luarocks --version

rm -rf $LUAROCKS_BASE

if [ "$LUAJIT" == "yes" ]; then
  rm -rf $LUAJIT_BASE;
elif [ "$LUA" == "lua5.1" ]; then
  rm -rf lua-5.1.5;
elif [ "$LUA" == "lua5.2" ]; then
  rm -rf lua-5.2.4;
elif [ "$LUA" == "lua5.3" ]; then
  rm -rf lua-5.3.1;
fi
