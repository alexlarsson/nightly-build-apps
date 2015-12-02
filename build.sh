#!/bin/sh

FILE=$1

APPID=`basename $FILE .json`

echo ========== Building $APPID ================
if xdg-app-builder --require-changes app $FILE; then
    if test -d app; then
        echo ========== Exporting $APPID ================
        xdg-app build-export --subject="Nightly build of ${APPID}, `date`" ${EXPORT_ARGS-} repo app
        if [ "x${GPG_SIGN_KEY}" != "x" ]; then
            echo ostree gpg-sign --repo=repo app/$APPID/x86_64/master ${GPG_SIGN_KEY}
        fi
    fi
fi
