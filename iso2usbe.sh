#!/bin/bash

# Define color codes
CYAN='\033[38;2;0;255;255m'  # Cyan color
NC='\033[0m'                 # No color (reset)

# Function to execute commands with cyan-colored output
execute_command() {
    # Print the command being executed in cyan
    printf "${CYAN}Executing: %s${NC}\n" "$*"
    # Execute the command and pipe its output through a loop to colorize each line
    "$@" | while IFS= read -r line; do
        printf "${CYAN}%s${NC}\n" "$line"
    done
}

# Print ASCII art in red
print_ascii_art() {
    printf "\e[91m"
    printf "░█████╗░██╗░░░░░░█████╗░██╗░░░██╗██████╗░███████╗███╗░░░███╗░█████╗░██████╗░░██████╗\n"
    printf "██╔══██╗██║░░░░░██╔══██╗██║░░░██║██╔══██╗██╔════╝████╗░████║██╔══██╗██╔══██╗██╔════╝\n"
    printf "██║░░╚═╝██║░░░░░███████║██║░░░██║██║░░██║█████╗░░██╔████╔██║██║░░██║██║░░██║╚█████╗░\n"
    printf "██║░░██╗██║░░░░░██╔══██║██║░░░██║██║░░██║██╔══╝░░██║╚██╔╝██║██║░░██║██║░░██║░╚═══██╗\n"
    printf "╚█████╔╝███████╗██║░░██║╚██████╔╝██████╔╝███████╗██║░╚═╝░██║╚█████╔╝██████╔╝██████╔╝\n"
    printf "░╚════╝░╚══════╝╚═╝░░░░░░╚═════╝░╚═════╝░╚══════╝╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚═════╝░\n"
    printf "\e[0m"
}

# Print title in cyan
print_title() {
    printf "${CYAN}Claudemods ISO 2 USB v1.0${NC}\n"
}

# Check if the user is root
if [[ $EUID -ne 0 ]]; then
    printf "\e[91mError: This script must be run as root. Please use sudo.\e[0m\n"
    exit 1
fi

# Print ASCII art and title
print_ascii_art
print_title

# Prompt for the target drive
printf "${CYAN}Enter the target drive (e.g., /dev/sda): ${NC}"
read DRIVE

# Validate the drive input
if [[ ! -b "$DRIVE" ]]; then
    printf "\e[91mError: The specified drive '$DRIVE' is not a valid block device.\e[0m\n"
    exit 1
fi

# List .iso files in /home/eggs
ISO_DIR="/home/eggs"
if [[ ! -d "$ISO_DIR" ]]; then
    printf "\e[91mError: Directory '$ISO_DIR' does not exist.\e[0m\n"
    exit 1
fi

# Find all .iso files in the directory
ISO_FILES=("$ISO_DIR"/*.iso)
if [[ ${#ISO_FILES[@]} -eq 0 ]]; then
    printf "\e[91mError: No .iso files found in '$ISO_DIR'.\e[0m\n"
    exit 1
fi

# Display the list of .iso files
printf "Available .iso files:\n"
for i in "${!ISO_FILES[@]}"; do
    printf "%d: %s\n" "$((i + 1))" "${ISO_FILES[$i]}"
done

# Prompt the user to select an .iso file
printf "${CYAN}Select the .iso file by number: ${NC}"
read SELECTED_INDEX

# Validate the selection
if [[ ! "$SELECTED_INDEX" =~ ^[0-9]+$ ]] || (( SELECTED_INDEX < 1 || SELECTED_INDEX > ${#ISO_FILES[@]} )); then
    printf "\e[91mError: Invalid selection. Please choose a valid number.\e[0m\n"
    exit 1
fi

# Get the selected .iso file
SELECTED_ISO="${ISO_FILES[$((SELECTED_INDEX - 1))]}"

# Confirm the operation
printf "${CYAN}Do you want to write '$SELECTED_ISO' to '$DRIVE'? This will overwrite data on the drive. (y/n): ${NC}"
read CONFIRMATION

if [[ "$CONFIRMATION" != "y" && "$CONFIRMATION" != "Y" ]]; then
    printf "Operation canceled.\n"
    exit 0
fi

# Execute the dd command using the execute_command function
execute_command dd if="$SELECTED_ISO" of="$DRIVE" bs=4M status=progress conv=fsync

# Check if dd succeeded
if [[ $? -eq 0 ]]; then
    printf "${CYAN}Operation completed successfully.${NC}\n"
else
    printf "\e[91mAn error occurred during the dd operation.\e[0m\n"
    exit 1
fi
