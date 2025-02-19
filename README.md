# To-Tray  

To-Tray is a script that generates a `.desktop` entry and a script to start a program minimized to the system tray. It uses **kdocker** to minimize the window and **wmctrl** to find the window. It requires **Xwayland** on Wayland environments.  

⚠ **Note:** This script has **not been tested on X11**.  

## Usage  

```bash
./generate_tray.sh [-i path/to/icon] <program_name> [arguments...]
```

### Example  

```bash
./generate_tray.sh -i path/to/icon carla ~/carla/Desktop.carxp
```

## Dependencies  

- `wmctrl` – for window management  
- `kdocker` – to send the window to the system tray  
- `xwayland` – required if running on Wayland  
