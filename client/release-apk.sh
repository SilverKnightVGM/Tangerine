#!/bin/bash

SECRET="$1"
CONTENT_PATH="$2"
QA_DIRECTORY="/tangerine/client/releases/qa/apks/$SECRET"
PROD_DIRECTORY="/tangerine/client/releases/prod/apks/$SECRET"

if [ "$SECRET" = "" ] || [ "$CONTENT_PATH" = "" ] || [ "QA_DIRECTORY" = "" ] || [ "PROD_DIRECTORY" = "" ]; then
  echo ""
  echo "RELEASE APK"
  echo "A command for releasing an APK using a secret URL."
  echo ""
  echo "./release-apk.sh <secret> <content path>"
  echo ""
  echo "Usage:"
  echo "  ./release-apk.sh a4uw93 ./content/groups/group-a"
  echo ""
  echo "Then visit https://foo.tangerinecentral.org/releases/apk/a4uw93.apk"
fi

# if [ ! -d "$QA_DIRECTORY" ]; then
  # Seed with Cordova project from /cordova_base if $QA_DIRECTORY doesn't exist.
  # When a new group is created, it copies over cordova_base, but this did not happen with existing groups.
  cp -r /cordova_base $QA_DIRECTORY
# fi

rm -rf $QA_DIRECTORY/www
cp -R /tangerine/client/builds/apk/www $QA_DIRECTORY/www

rm -rf $QA_DIRECTORY/www/content
cp -r $CONTENT_PATH $QA_DIRECTORY/www/content
cp -r ./content/assets $QA_DIRECTORY/www/content

cd $QA_DIRECTORY
echo "RELEASE APK: running Cordova build."
cordova -v --no-telemetry
cordova build --no-telemetry android
if [ ! -d "$RELEASES_DIRECTORY" ]; then
# mkdir if $RELEASES_DIRECTORY doesn't exist.
    mkdir $RELEASES_DIRECTORY
else
    rm -r $RELEASES_DIRECTORY/www
fi

echo "Copying www and cordova-hcp.json $RELEASES_DIRECTORY"
cp -R $QA_DIRECTORY/www $RELEASES_DIRECTORY/www
cp -R $QA_DIRECTORY/cordova-hcp.json $RELEASES_DIRECTORY/cordova-hcp.json

cp $QA_DIRECTORY/platforms/android/app/build/outputs/apk/debug/app-debug.apk $RELEASES_DIRECTORY/$SECRET.apk

echo "Released apk for $SECRET at $RELEASES_DIRECTORY"

