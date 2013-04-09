#! /bin/bash

###
#
# Script to add .air file association to LaunchServices
#
###

# assign values to the variables:
localaccount="$(/usr/bin/who | awk '/console/{print $1}')"
keyvariable () {
/usr/libexec/PlistBuddy -c "Print :LSHandlers" "/Users/${localaccount}/Library/Preferences/com.apple.LaunchServices.plist" | grep -c "LSHandlerRoleAll"
}
 
# Add a new server to the list:
/usr/libexec/PlistBuddy -c "Add :LSHandlers:$(keyvariable):LSHandlerContentTag string air" "/Users/${localaccount}/Library/Preferences/com.apple.LaunchServices.plist"
/usr/libexec/PlistBuddy -c "Add :LSHandlers:$(keyvariable):LSHandlerContentTagClass string public.filename-extension" "/Users/${localaccount}/Library/Preferences/com.apple.LaunchServices.plist"
/usr/libexec/PlistBuddy -c "Add :LSHandlers:$(keyvariable):LSHandlerRoleAll string com.adobe.air.applicationinstaller" "/Users/${localaccount}/Library/Preferences/com.apple.LaunchServices.plist"

exit 0