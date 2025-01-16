#!/bin/sh

# Function to check and install required tools
install_required_tools() {
	if ! command -v host &> /dev/null; then
		echo "'host' command not found. Attempting to install 'bind-tools' package..."
		if apk update && apk add bind-tools; then
			echo "'bind-tools' successfully installed."
		else
			echo "Failed to install 'bind-tools'. Please install it manually and rerun this script."
			exit 1
		fi
	fi
	if ! command -v whiptail &> /dev/null; then
		echo "'whiptail' command not found. Attempting to install 'newt' package..."
		if apk add newt; then
			echo "'newt' package successfully installed."
		else
			echo "Failed to install 'newt'. Please install it manually and rerun this script."
			exit 1
		fi
	fi
}

# Install necessary tools like 'host' and 'dialog'
install_required_tools

# Function to perform reverse DNS lookup and print results
perform_reverse_dns() {

	# Before performing a reverse DNS lookup, check that the IP address is non-empty
	if [ -n "$IPV4_ADDRESS" ]; then
		IPV4_RDNS=$(perform_reverse_dns $IPV4_ADDRESS 2>/dev/null)
	else
		echo "IPv4 address not detected or network is unreachable."
	fi

	if [ -n "$IPV6_ADDRESS" ]; then
		IPV6_RDNS=$(perform_reverse_dns $IPV6_ADDRESS 2>/dev/null)
	else
		echo "IPv6 address not detected or network is unreachable."
	fi
	local ip_address=$1
	local reverse_dns=$(host $ip_address | awk '/pointer/ {print $5}' | sed 's/\.$//')
	echo "$reverse_dns"
}

# Sensible defaults
HOSTNAME=$(hostname)
DOMAIN=$(hostname -d)
if [ -z "$DOMAIN" ]; then
	DOMAIN="example.com" # Fallback domain if the hostname doesn't provide one
fi
IPV4_ADDRESS=$(ip -4 route get 1.1.1.1 | awk '{ print $7 }' 2>/dev/null)
IPV6_ADDRESS=$(ip -6 route get 2606:4700:4700::1111 | awk '{ print $7 }' 2>/dev/null)
if ! IPV4_ADDRESS=$(...); then
    echo "Failed to obtain IPv4 address, please check your network."
    exit 1
fi
if ! IPV6_ADDRESS=$(...); then
    echo "Failed to obtain IPv6 address, please check your network."
fi
IPV4_RDNS=$(perform_reverse_dns $IPV4_ADDRESS)
IPV6_RDNS=$(perform_reverse_dns $IPV6_ADDRESS)
ADMIN_EMAIL="admin@$DOMAIN"

# Dialog utility functions
edit_value() {
	local value=$1
	local title=$2
	local result=$(dialog --title "Edit $title" --inputbox "Current $title: $value" 8 50 3>&1 1>&2 2>&3 3>&-)
	echo $result
}

# Display and edit configuration with dialog
configure_postfix() {
	while true; do
		CHOICE=$(whiptail --title "Postfix Configuration" --menu "Choose an option to edit:" 20 78 10 \
			"1" "Hostname: $HOSTNAME" \
			"2" "Domain: $DOMAIN" \
			"3" "IPv4 Address: $IPV4_ADDRESS" \
			"4" "IPv4 Reverse DNS: $IPV4_RDNS" \
			"5" "IPv6 Address: $IPV6_ADDRESS" \
			"6" "IPv6 Reverse DNS: $IPV6_RDNS" \
			"7" "Admin Email: $ADMIN_EMAIL" \
			3>&1 1>&2 2>&3)

		EXITSTATUS=$?
		if [ $EXITSTATUS != 0 ]; then
			# Exit status of 1 means user pressed ESC or selected No/Cancel, etc.
			echo "Exiting configuration menu."
			return
		fi

	# Depending on the choice, open an input box to edit the value
	case $CHOICE in
		1) HOSTNAME=$(whiptail --inputbox "Edit Hostname" 8 78 $HOSTNAME 3>&1 1>&2 2>&3);;
		2) DOMAIN=$(whiptail --inputbox "Edit Domain" 8 78 $DOMAIN 3>&1 1>&2 2>&3);;
		3) IPV4_ADDRESS=$(whiptail --inputbox "Edit IPv4 Address" 8 78 $IPV4_ADDRESS 3>&1 1>&2 2>&3);;
		4) IPV4_RDNS=$(whiptail --inputbox "Edit IPv4 Reverse DNS" 8 78 $IPV4_RDNS 3>&1 1>&2 2>&3);;
		5) IPV6_ADDRESS=$(whiptail --inputbox "Edit IPv6 Address" 8 78 $IPV6_ADDRESS 3>&1 1>&2 2>&3);;
		6) IPV6_RDNS=$(whiptail --inputbox "Edit IPv6 Reverse DNS" 8 78 $IPV6_RDNS 3>&1 1>&2 2>&3);;
		7) ADMIN_EMAIL=$(whiptail --inputbox "Edit Admin Email" 8 78 $ADMIN_EMAIL 3>&1 1>&2 2>&3);;
	esac
done
}

# Run configuration menu
configure_postfix

echo "Continuing with setup..."
# Place the rest of your setup script here. This is where you would apply the configurations.
