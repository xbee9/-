#!/bin/bash

# === Colors ===
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m' 

LOGFILE="adb_tool.log"
DEFAULT_PORT=5555
ADB_TIMEOUT=10

# === Clean exit trap ===
trap 'echo -e "\n${YELLOW}Exiting. Disconnecting devices...${NC}"; adb disconnect; exit 0' SIGINT

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOGFILE"; }

print_banner() {
    clear
    if command -v figlet &>/dev/null; then
        figlet -f slant "ADB Tool"
    else
        echo -e "${CYAN}==== ADB Tool ====${NC}"
    fi
    echo -e "${YELLOW}ADB over Network Automation Tool${NC}"
    echo
}

adb_check() {
    if ! command -v adb &> /dev/null; then
        echo -e "${YELLOW}adb not found. Installing...${NC}"
        sudo apt update && sudo apt install android-tools-adb -y
    fi
}

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        for octet in $(echo $ip | tr '.' ' '); do
            ((octet < 0 || octet > 255)) && return 1
        done
        return 0
    fi
    return 1
}

validate_port() {
    local port=$1
    [[ $port =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)) && return 0 || return 1
}

security_warning() {
    echo -e "${RED}WARNING: Enabling ADB over the network can expose your device!${NC}"
    echo -e "${RED}Only use this on trusted networks.${NC}"
    echo
}

device_info() {
    local ip="$1"
    local port="$2"
    local serial="$ip:$port"
    echo -e "${CYAN}Gathering Device Info from $serial...${NC}"
    local info=$(timeout $ADB_TIMEOUT adb -s "$serial" shell 'echo "Model: $(getprop ro.product.model) | Android: $(getprop ro.build.version.release) | Battery: $(dumpsys battery | grep level | awk \"{print \$2\"%\"}\")"' 2>/dev/null)
    echo "$info"
    log "Device Info [$serial]: $info"
}

# === Push/Pull/Install ===
push_file() {
    read -ep "Local file path: " local_file
    read -ep "Remote destination (e.g., /sdcard/): " remote_path
    if [[ -f "$local_file" ]]; then
        adb push "$local_file" "$remote_path"
        echo -e "${GREEN}File pushed.${NC}"
        log "Pushed $local_file to $remote_path"
    else
        echo -e "${RED}File not found.${NC}"
    fi
}

pull_file() {
    read -ep "Remote file path: " remote_file
    read -ep "Local destination: " local_dest
    adb pull "$remote_file" "$local_dest"
    echo -e "${GREEN}File pulled.${NC}"
    log "Pulled $remote_file to $local_dest"
}

install_apk() {
    read -ep "APK file path: " apk_path
    if [[ -f "$apk_path" ]]; then
        adb install "$apk_path"
        echo -e "${GREEN}APK installed.${NC}"
        log "Installed APK: $apk_path"
    else
        echo -e "${RED}APK file not found.${NC}"
    fi
}

run_custom_command() {
    read -ep "Enter ADB shell command: " cmd
    adb shell "$cmd"
    log "Ran custom command: $cmd"
}

# === Batch Mode ===
batch_mode() {
    local file="$1"
    local port="$DEFAULT_PORT"
    local max_parallel=5

    if [[ ! -f $file ]]; then
        echo -e "${RED}Batch file not found.${NC}"
        return
    fi

    echo -e "${YELLOW}Batch mode started. Port: $port${NC}"

    run_for_ip() {
        local ip="$1"
        if ! validate_ip "$ip"; then
            echo -e "${RED}Invalid IP: $ip${NC}"
            log "Invalid IP: $ip"
            return
        fi
        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            timeout $ADB_TIMEOUT adb connect "$ip:$port" &>/dev/null
            local info=$(timeout $ADB_TIMEOUT adb -s "$ip:$port" shell 'echo -n "Model: "; getprop ro.product.model; echo -n " Android: "; getprop ro.build.version.release; echo -n " Battery: "; dumpsys battery | grep level | awk "{print \$2\"%\"}"' 2>/dev/null)
            echo -e "${CYAN}[$ip]:${NC} $info"
            adb disconnect "$ip:$port" &>/dev/null
            log "Batch processed $ip"
        else
            echo -e "${RED}Device $ip is offline.${NC}"
            log "Offline IP: $ip"
        fi
    }

    local jobs=0
    while IFS= read -r ip; do
        ip=$(echo "$ip" | xargs)
        [[ -z $ip ]] && continue
        run_for_ip "$ip" &
        ((++jobs))
        (( jobs >= max_parallel )) && wait -n && ((jobs--))
    done < "$file"
    wait
    echo -e "${GREEN}Batch processing complete.${NC}"
}

