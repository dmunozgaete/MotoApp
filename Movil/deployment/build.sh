#!/bin/sh
ANT_BUILD_FOLDER="platforms/android/build/outputs/apk"
ANT_BUILD_APK_FILENAME="android"
ZIPALIGN_PATH="/usr/local/Cellar/android-sdk/24.3.3/build-tools/23.0.1/zipalign"
DEPLOYMENT_FOLDER=`dirname $0`						#GET PATH FROM THE SCRIPT

#MANUAL VARIABLES
DISTRIBUTION_FILENAME="app-distribution"
DEBUG_FILENAME="app-qas"

#RELEASE MODE CONFIGURATION
KEYSTORE_FILE="distribution.keystore"
KEYSTORE_PASSWORD="123Momia"
KEYSTORE_ALIAS="motoApp"

#CREATE KEY
#keytool -genkey -v -keystore distribution.keystore -alias motoApp -storepass 123Momia -keyalg RSA -keysize 2048 -validity 10000


clear
echo ''
echo '-------------------------------------------------------------------------'
echo ' Publish - Shell Script'
echo ''
echo ' Company: Valentys Ltda.'
echo ' Contact: dmunoz@valentys.com'
echo ''

#DEBUG ???
if [ "$1" == "--debug" ] || [ "$1" == "debug" ] || [ "$1" == "" ] ; then

	echo ' Build Mode: DEBUG'
	echo '-------------------------------------------------------------------------'
	echo ''
	sleep 1

	#CLEAN THE FILES BEFORE RUNNING COMMAND'S
	rm -rfR $DEPLOYMENT_FOLDER/$DEBUG_FILENAME.apk

	echo 'Building Android...'
	ionic build android								#BUILD IN DEBUG MODE
	echo 'Building Ios (only in OSX)...'
	ionic build ios									#BUILD IN DEBUG MODE
	sleep 5 										#WAIT FOR BUILD

	echo 'Copy debug version from the ant-build (Ionic) ...'
	cp $ANT_BUILD_FOLDER/$ANT_BUILD_APK_FILENAME-debug.apk $DEPLOYMENT_FOLDER/$DEBUG_FILENAME.apk

	clear

	echo '-------------------------------------------------------------------------'
	echo ' Debug Shell Script'
	echo ''
	echo ' Company: Valentys Ltda.'
	echo ' Contact: dmunoz@valentys.com'
	echo ''
	echo ' Debug APK Path: '$DEBUG_FILENAME'.apk'
	echo ' Debug IOS: You can run with ionic run ios --device'
	echo ''
	echo ' Debug Build Success'
	echo '-------------------------------------------------------------------------'
	echo ''

fi



#RELEASE MODE
if [ "$1" == "--release" ] || [ "$1" == "release" ] || [ "$1" == "" ]; then

	echo ' Build Mode: RELEASE'
	echo '-------------------------------------------------------------------------'
	echo ''
	sleep 1

	rm -rfR $DEPLOYMENT_FOLDER/$DISTRIBUTION_FILENAME.apk

	echo 'Building Android (Release)...'
	ionic build --release android					#BUILD IN RELEASE MODE
	echo 'Building Ios (only in OSX)...'
	ionic build ios									#BUILD IN DEBUG MODE
	sleep 5 										#WAIT FOR BUILD

	echo 'Copy unsigned version from the ant-build (Ionic) ...'
	cp $ANT_BUILD_FOLDER/$ANT_BUILD_APK_FILENAME-release-unsigned.apk $DEPLOYMENT_FOLDER/$DISTRIBUTION_FILENAME-unsigned.apk

	echo 'Signing APK With the Keystore File ('$KEYSTORE_FILE')'
	jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore $DEPLOYMENT_FOLDER/$KEYSTORE_FILE -keypass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD $DEPLOYMENT_FOLDER/$DISTRIBUTION_FILENAME-unsigned.apk $KEYSTORE_ALIAS 

	echo 'Optimizing APK with ZipAlign (Required by Play Store)'
	$ZIPALIGN_PATH 4 $DEPLOYMENT_FOLDER/$DISTRIBUTION_FILENAME-unsigned.apk $DEPLOYMENT_FOLDER/$DISTRIBUTION_FILENAME.apk

	echo 'Cleaning Generated Files ...'

	rm -rfR $DEPLOYMENT_FOLDER/$DISTRIBUTION_FILENAME-unsigned.apk

	clear

	echo '-------------------------------------------------------------------------'
	echo ' Distribution Shell Script'
	echo ''
	echo ' Company: Valentys Ltda.'
	echo ' Contact: dmunoz@valentys.com'
	echo ''
	echo ' Distribution APK Path: '$DISTRIBUTION_FILENAME'.apk'
	echo ' Distribution IOS: https://goo.gl/XjqcMe'
	echo ''
	echo ' Build Success, You can Upload to the App Stores'
	echo '-------------------------------------------------------------------------'
	echo ''

fi

