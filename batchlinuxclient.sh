#!/bin/bash
# ===================================================
# <BATCH>CHAT STARTUP SCREEN
# ===================================================
clear
echo -e "\e[36m"
echo "  < \/ > | _ \  /_\ |_   _|/ __|| _| | / __|| _| | /_\ |_   _|"
echo "  |    | | _ \/ _ \  | |  | (__ | _| || (__ | _| |/ _ \  | |  "
echo "  <_/\_> |___/_/ \_\ |_|   \___||_||_| \___||_||_/_/ \_\ |_|  "
echo ""
echo "                   Starting <batch>chat..."
echo ""
echo "             (c) OpenHcat Projects. Licensed under the MIT license."
echo "==================================================="
echo -e "\e[0m"
sleep 2
clear
# Ensure bash execution
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/client_config.ini"
CURRENT_USER_FILE="$SCRIPT_DIR/current_user.dat"
AUTO_LOGIN_FILE="$SCRIPT_DIR/autologin.dat"

# 1. Shared Folder Path Setup & Initialization
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    clear
    echo "==================================================="
    echo "         WELCOME TO <batch>chat SETUP (Linux)"
    echo "==================================================="
    read -p "Enter Path to Shared Folder: " DB_ROOT
    echo "DB_ROOT=\"$DB_ROOT\"" > "$CONFIG_FILE"
fi

if [ ! -d "$DB_ROOT" ]; then
    echo "[*] Creating shared directory structure..."
    mkdir -p "$DB_ROOT/users" "$DB_ROOT/rooms" "$DB_ROOT/dms" "$DB_ROOT/activity" "$DB_ROOT/bans"
    
    if [ ! -f "$DB_ROOT/server_config.ini" ]; then
        {
            echo "ALLOW_SIGNUPS=1"
            echo "ALLOW_DMS=1"
            echo "ALLOW_ROOM_CREATION=1"
        } > "$DB_ROOT/server_config.ini"
    fi
    if [ ! -f "$DB_ROOT/rooms/General.room" ]; then
        echo "[SYSTEM]: General Chat Room initialized." > "$DB_ROOT/rooms/General.room"
    fi
fi

# 2. Authentication Handling
if [ -f "$AUTO_LOGIN_FILE" ] && [ ! -f "$CURRENT_USER_FILE" ]; then
    cat "$AUTO_LOGIN_FILE" > "$CURRENT_USER_FILE"
fi

if [ ! -f "$CURRENT_USER_FILE" ] || [ ! -s "$CURRENT_USER_FILE" ]; then
    while true; do
        clear
        echo "==================================================="
        echo "               <batch>chat PORTAL (Linux)"
        echo "==================================================="
        echo " [1] Sign In"
        echo " [2] Create New Account (Sign Up)"
        echo " [3] Exit"
        echo "==================================================="
        read -p "Select Option [1-3]: " auth_choice

        if [ "$auth_choice" = "1" ]; then
            read -p "Username: " username
            read -s -p "Password: " password
            echo ""
            
            if [ ! -f "$DB_ROOT/users/$username.usr" ]; then
                echo "[!] User does not exist!"
                sleep 2
                continue
            fi
            
            if grep -q "BANNED=1" "$DB_ROOT/users/$username.usr"; then
                echo "[!] Your account has been BANNED."
                exit 1
            fi
            
            echo "$username" > "$CURRENT_USER_FILE"
            echo "[OK] Login successful!"
            sleep 1
            break
            
        elif [ "$auth_choice" = "2" ]; then
            if [ -f "$DB_ROOT/server_config.ini" ]; then source "$DB_ROOT/server_config.ini"; fi
            if [ "${ALLOW_SIGNUPS:-1}" = "0" ]; then
                echo "[!] Signups are disabled by server admin."
                sleep 2
                continue
            fi
            
            clear
            echo "==================================================="
            echo "                   ACCOUNT SIGN UP"
            echo "==================================================="
            echo ""
            echo " NOTICE: Passwords are not encrypted and stored!"
            echo " Please use a different password than other apps!"
            echo ""
            echo "---------------------------------------------------"
            read -p "Choose Username: " username
            read -s -p "Choose Password: " password
            echo ""
            
            if [ -f "$DB_ROOT/users/$username.usr" ]; then
                echo "[!] Username already taken!"
                sleep 2
                continue
            fi
            
            {
                echo "USERNAME=$username"
                echo "ROLE=user"
                echo "BANNED=0"
                echo "PASSWORD=$password"
            } > "$DB_ROOT/users/$username.usr"
            
            {
                echo "NICKNAME=$username"
                echo "BIO=Hello, I am using <batch>chat from Linux!"
                echo "SOCIALS=None"
                echo "PROFILE_THEME=neon"
            } > "$DB_ROOT/users/$username.page"
            
            touch "$DB_ROOT/users/$username.followers"
            touch "$DB_ROOT/users/$username.friends"
            touch "$DB_ROOT/users/$username.requests"
            
            echo "[OK] Account created successfully!"
            sleep 2
        elif [ "$auth_choice" = "3" ]; then
            exit 0
        fi
    done
