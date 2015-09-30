#!/bin/bash

set -o nounset
set -o errexit

if [ "$#" -ne 1 ]; then
    echo "Missing def file"
fi

DEFS=$1

declare -A OPTS
declare -A CONFIGURE
declare -A SOURCES
declare -A BRANCHES

source "$DEFS"

CHANGED=""

mkdir -p dl
cd dl

for MODULE in ${!SOURCES[@]}; do
    echo ========== Updating $MODULE ================
    URL=${SOURCES[$MODULE]}
    BRANCH=${BRANCHES[$MODULE]-master}
    BASENAME=`basename $URL`
    if [[ "$URL" =~ ^git: ]]; then
        if ! test -d $BASENAME.git; then
            git clone --mirror $URL --single-branch --branch $BRANCH
            CHANGED="$CHANGED $MODULE"
        else
            cd $BASENAME.git
            OLD_REV=""
            git rev-parse -q --verify refs/heads/$BRANCH && OLD_REV=`git rev-parse $BRANCH`
            git fetch origin $BRANCH
            if [ $OLD_REV != $(git rev-parse $BRANCH) ]; then
                CHANGED="$CHANGED $MODULE"
            fi
            cd ..
        fi
    else
        if ! test -f $BASENAME ; then
            curl -O $URL
            CHANGED="$CHANGED $MODULE"
        fi
    fi
done

cd ..

if [ "x$CHANGED" == "x" -a "x${FORCE-}" == "x" ]; then
    echo "No changes - skipping rebuild"
    exit 0
fi

echo "Changed modules: $CHANGED"

rm -rf app
xdg-app build-init app $APPID $SDK $PLATFORM $SDK_VERSION

mkdir -p build

cd build
for MODULE in $MODULES; do
    echo ========== Building $MODULE ================

    OPT="${OPTS[$MODULE]-}"
    CONFIGURE_ARGS="${CONFIGURE[$MODULE]-}"
    URL=${SOURCES[$MODULE]}
    BASENAME=`basename $URL`
    if [[ "$URL" =~ ^git: ]]; then
        DIR=$BASENAME
        rm -rf $DIR
        BRANCH=${BRANCHES[$MODULE]-master}
        git clone --shared --branch $BRANCH ../dl/$BASENAME.git
    else
        DIR=${BASENAME%.tar*}
        rm -rf $DIR
        tar xf ../dl/$BASENAME

        OPT="$OPT noautogen"
    fi

    xdg-app build ../app ../build_helper.sh "$DIR" "$OPT" "$CONFIGURE_ARGS"
done
cd ..

echo ========== Postprocessing ================

xdg-app build app rm -rf /app/include
xdg-app build app rm -rf /app/lib/pkgconfig
xdg-app build app rm -rf /app/share/pkgconfig
xdg-app build app rm -rf /app/share/aclocal
xdg-app build app rm -rf /app/share/gtk-doc
xdg-app build app rm -rf /app/share/man
xdg-app build app rm -rf /app/share/vala/vapi
xdg-app build app bash -c "find /app/lib -name *.a | xargs rm"
xdg-app build app bash -c "find /app -name *.la | xargs rm"
xdg-app build app bash -c "find /app -name *.pyo | xargs rm"
xdg-app build app bash -c "find /app -name *.pyc | xargs rm"

xdg-app build app bash -c "find /app -type f | xargs file | grep ELF | grep 'not stripped' | cut -d: -f1 | xargs -r -n 1 strip"
if [ "x${DESKTOP_FILE-}" != x ]; then
    xdg-app build app mv /app/share/applications/${DESKTOP_FILE} /app/share/applications/${APPID}.desktop
fi
if [ "x${DESKTOP_NAME_SUFFIX-}" != x ]; then
    xdg-app build app sed -i "s/^Name\(\[.*\]\)\?=.*/&${DESKTOP_NAME_SUFFIX}/" /app/share/applications/${APPID}.desktop
fi
if [ "x${DESKTOP_NAME_PREFIX-}" != x ]; then
    xdg-app build app sed -i "s/^Name\(\[.*\]\)\?=/&${DESKTOP_NAME_PREFIX}/" /app/share/applications/${APPID}.desktop
fi
if [ "x${ICON_FILE-}" != x ]; then
    xdg-app build app bash -c "for i in \`find /app/share/icons -name ${ICON_FILE}\`; do mv \$i \`dirname \$i\`/${APPID}.png; done"
    xdg-app build app sed -i "s/Icon=.*/Icon=${APPID}/" /app/share/applications/${APPID}.desktop
fi
if [ "x${CLEANUP_FILES-}" != x ]; then
    xdg-app build app rm -rf ${CLEANUP_FILES-}
fi
xdg-app build-finish --command=$COMMAND --share=ipc --socket=x11 --socket=pulseaudio --filesystem=host  app
xdg-app build-export repo app
