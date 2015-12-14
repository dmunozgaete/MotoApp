#Android Facebook Setup
http://excellencenodejsblog.com/cordova-ionic-facebook-login-mobile-app/
https://ionicthemes.com/tutorials/about/native-facebook-login-with-ionic-framework
http://www.joshmorony.com/user-authentication-with-ionic-and-parse-part-2-facebook-login/

#Key Hashes
keytool -exportcert -alias motoApp -keystore distribution.keystore | openssl sha1 -binary | openssl base64

#Android Google+ Setup
http://www.androidhive.info/2014/02/android-login-with-google-plus-account-1/
https://ionicthemes.com/tutorials/about/google-plus-login-with-ionic-framework

##SHA1 FootPrint
_DEBUG_
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

_PRD_
keytool -list -v -keystore distribution.keystore -alias motoApp -storepass 123Momia -keypass 123Momia

#Building
In the __build.graddle__ file , for correct build and remove the xMerge Error


// GENERATED FILE! DO NOT EDIT!
apply plugin: 'android'

//this line
configurations {
   all*.exclude group: 'com.android.support', module: 'support-v4'
}

