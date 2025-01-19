#!/bin/bash
# File Permissions
cd /opt/iNodeClient/
chmod 777 ./clientfiles
chmod 777 ./clientfiles/8021
chmod 777 ./clientfiles/5020
chmod 777 ./clientfiles/7000
chmod 777 ./clientfiles/2041
chmod 777 ./clientfiles/9019
chmod -R 777 ./conf
chmod -R 777 ./log

# Firewall MASQUERADE
iptables -t nat -A POSTROUTING -o any -j MASQUERADE
sudo iptables -A FORWARD -j ACCEPT

# Check if the file exists
if [ -f "/opt/iNodeClient/install_64.sh" ]; then
    echo Start install iNodeClient
    bash "/opt/iNodeClient/install_64.sh"
fi

# Start iNodeAuthService
echo Start iNodeAuthService ...
/etc/init.d/iNodeAuthService start 

# Start squid
/etc/init.d/squid start

# Signal handling function
cleanup() {
    echo "Exiting iNode Client ..."
    terminate_process /opt/iNodeClient/.iNode/iNodeClient
    echo "Exiting iNodeMon ..."
    terminate_process /opt/iNodeClient/iNodeMon
    echo "Exiting iNodeAuthService ..."
    /etc/init.d/iNodeAuthService stop
    echo "Exiting squid ..."
    /etc/init.d/squid stop
    exit 0
}


# Function: Find process and send SIGTERM signal
terminate_process() {
    local program_path="$1"  
 
    local pids=$(pgrep -f "$program_path")

    if [ -z "$pids" ]; then
        echo "No process found for $program_path."
    else
        echo "Sending SIGTERM to the following PIDs: $pids"
        kill -15 $pids

        echo "Waiting for $program_path to exit..."
        while pgrep -f "$program_path" > /dev/null; do
            sleep 1
        done

        echo "$program_path has exited."
    fi
} 
trap cleanup SIGINT SIGTERM

echo Start iNodeClient ... 
PROGRAM_PATH="/opt/iNodeClient/.iNode/iNodeClient" 
LOG_FILE="/opt/iNodeClient/log/inodeclient_monitor.log"
is_running() {
    pgrep -f "$PROGRAM_PATH" > /dev/null 2>&1
    return $?
}

echo Starting screen :100 ...
Xvfb :100 -screen 0 800x600x24 & 
echo Starting xpra and iNodeClient ...
xpra start :100 --bind-tcp=0.0.0.0:14500 \
--html=on \
--speaker=off \
--webcam=off \
--resize-display=off \
--keyboard-sync=no \
--log-dir=/opt/iNodeClient/log \
--log-file=xpra.log \
--start='/opt/iNodeClient/iNodeClient.sh' \
--use-display 

while true; do
    if ! is_running; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Program not running. Restarting..." | tee -a "$LOG_FILE"
        DISPLAY=:100 /opt/iNodeClient/iNodeClient.sh
    fi
    sleep 2 
done

#tail -f /dev/null