fi

if [ ! -f "$CURRENT_USER_FILE" ]; then exit 0; fi
CURR_USER=$(cat "$CURRENT_USER_FILE")

# Ensure user data files exist
touch "$DB_ROOT/users/$CURR_USER.followers" 2>/dev/null
touch "$DB_ROOT/users/$CURR_USER.friends" 2>/dev/null
touch "$DB_ROOT/users/$CURR_USER.requests" 2>/dev/null

# 3. Background Heartbeat Engine
(
    while true; do
        echo "$CURR_USER - $(date)" > "$DB_ROOT/active_users.txt"
        sleep 5
    done
) &
TRANSLATOR_PID=$!
trap "kill $TRANSLATOR_PID 2>/dev/null" EXIT

# 4. First-Time Profile Setup
if [ ! -f "$DB_ROOT/users/$CURR_USER.setup" ]; then
    clear
    echo "==================================================="
    echo "         WELCOME SETUP WIZARD ($CURR_USER)"
    echo "==================================================="
    read -p "Enter Public Nickname: " nick
    read -p "Enter Profile Bio: " bio
    read -p "Enter Social Links: " socials

    {
        echo "NICKNAME=$nick"
        echo "BIO=$bio"
        echo "SOCIALS=$socials"
    } > "$DB_ROOT/users/$CURR_USER.page"
    touch "$DB_ROOT/users/$CURR_USER.setup"
    sleep 1
fi

