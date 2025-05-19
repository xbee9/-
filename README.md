
# ADB-HUT - ADB Over Network Automation Script

A powerful and interactive Bash script to manage Android devices over a network using ADB (Android Debug Bridge). This tool allows users to connect to Android devices via IP, push/pull files, install APKs, run shell commands, scan subnets for ADB-enabled devices, and more — all from a terminal interface with a colored UI and logging.

## 📌 Features

- Automatic ADB Installation Check
- Interactive IP Connection Interface
- Push/Pull Files and Install APKs
- Run Custom ADB Shell Commands
- Scan Subnets for ADB-Enabled Devices
- Batch Mode for Multiple IPs
- Logs All Device Info and Actions
- Graceful Exit on Interrupt Signal (Ctrl+C)
---

## 🧰 Prerequisites

- Linux (Ubuntu/Debian tested)
- `adb` tool (`android-tools-adb`)
- Optional: `figlet` 

If `adb` is not installed, the script will prompt to install it automatically using `apt`.

---

## 📦 Installation

1. Clone or download the script:
   ```bash
   
   git clone https://github.com/xbee9/adb-hut.git
   cd adb-hut
   ```

2.	Make the script executable:

   ```
   chmod +x adb-hut
```


	
 3.	(Optional) Install figlet for the banner:

```
sudo apt install figlet
```



🚀 Usage

Run the script:

```
./adb-hut

Main Menu Options:

1) Connect to device
2) Batch connect (from file)
3) Scan subnet for ADB devices
4) Exit

```
⸻

🔧 Functional Details
```

1. Connect to Device
	•	Input the device’s IP and port.
	•	Connect and interact via a sub-menu:
	•	Open ADB shell
	•	Push/Pull files
	•	Install APK
	•	Reboot device
	•	Run custom shell commands
	•	Disconnect or Exit

2. Batch Connect (from File)
	•	Reads a file containing one IP per line.
	•	Connects to each device in parallel (up to 5 at once).
	•	Logs info like model, Android version, and battery level.

3. Subnet Scan
	•	Scan any /24 subnet (e.g., 192.168.0).
	•	Pings and attempts ADB connection on IPs from .1 to .254.
	•	Displays and logs online devices with basic info.

4. Exit
	•	Disconnects all devices and gracefully exits.
```
---

📂 Batch File Format
```

Simple text file with one IP address per line:

192.168.1.10
192.168.1.12
192.168.1.15

```
---

⚠️ Security Warning

Using ADB over network is insecure by default. It should only be used in trusted environments.

---

📄 Logs

All actions are logged to:

`adb_tool.log`

Includes timestamps, device connections, errors, and command history.
---

🤝 Contributions

Feel free to fork and modify this tool to suit your needs. Pull requests are welcome!

---

👨‍💻 Authors                          
[@xbee9](https://github.com/xbee9)                                         
[@una55](https://github.com/una55)                                  
[@povzayd](https://github.com/povzayd)                    


---
> Made with ♥️ 
