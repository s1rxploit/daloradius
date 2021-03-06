#!/bin/sh
#
# daloRADIUS Heartbeat agent
# @version 1.0
# @author Liran Tal <liran.tal@gmail.com>

# ----------------------------------------------------------------------------
# Configuration --------------------------------------------------------------
# ----------------------------------------------------------------------------
# edit the settings below to apply configuration for your own deployment
# do not edit past the Configuration stanza unless you know what you're doing!


# Set to the URL of daloradius's heartbeat script location
DALO_HEARTBEAT_ADDR="http://daloradius.com/heartbeat.php"

# Set NAS MAC to the MAC address of the chilli interface
# MAC address format, according to how the NAS sends this information. For example: 00-aa-bb or 00:aa:bb
NAS_MAC="00-1D-7E-11-22-33"


# Set to a unique, hard-to-figure-out key across all of your NASes.
# This key is saved in daloRADIUS's configuration and so should also
# be configured in daloRADIUS as well.
SECRET_KEY="sillykey"


# Set to 1 if debug mode should be enabled for the agent
# Debug mode prints the collected variable values from the NAS and the returned response form the
# daloradius server
DEBUG_MODE=0


# do not edit past this point
# ----------------------------------------------------------------------------
# Configuration --------------------------------------------------------------
# ----------------------------------------------------------------------------








## get wan information --------------------------------------------------------
wan_iface=`uci get network.wan.ifname`
wan_ip=`uci -P /var/state get network.wan.ipaddr`
if [ -z $wan_ip ]
then
	wan_ip=`ifconfig $wan_iface | awk '/inet addr/{print substr($2,6)}'`
fi
wan_mac=`uci get network.wifi.macaddr | awk '{gsub(":","-");print $0}'`
if [ -z $wan_mac ]
then
	wan_mac=`ifconfig $wan_iface | awk '/HWaddr/{print substr($5,0)}' | awk '{gsub(":","-");print $0}'`
fi

wan_gateway=`uci get network.internet_gateway.gateway`
## get wan information --------------------------------------------------------





## get wifi information -------------------------------------------------------
wifi_iface=`uci -P /var/state get network.wifi.ifname`
wifi_ip=`uci -P /var/state get network.wifi.ipaddr`
if [ -z $wifi_ip ]
then
	wifi_ip=`ifconfig $wifi_iface | awk '/inet addr/{print substr($2,6)}'`
fi
wifi_mac=`uci get network.wifi.macaddr | awk '{gsub(":","-");print $0}'`
if [ -z $wifi_mac ]
then
	wifi_mac=`ifconfig $wifi_iface | awk '/HWaddr/{print substr($5,0)}' | awk '{gsub(":","-");print $0}'`
fi

wifi_ssid=`uci get wireless.@wifi-iface[0].ssid`
wifi_key=`uci get wireless.@wifi-iface[0].key`
wifi_channel=`uci get wireless.wl0.channel`
## get wifi information -------------------------------------------------------









## get lan information -------------------------------------------------------
lan_iface=`uci -P /var/state get network.lan.ifname`
lan_ip=`uci -P /var/state get network.lan.ipaddr`
if [ -z $lan_ip ]
then
	lan_ip=`ifconfig $lan_iface | awk '/inet addr/{print substr($2,6)}'`
fi
lan_mac=`uci get network.lan.macaddr | awk '{gsub(":","-");print $0}'`
if [ -z $lan_mac ]
then
	lan_mac=`ifconfig $lan_iface | awk '/HWaddr/{print substr($5,0)}' | awk '{gsub(":","-");print $0}'`
fi
## get lan information -------------------------------------------------------










#gets wan ip address via wan_ipaddr name or via interface name
ip=$wan_ip

#gets the mac address of the wireless interface on which the hotspot
#runs on
mac=$wifi_mac

uptime=`cat /proc/uptime | awk '{print $1}'`
memfree=`awk '/MemFree/{print $2}' /proc/meminfo`

wan_bdown=`ifconfig $wan_iface | awk '/RX bytes/{print substr($2, index($2, ":")+1)}'`
wan_bup=`ifconfig $wan_iface | awk '/TX bytes/{print substr($6, index($6, ":")+1)}'`

