#! /bin/bash

###
#
# Script to clear the Favorite Servers list and add a single new server to the list
#
###

localaccount="$3"
servername="$4"
serveradd="afp://$servername"

/usr/libexec/PlistBuddy -c "Delete :Hosts:CustomListItems" /Users/"$localaccount"/Library/Preferences/com.apple.recentitems.plist

/usr/libexec/PlistBuddy -c "Add :Hosts:CustomListItems:0:Name string $servername" /Users/"$localaccount"/Library/Preferences/com.apple.recentitems.plist

/usr/libexec/PlistBuddy -c "Add :Hosts:CustomListItems:0:URL string $serveradd" /Users/"$localaccount"/Library/Preferences/com.apple.recentitems.plist

exit 0