# 5. Main Dashboard Loop
while true; do
    ACT_COUNT=0
    if [ -f "$DB_ROOT/activity/$CURR_USER.act" ]; then
        ACT_COUNT=$(wc -l < "$DB_ROOT/activity/$CURR_USER.act")
    fi

    clear
    echo "==================================================="
    echo "             <batch>chat HUB [$CURR_USER]"
    echo "==================================================="
    echo " [1] Chat Rooms Directory & Create Room"
    echo " [2] Direct Messages (DMs)"
    echo " [3] Friends List & Manage Requests"
    echo " [4] Activity Feed & Notifications ($ACT_COUNT)"
    echo " [5] Public Profile Page Lookup"
    echo " [6] User Settings & Auto-Login"
    echo " [7] Exit Application"
    echo "==================================================="
    read -p "Select Option [1-7]: " menu_choice

    case $menu_choice in
        1)
            while true; do
                clear
                echo "==================================================="
                echo "                 CHAT ROOMS"
                echo "==================================================="
                echo "Available Rooms:"
                ls "$DB_ROOT/rooms/" 2>/dev/null | sed 's/\.room$//'
                echo "---------------------------------------------------"
                echo " [1] Join Room"
                echo " [2] Create Room"
                echo " [3] Back"
                read -p "Select [1-3]: " rchoice
                
                if [ "$rchoice" = "3" ]; then break; fi
                if [ "$rchoice" = "2" ]; then
                    if [ -f "$DB_ROOT/server_config.ini" ]; then source "$DB_ROOT/server_config.ini"; fi
                    if [ "${ALLOW_ROOM_CREATION:-1}" = "0" ]; then
                        echo "[!] Room creation disabled by admin."
                        sleep 2
                        continue
                    fi
                    read -p "Enter New Room Name: " newroom
                    if [ -n "$newroom" ]; then
                        echo "[SYSTEM]: Room created by $CURR_USER" > "$DB_ROOT/rooms/$newroom.room"
                        echo "[OK] Room created!"
                        sleep 1
                    fi
                elif [ "$rchoice" = "1" ]; then
                    read -p "Enter Room Name to Join: " targetroom
                    if [ -f "$DB_ROOT/rooms/$targetroom.room" ]; then
                        while true; do
                            clear
                            echo "==================================================="
                            echo " ROOM: $targetroom (Type /exit to leave)"
                            echo "==================================================="
                            cat "$DB_ROOT/rooms/$targetroom.room"
                            echo "---------------------------------------------------"
                            read -p "Message: " msg
                            if [ "$msg" = "/exit" ]; then break; fi
                            echo "[$CURR_USER]: $msg" >> "$DB_ROOT/rooms/$targetroom.room"
                        done
                    else
                        echo "[!] Room not found!"
                        sleep 1
                    fi
                fi
            done
            ;;
        2)
            clear
            if [ -f "$DB_ROOT/server_config.ini" ]; then source "$DB_ROOT/server_config.ini"; fi
            if [ "${ALLOW_DMS:-1}" = "0" ]; then
                echo "[!] Direct Messages are disabled by server admin."
                read -p "Press Enter to return..."
                continue
            fi
            read -p "Enter Username for DM: " dmuser
            if [ -z "$dmuser" ]; then continue; fi
            
            dm_file="$DB_ROOT/dms/${CURR_USER}_${dmuser}.dm"
            [ ! -f "$dm_file" ] && dm_file="$DB_ROOT/dms/${dmuser}_${CURR_USER}.dm"
            
            while true; do
                clear
                echo "==================================================="
                echo " DM WITH: $dmuser (Type /exit to leave)"
                echo "==================================================="
                [ -f "$dm_file" ] && cat "$dm_file"
                echo "---------------------------------------------------"
                read -p "Message: " dmsg
                if [ "$dmsg" = "/exit" ]; then break; fi
                echo "[$CURR_USER]: $dmsg" >> "$dm_file"
            done
            ;;
        3)
            while true; do
                clear
                echo "==================================================="
                echo "                 FRIENDS & REQUESTS"
                echo "==================================================="
                echo "Your Friends:"
                if [ -s "$DB_ROOT/users/$CURR_USER.friends" ]; then
                    cat "$DB_ROOT/users/$CURR_USER.friends"
                else
                    echo "  (No friends added yet)"
                fi
                echo "---------------------------------------------------"
                echo "Pending Friend Requests:"
                if [ -s "$DB_ROOT/users/$CURR_USER.requests" ]; then
                    cat "$DB_ROOT/users/$CURR_USER.requests"
                else
                    echo "  (No pending requests)"
                fi
                echo "---------------------------------------------------"
                echo " [1] Accept a Friend Request"
                echo " [2] Interact with a Friend (Message / Profile / Block)"
                echo " [3] Back to Home"
                read -p "Select [1-3]: " fchoice

                if [ "$fchoice" = "3" ]; then break; fi
                if [ "$fchoice" = "1" ]; then
                    read -p "Enter username to accept request from: " reqUser
                    if grep -q "^$reqUser$" "$DB_ROOT/users/$CURR_USER.requests"; then
                        # Remove from requests
                        grep -v "^$reqUser$" "$DB_ROOT/users/$CURR_USER.requests" > "$DB_ROOT/users/$CURR_USER.requests.tmp"
                        mv "$DB_ROOT/users/$CURR_USER.requests.tmp" "$DB_ROOT/users/$CURR_USER.requests"
                        
                        # Add to both friends lists
                        echo "$reqUser" >> "$DB_ROOT/users/$CURR_USER.friends"
                        echo "$CURR_USER" >> "$DB_ROOT/users/$reqUser.friends"
                        
                        echo "[NOTIFICATION] $CURR_USER accepted your friend request!" >> "$DB_ROOT/activity/$reqUser.act"
                        echo "[OK] You are now friends with $reqUser!"
                    else
                        echo "[!] No pending request from that user."
                    fi
                    sleep 2
                elif [ "$fchoice" = "2" ]; then
                    read -p "Enter friend's username: " friendTarget
                    if grep -q "^$friendTarget$" "$DB_ROOT/users/$CURR_USER.friends"; then
                        while true; do
                            clear
                            echo "==================================================="
                            echo " FRIEND: $friendTarget"
                            echo "==================================================="
                            echo " [1] Message (DM)"
                            echo " [2] View Profile Page"
                            echo " [3] Block Friend"
                            echo " [4] Back"
                            read -p "Select [1-4]: " subF
                            if [ "$subF" = "4" ]; then break; fi
                            if [ "$subF" = "1" ]; then
                                dm_file="$DB_ROOT/dms/${CURR_USER}_${friendTarget}.dm"
                                [ ! -f "$dm_file" ] && dm_file="$DB_ROOT/dms/${friendTarget}_${CURR_USER}.dm"
                                while true; do
                                    clear
                                    echo " DM WITH: $friendTarget (Type /exit to leave)"
                                    echo "---------------------------------------------------"
                                    [ -f "$dm_file" ] && cat "$dm_file"
                                    echo "---------------------------------------------------"
                                    read -p "Message: " dmsg
                                    [ "$dmsg" = "/exit" ] && break
                                    echo "[$CURR_USER]: $dmsg" >> "$dm_file"
                                done
                            elif [ "$subF" = "2" ]; then
                                clear
                                echo "Profile: $friendTarget"
                                echo "---------------------------------------------------"
                                cat "$DB_ROOT/users/$friendTarget.page"
                                echo "---------------------------------------------------"
                                read -p "Press Enter to return..."
                            elif [ "$subF" = "3" ]; then
                                grep -v "^$friendTarget$" "$DB_ROOT/users/$CURR_USER.friends" > "$DB_ROOT/users/$CURR_USER.friends.tmp"
                                mv "$DB_ROOT/users/$CURR_USER.friends.tmp" "$DB_ROOT/users/$CURR_USER.friends"
                                echo "[OK] $friendTarget blocked/removed from friends."
                                sleep 2
                                break
                            fi
                        done
                    else
                        echo "[!] That user is not in your friends list."
                        sleep 2
                    fi
                fi
            done
            ;;
        4)
            clear
            echo "==================================================="
            echo "                ACTIVITY FEED"
            echo "==================================================="
            if [ -f "$DB_ROOT/activity/$CURR_USER.act" ]; then
                cat "$DB_ROOT/activity/$CURR_USER.act"
                rm "$DB_ROOT/activity/$CURR_USER.act"
            else
                echo "No new notifications."
            fi
            echo "---------------------------------------------------"
            read -p "Press Enter to return..."
            ;;
        5)
            clear
            echo "==================================================="
            echo "                 PUBLIC PROFILE PAGE"
            echo "==================================================="
            read -p "Enter Username to View: " puser
            if [ -z "$puser" ]; then puser="$CURR_USER"; fi
            
            if [ -f "$DB_ROOT/users/$puser.page" ]; then
                echo "==================================================="
                echo " Profile: $puser"
                echo "==================================================="
                cat "$DB_ROOT/users/$puser.page"
                echo "---------------------------------------------------"
                echo "Followers ($(wc -l < "$DB_ROOT/users/$puser.followers" 2>/dev/null || echo 0)):"
                cat "$DB_ROOT/users/$puser.followers" 2>/dev/null
                echo "---------------------------------------------------"
                echo "Friends:"
                cat "$DB_ROOT/users/$puser.friends" 2>/dev/null
                echo "---------------------------------------------------"
                echo " [1] Follow / Unfollow User"
                echo " [2] Send Friend Request"
                echo " [3] Back"
                read -p "Select [1-3]: " pact
                if [ "$pact" = "1" ]; then
                    if grep -q "^$CURR_USER$" "$DB_ROOT/users/$puser.followers"; then
                        grep -v "^$CURR_USER$" "$DB_ROOT/users/$puser.followers" > "$DB_ROOT/users/$puser.followers.tmp"
                        mv "$DB_ROOT/users/$puser.followers.tmp" "$DB_ROOT/users/$puser.followers"
                        echo "[OK] Unfollowed $puser."
                    else
                        echo "$CURR_USER" >> "$DB_ROOT/users/$puser.followers"
                        echo "[NOTIFICATION] $CURR_USER started following you!" >> "$DB_ROOT/activity/$puser.act"
                        echo "[OK] Now following $puser!"
                    fi
                    sleep 2
                elif [ "$pact" = "2" ]; then
                    if ! grep -q "^$CURR_USER$" "$DB_ROOT/users/$puser.requests" && ! grep -q "^$CURR_USER$" "$DB_ROOT/users/$puser.friends"; then
                        echo "$CURR_USER" >> "$DB_ROOT/users/$puser.requests"
                        echo "[NOTIFICATION] $CURR_USER sent you a friend request!" >> "$DB_ROOT/activity/$puser.act"
                        echo "[OK] Friend request sent to $puser!"
                    else
                        echo "[!] Request already sent or already friends."
                    fi
                    sleep 2
                fi
            else
                echo "[!] Profile not found."
                sleep 2
            fi
            ;;
        6)
            clear
            echo "==================================================="
            echo "                    USER SETTINGS"
            echo "==================================================="
            echo " [1] Edit Profile Page"
            echo " [2] Enable Auto-Sign-In"
            echo " [3] Back"
            read -p "Select [1-3]: " usign
            if [ "$usign" = "1" ]; then
                read -p "New Nickname: " nn
                read -p "New Bio: " bb
                read -p "New Social Links: " ss
                {
                    echo "NICKNAME=$nn"
                    echo "BIO=$bb"
                    echo "SOCIALS=$ss"
                } > "$DB_ROOT/users/$CURR_USER.page"
                echo "[OK] Profile updated!"
                sleep 1
            elif [ "$usign" = "2" ]; then
                echo "$CURR_USER" > "$AUTO_LOGIN_FILE"
                echo "[OK] Auto-sign-in enabled!"
                sleep 1
            fi
            ;;
        7)
            exit 0
            ;;
    esac
done