# === Subnet Scanner ===
scan_subnet() {
    read -ep "Enter subnet (e.g., 192.168.1): " subnet
    echo -e "${YELLOW}Scanning $subnet.0/24 for ADB-enabled devices...${NC}"
    for i in {1..254}; do
        ip="$subnet.$i"
        (timeout 1 ping -c 1 $ip &> /dev/null && {
            timeout $ADB_TIMEOUT adb connect "$ip:$DEFAULT_PORT" &>/dev/null && \
            echo -e "${GREEN}Connected to $ip${NC}" && \
            device_info "$ip" "$DEFAULT_PORT" && \
            adb disconnect "$ip:$DEFAULT_PORT"
        }) &
    done
    wait
    echo -e "${GREEN}Subnet scan complete.${NC}"
    log "Subnet scan on $subnet.0/24 complete."
}

# === Main Connection Loop ===
main_connection() {
    read -ep "Enter IP address: " ip_address
    if ! validate_ip "$ip_address"; then echo -e "${RED}Invalid IP.${NC}"; return; fi
    read -ep "Enter port (default: $DEFAULT_PORT): " port
    port=${port:-$DEFAULT_PORT}
    if ! validate_port "$port"; then echo -e "${RED}Invalid port.${NC}"; return; fi

    echo -e "${CYAN}Pinging $ip_address...${NC}"
    if ping -c 1 "$ip_address" &>/dev/null; then
        echo -e "${GREEN}Online. Connecting...${NC}"
        security_warning
        timeout $ADB_TIMEOUT adb connect "$ip_address:$port" &>/dev/null
        adb devices
        device_info "$ip_address" "$port"

        while true; do
            echo -e "${CYAN}Device Actions:${NC}"
            echo "  1) ADB Shell"
            echo "  2) Push File"
            echo "  3) Pull File"
            echo "  4) Install APK"
            echo "  5) Run Shell Command"
            echo "  6) Reboot"
            echo "  7) Disconnect"
            echo "  8) Exit"
            read -ep "Choice: " action
            case $action in
                1) adb shell ;;
                2) push_file ;;
                3) pull_file ;;
                4) install_apk ;;
                5) run_custom_command ;;
                6) adb reboot; log "Rebooted $ip_address" ;;
                7) adb disconnect "$ip_address:$port"; log "Disconnected $ip_address"; break ;;
                8) adb disconnect "$ip_address:$port"; log "Exited tool"; exit 0 ;;
                *) echo -e "${RED}Invalid choice.${NC}" ;;
            esac
        done
    else
        echo -e "${RED}Device is offline.${NC}"
        log "Offline: $ip_address"
    fi
}

# === Entry Point ===
adb_check
print_banner

while true; do
    echo -e "${CYAN}Main Menu:${NC}"
    echo "  1) Connect to device"
    echo "  2) Batch connect (from file)"
    echo "  3) Scan subnet for ADB devices"
    echo "  4) Exit"
    read -ep "Enter choice: " main_choice
    case "$main_choice" in
        1) main_connection ;;
        2) read -ep "Enter batch file path: " file; batch_mode "$file" ;;
        3) scan_subnet ;;
        4) echo -e "${YELLOW}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid choice.${NC}" ;;
    esac
done
