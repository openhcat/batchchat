# `<batch>chat`

> A lightweight, cross-platform terminal messaging application and social network powered entirely by **Windows Batch (`.bat`)** and **Linux Shell (`.sh`)** scripts using a shared file-database architecture.

---

## 🌟 Features

* **Zero External Dependencies:** Built using pure native Batch and Bash scripting.
* **Cross-Play Interoperability:** Windows users running `batchclient.bat` can seamlessly chat, send DMs, and follow Linux users running `batchlinuxclient.sh`.
* **Server Dashboard:** Admin controls for banning users, promoting admins, and toggling global settings (disabling signups, DMs, or room creation).
* **Social Network Suite:**
  * **Follow System:** Public one-way subscriptions with live subscriber/follower lists on user profiles.
  * **Friend System:** Mutual connections requiring acceptance, complete with an interactive friend action menu (**Message**, **View Profile**, **Block/Remove**).
* **Direct Messages (DMs) & Public Rooms:** Create custom chat rooms or start private 1-on-1 direct message threads.
* **Activity & Badge Notifications:** Unread notification counter in the main hub for friend requests, room invites, and new followers.
* **Custom Themes & Setup Wizard:** First-time setup wizard allowing theme selection (Red Neon, Matrix Green, Cyber Blue) and public profile customization.

---

## 📂 Project File Structure

```text
<batch>chat/
├── batchclient.bat          # Windows Client Application
├── batchserver.bat          # Windows Server Dashboard
├── batchsignup.bat          # Windows Authentication Gateway
├── batchtranslator.bat       # Windows Sync Engine & Heartbeat
│
├── batchlinuxclient.sh      # Linux Client Suite (Includes Auth & Translator)
├── linuxbatchserver.sh      # Linux Server Dashboard
│
└── batchchat_shared/        # Shared Database Directory (Created automatically)
    ├── server_config.ini    # Server settings & feature toggles
    ├── active_users.txt     # Live user heartbeats
    ├── users/               # Account profiles (.usr), bios (.page), followers & friends
    ├── rooms/               # Public and private chat room logs (.room)
    ├── dms/                 # Private 1-on-1 conversation logs (.dm)
    └── activity/            # Notifications & pending friend requests (.act)
```

---

## 🚀 Getting Started

### 1. Hosting the Server

To host the chat network, run the server script on either Windows or Linux inside your shared folder directory (e.g., a local network share, Samba drive, or cloud-synced folder):

* **Windows Server:**
  Double-click `batchserver.bat` or run it via Command Prompt:
  ```cmd
  batchserver.bat
  ```

* **Linux Server:**
  Open your terminal, grant execution permissions, and run `linuxbatchserver.sh`:
  ```bash
  chmod +x linuxbatchserver.sh
  ./linuxbatchserver.sh
  ```

---

### 2. Connecting as a Client

#### 🪟 On Windows:
1. Run `batchclient.bat`.
2. When prompted on first launch, enter the path to the `batchchat_shared` directory.
3. Sign up or log in, complete your profile setup, and enter the hub!

#### 🐧 On Linux:
1. Open terminal in the `<batch>chat` folder:
   ```bash
   cd "/path/to/<batch>chat"
   ```
2. Grant execution permission to the client script:
   ```bash
   chmod +x batchlinuxclient.sh
   ```
3. Start the client:
   ```bash
   ./batchlinuxclient.sh
   ```
4. Enter the path to your `batchchat_shared` directory (e.g., `/home/username/<batch>chat v1.0/batchchat_shared`).

---

## 🔒 Security Notice

> [!WARNING]
> Passwords in `<batch>chat` are stored in plain text / basic Base64 encoding due to the limitations of batch and shell scripting environments. **Do not use passwords that you use for other personal accounts or services!**

---

## 📄 License

(c) **OpenHcat Projects**. Licensed under the [MIT License](LICENSE).