#bdown=`awk '/'"$wan_iface"'/{print substr($1,6)}'  /proc/net/dev`	#in bytes, need to turn to kilobytes
#bup=`awk '/'"$wan_iface"'/{print $9}'  /proc/net/dev`				#in bytes, need to turn to kilobytes

kbdown=$((bdown/1024))
kbup=$((bup/1024))



# device firmware
firmware=`uci get webif.general.firmware_name | awk '{gsub(" ","");print $0}'`
firmware_revision=`uci get webif.general.firmware_version | awk '{gsub(" ","");print $0}'`

# Snippet to get CPU % --------------------------------------------------------------
# adopted from Paul Colby (http://colby.id.au)
PREV_TOTAL=0
PREV_IDLE=0
#repeat period
x=5
#counter
i=1
while [ $i -le $x ]
do
  IDLE=`cat /proc/stat | grep '^cpu ' | awk '{print $5}'`	# get cpu idle time
  TOTAL=`cat /proc/stat | grep '^cpu ' | awk '{print $1+$2+$3+$4+$5+$6+$7+$8+$9+$10+$11}'` #get total cpu time

  # Calculate the CPU usage since we last checked.
  let "DIFF_IDLE=$IDLE-$PREV_IDLE"
  let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
  let "DIFF_USAGE=1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL"
  let "DIFF_USAGE_UNITS=$DIFF_USAGE/10"
  let "DIFF_USAGE_DECIMAL=$DIFF_USAGE%10"
#  echo -en "\rCPU: $DIFF_USAGE_UNITS.$DIFF_USAGE_DECIMAL%    \b\b\b\b"

# No decemical  
  #let "DIFF_IDLE=$IDLE-$PREV_IDLE"
  #let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
  #let "DIFF_USAGE=1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL"
  #let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"
  #echo -en "\rCPU: $DIFF_USAGE%  \b\b"

  # Remember the total and idle CPU times for the next check.
  PREV_TOTAL="$TOTAL"
  PREV_IDLE="$IDLE"

  # Wait before checking again.
  sleep 1
  i=$(( $i + 1 ))
done
cpu=$DIFF_USAGE_UNITS.$DIFF_USAGE_DECIMAL%
# --------------------------------------------------------------------------------------

if [ "$DEBUG_MODE" = "1" ]
then
	echo "Collected the following information..."
	echo "-------------------------------------------------------"
	echo "wan_iface $wan_iface"
	echo "wan_ip $wan_ip"
	echo "wan_mac $wan_mac"
	echo "wan_gateway $wan_gateway"
	echo "wifi_mac $wifi_mac"
	echo "wifi_ip $wifi_ip"
	echo "wifi_iface $wifi_iface"

	echo "lan_mac $lan_mac"
	echo "lan_ip $lan_ip"
	echo "lan_iface $lan_iface"

	echo "ip $ip"
	echo "mac $mac"
	echo "uptime $uptime"
	echo "memfree $memfree"
	echo "wan_bdown $wan_bdown"
	echo "wan_bup $wan_bup"
	echo "wifi_ssid $wifi_ssid"
	echo "wifi_key $wifi_key"
	echo "wifi_channel $wifi_channel"
	echo "firmware $firmware"
	echo "firmware_revision $firmware_revision"
	echo $cpu
	echo "-------------------------------------------------------"
fi


wget -O /tmp/heartbeat.txt "$DALO_HEARTBEAT_ADDR?secret_key=$SECRET_KEY&nas_mac=$NAS_MAC&firmware=$firmware&firmware_revision=$firmware_revision&wan_iface=$wan_iface&wan_ip=$wan_ip&wan_mac=$wan_mac&wifi_mac=$wifi_mac&wan_gateway=$wan_gateway&wifi_iface=$wifi_iface&wifi_ip=$wifi_ip&wifi_mac=$wifi_mac&wifi_ssid=$wifi_ssid&wifi_key=$wifi_key&wifi_channel=$wifi_channel&lan_iface=$lan_iface&lan_ip=$lan_ip&lan_mac=$lan_mac&uptime=$uptime&memfree=$memfree&wan_bup=$wan_bup&wan_bdown=$wan_bdown&cpu=$cpu"


if [ "$DEBUG_MODE" = "1" ]
then
	echo "-------------------------------------------------------"
	echo "daloRADIUS server returned: \n"
	echo "-------------------------------------------------------"
	cat /tmp/heartbeat.txt
	echo "-------------------------------------------------------"
fi
