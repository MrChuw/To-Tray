#!/bin/bash

# Function to show usage
show_usage() {
    echo "Usage: $0 [-i path/to/icon] <program_name> [arguments...]"
    exit 1
}

# Variables
icon_path=""
program_name=""
program_args=""

# Process script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i)
            if [[ -n $2 ]]; then
                icon_path=$2
                shift 2
            else
                echo "Error: -i requires an icon path"
                show_usage
            fi
            ;;
        *)
            if [[ -z $program_name ]]; then
                program_name=$1
            else
                program_args="$program_args $1"
            fi
            shift
            ;;
    esac
done

# Check if the program name was provided
if [[ -z $program_name ]]; then
    echo "Error: Program name not provided"
    show_usage
fi

# Create the directory where the .desktop file will be saved
desktop_dir="$HOME/.local/share/applications"
mkdir -p "$desktop_dir"

mkdir -p ./scripts

# Name of the startup script
script_file="./scripts/${program_name}_tray.sh"

# Create the startup script
cat > "$script_file" <<EOF
#!/bin/bash

# Run the program with the XCB backend
QT_QPA_PLATFORM=xcb $program_name $program_args &

# Function to find the most probable PID
find_program_pid() {
    local name=\$1
    
    # First, try to find the exact program name
    local exact_pid=\$(ps -eo pid,comm | awk -v name="\$name" 'tolower(\$2) == tolower(name) {print \$1}')
    
    if [ -n "\$exact_pid" ]; then
        echo \$exact_pid
        return
    fi
    
    # If not found, look for the closest process
    ps -eo pid,comm | awk -v name="\$name" '
    tolower(\$2) ~ tolower(name) {
        closeness = index(tolower(\$2), tolower(name))
        print closeness, \$1
    }' | sort -n | awk 'NR==1 {print \$2}'
}

# Wait for the window to appear
echo "Waiting for $program_name window to appear..."
while true; do
    sleep 1
    if wmctrl -l | grep -i -q "$program_name"; then
        echo "Window detected!"
        break
    fi
done

# Now that the window appeared, try to find the PID
wlroots_pid=\$(find_program_pid "$program_name")

if [ -n "\$wlroots_pid" ]; then
    echo "PID of $program_name window: \$wlroots_pid"
    
    # Build the kdocker command
    kdocker_cmd="QT_QPA_PLATFORM=xcb kdocker -qx \$wlroots_pid"
    
    # Add the icon if provided
    if [[ -n "$icon_path" ]]; then
        kdocker_cmd="\$kdocker_cmd -i $icon_path"
    fi
    
    # Run kdocker in the background
    eval "\$kdocker_cmd &"
else
    echo "Could not find PID of program $program_name"
fi
EOF

# Make the script executable
chmod +x "$script_file"

# Get real paths
script_file=$(realpath "$script_file")
icon_path=$(realpath "$icon_path")

echo "Startup script created at: $script_file"

# Create the .desktop file
desktop_file="$desktop_dir/${program_name}_tray.desktop"
cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=${program_name} Tray
Exec=$script_file
Icon=${icon_path:-utilities-terminal}
Type=Application
Categories=Utility;Application;
EOF

echo "Desktop entry created at: $desktop_file"
