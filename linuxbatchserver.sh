#!/bin/bash

# Ensure running in bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Define Database Root Directory
DB_ROOT="$(pwd)/batchchat_shared"

init_storage() {
    mkdir -p "$DB_ROOT/users"
    mkdir -p "$DB_ROOT/rooms"
    mkdir -p "$DB_ROOT/dms"
    mkdir -p "$DB_ROOT/activity"
    mkdir -p "$DB_ROOT/bans"

    # Initialize Default Configuration if missing
    if [ ! -f "$DB_ROOT/server_config.ini" ]; then
        {
            echo "ALLOW_SIGNUPS=1"
            echo "ALLOW_DMS=1"
            echo "ALLOW_ROOM_CREATION=1"
        } > "$DB_ROOT/server_config.ini"
    fi

    # Initialize General Room if missing
    if [ ! -f "$DB_ROOT/rooms/General.room" ]; then
        echo "[SYSTEM]: General Chat Room initialized." > "$DB_ROOT/rooms/General.room"
    fi
}

server_menu() {
    while true; do
        clear
        echo "==================================================="
        echo "             <batch>chat SERVER DASHBOARD (Linux)"
        echo "==================================================="
        echo " Shared Directory : $DB_ROOT"
        echo " Status           : ONLINE (Cross-Play File Engine)"
        echo "---------------------------------------------------"
        echo " [1] Server Settings & Toggles"
        echo " [2] User Management (Ban / Promote Admin)"
        echo " [3] View Active Users & Heartbeats"
        echo " [4] Purge / Reset Server Database"
        echo " [5] Exit Dashboard"
        echo "==================================================="
        read -p "Select Option [1-5]: " choice

        case $choice in
            1) settings_menu ;;
            2) user_mgmt ;;
            3) view_active ;;
            4) reset_db ;;
            5) exit 0 ;;
            *) echo "Invalid option." ; sleep 1 ;;
        esac
    done
}

settings_menu() {
    while true; do
        clear
        echo "==================================================="
        echo "                 SERVER SETTINGS"
        echo "==================================================="
        if [ -f "$DB_ROOT/server_config.ini" ]; then
            source "$DB_ROOT/server_config.ini"
        fi
        echo " [1] Allow New Signups       : ${ALLOW_SIGNUPS:-1} (1=Yes, 0=No)"
        echo " [2] Allow Direct Messages   : ${ALLOW_DMS:-1} (1=Yes, 0=No)"
        echo " [3] Allow Room Creation     : ${ALLOW_ROOM_CREATION:-1} (1=Yes, 0=No)"
        echo " [B] Back to Main Menu"
        echo "---------------------------------------------------"
        read -p "Toggle Setting [1-3 or B]: " tchoice

        case $tchoice in
            1) [ "${ALLOW_SIGNUPS:-1}" = "1" ] && ALLOW_SIGNUPS=0 || ALLOW_SIGNUPS=1 ;;
            2) [ "${ALLOW_DMS:-1}" = "1" ] && ALLOW_DMS=0 || ALLOW_DMS=1 ;;
            3) [ "${ALLOW_ROOM_CREATION:-1}" = "1" ] && ALLOW_ROOM_CREATION=0 || ALLOW_ROOM_CREATION=1 ;;
            [bB]) return ;;
            *) echo "Invalid choice." ; sleep 1 ; continue ;;
        esac

        {
            echo "ALLOW_SIGNUPS=$ALLOW_SIGNUPS"
            echo "ALLOW_DMS=$ALLOW_DMS"
            echo "ALLOW_ROOM_CREATION=$ALLOW_ROOM_CREATION"
        } > "$DB_ROOT/server_config.ini"
    done
}

user_mgmt() {
    while true; do
        clear
        echo "==================================================="
        echo "                  USER MANAGEMENT"
        echo "==================================================="
        echo "Registered Users:"
        if [ -d "$DB_ROOT/users" ]; then
            for f in "$DB_ROOT/users/"*.usr; do
                [ -e "$f" ] && echo "   - $(basename "$f" .usr)"
            done
        fi
        echo "---------------------------------------------------"
        read -p "Enter Username to Modify (or B to Back): " target

        if [ "$target" = "B" ] || [ "$target" = "b" ]; then return; fi

        if [ ! -f "$DB_ROOT/users/$target.usr" ]; then
            echo "[!] User not found!"
            sleep 2
            continue
        fi

        clear
        echo "==================================================="
        echo " Modifying User: $target"
        echo "==================================================="
        echo " [1] Ban / Unban User"
        echo " [2] Promote to Admin / Demote to User"
        echo " [B] Back"
        read -p "Select Action [1-2 or B]: " uact

        if [ "$uact" = "1" ]; then
            if grep -q "BANNED=1" "$DB_ROOT/users/$target.usr"; then
                grep -v "BANNED=" "$DB_ROOT/users/$target.usr" > "$DB_ROOT/users/$target.tmp" 2>/dev/null
                echo "BANNED=0" >> "$DB_ROOT/users/$target.tmp"
                mv "$DB_ROOT/users/$target.tmp" "$DB_ROOT/users/$target.usr"
                echo "[OK] User $target unbanned."
            else
                grep -v "BANNED=" "$DB_ROOT/users/$target.usr" > "$DB_ROOT/users/$target.tmp" 2>/dev/null
                echo "BANNED=1" >> "$DB_ROOT/users/$target.usr"
                echo "[OK] User $target banned."
            fi
            sleep 2
        elif [ "$uact" = "2" ]; then
            if grep -q "ROLE=admin" "$DB_ROOT/users/$target.usr"; then
                grep -v "ROLE=" "$DB_ROOT/users/$target.usr" > "$DB_ROOT/users/$target.tmp" 2>/dev/null
                echo "ROLE=user" >> "$DB_ROOT/users/$target.tmp"
                mv "$DB_ROOT/users/$target.tmp" "$DB_ROOT/users/$target.usr"
                echo "[OK] User $target demoted to standard user."
            else
                grep -v "ROLE=" "$DB_ROOT/users/$target.usr" > "$DB_ROOT/users/$target.tmp" 2>/dev/null
                echo "ROLE=admin" >> "$DB_ROOT/users/$target.usr"
                echo "[OK] User $target promoted to ADMIN."
            fi
            sleep 2
        fi
    done
}

view_active() {
    clear
    echo "==================================================="
    echo "              ACTIVE USERS HEARTBEAT"
    echo "==================================================="
    if [ -f "$DB_ROOT/active_users.txt" ]; then
        cat "$DB_ROOT/active_users.txt"
    else
        echo "No active user heartbeats recorded yet."
    fi
    echo "---------------------------------------------------"
    read -p "Press Enter to return..."
}

reset_db() {
    clear
    echo "==================================================="
    echo "[!] WARNING: THIS WILL WIPE ALL USERS, ROOMS, AND CHATS!"
    echo "==================================================="
    read -p "Type YES to confirm database reset: " confirm
    if [ "$confirm" = "YES" ]; then
        rm -rf "$DB_ROOT"
        echo "Database cleared successfully."
        sleep 2
        init_storage
    fi
}

init_storage
server_menu
