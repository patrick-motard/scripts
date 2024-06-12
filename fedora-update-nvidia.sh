#!/usr/bin/env bash

# Function to check the exit status of each command and exit if the command fails
check_exit_status() {
	if [ $? -ne 0 ]; then
		echo "Error: Step '$1' failed."
		exit 1
	fi
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
	echo "Please run as root."
	exit 1
fi

# Step 1: List current Yum repositories
echo "Listing current Yum repositories:"
ls /etc/yum.repos.d
check_exit_status "Listing current Yum repositories"

# Step 2: Remove NVIDIA repositories using pattern matching
echo "Removing NVIDIA repositories..."
rm -f /etc/yum.repos.d/*cuda*.repo /etc/yum.repos.d/*nvidia*.repo
check_exit_status "Removing NVIDIA repositories"

# Step 3: Update the system
echo "Updating the system..."
dnf update -y
check_exit_status "Updating the system"

# Step 4: List installed NVIDIA packages
echo "Listing installed NVIDIA packages:"
dnf list installed \*nvidia\*
check_exit_status "Listing installed NVIDIA packages"

# Step 5: Remove NVIDIA packages
echo "Removing NVIDIA packages..."
dnf remove -y '*nvidia*'
check_exit_status "Removing NVIDIA packages"

# Step 6: Verify removal of NVIDIA packages
echo "Verifying removal of NVIDIA packages:"
rpm -qa | grep -i nvidia
check_exit_status "Verifying removal of NVIDIA packages"

# Step 7: Verify kernel packages
echo "Listing installed kernel packages:"
rpm -qa | grep -i kernel
check_exit_status "Listing installed kernel packages"

# Step 8: Update the system again
echo "Updating the system again..."
dnf update -y
check_exit_status "Updating the system again"

# Step 9: Install NVIDIA kernel module
echo "Installing NVIDIA kernel module (akmod-nvidia)..."
dnf install -y akmod-nvidia
check_exit_status "Installing NVIDIA kernel module (akmod-nvidia)"

# Step 10: Install NVIDIA CUDA drivers
echo "Installing NVIDIA CUDA drivers (xorg-x11-drv-nvidia-cuda)..."
dnf install -y xorg-x11-drv-nvidia-cuda
check_exit_status "Installing NVIDIA CUDA drivers (xorg-x11-drv-nvidia-cuda)"

# Step 11: Monitor NVIDIA driver version
echo "Monitoring NVIDIA driver version..."
watch -n1 modinfo -F version nvidia
check_exit_status "Monitoring NVIDIA driver version"
