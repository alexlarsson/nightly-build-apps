#!/bin/sh

FILE=$1

APPID=`basename $FILE .json`

echo ========== Building $APPID ================
flatpak-builder --force-clean --ccache --require-changes --gpg-sign=44F17A57 --gpg-homedir=/home/jgrulich/.gnupg/ --repo=repo --subject="Nightly build of ${APPID}, `date`" ${EXPORT_ARGS-} app $FILE
