#!/bin/bash

# 🎨 رنگ‌ها
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # بدون رنگ

while true; do
    clear
    echo -e "${CYAN}"
    echo "========================================="
    echo "          Backuper Checkhost Menu"
    echo "========================================="
    echo -e "${NC}"

    echo -e "${RED}[1]${NC} Install"
    echo
    echo -e "${RED}[2]${NC} Uninstall"
    echo
    echo -e "${RED}[3]${NC} Run Script"
    echo
    echo -e "${RED}[4]${NC} Exit"
    echo
    echo -e "${RED}[5]${NC} Show Crontab"
    echo
    echo -e "${YELLOW}-----------------------------------------${NC}"
    echo -ne "${RED}Choose an option:${NC} "
    read option

    if [[ $option == 1 ]]; then
        clear
        echo -ne "Enter your Bot Token: "
        read BOT_TOKEN
        clear
        echo -ne "Enter your Chat ID: "
        read CHAT_ID
        clear

        echo -e "Choose backup interval:"
        echo
        echo -e "${RED}[1]${NC} Every minute"
        echo -e "${RED}[2]${NC} Every 10 minutes"
        echo -e "${RED}[3]${NC} Every hour"
        echo
        echo -ne "${RED}Your choice:${NC} "
        read interval
        clear

        case $interval in
            1) CRON_TIME="* * * * *" ;;
            2) CRON_TIME="*/10 * * * *" ;;
            3) CRON_TIME="0 * * * *" ;;
            *) echo "Invalid option"; sleep 2; continue ;;
        esac

        # ساختن فایل mirzadatabackup.sh
        cat > mirzadatabackup.sh <<EOF
#!/bin/bash
ZIP_NAME="mirzadata_\$(date +%Y-%m-%d_%H-%M-%S).zip"

if [ -d "/var/www/html" ]; then
    zip -r "\$ZIP_NAME" /var/www/html > /dev/null

    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document="@\$ZIP_NAME"

    rm -f "\$ZIP_NAME"

    if [ ! -f ".first_run_done" ]; then
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="Backup successful!"
        touch .first_run_done
    fi
else
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="No Folder: /var/www/html"
fi
EOF

        chmod +x mirzadatabackup.sh

        # اضافه کردن کرون‌جاب
        (crontab -l 2>/dev/null; echo "$CRON_TIME $(pwd)/mirzadatabackup.sh") | crontab -

        # اجرای اولیه بلافاصله بعد نصب
        ./mirzadatabackup.sh

        echo -e "\nInstallation completed! First backup sent."
        sleep 3
    fi

    if [[ $option == 2 ]]; then
        clear
        crontab -l | grep -v "mirzadatabackup.sh" | crontab -
        rm -f mirzadatabackup.sh .first_run_done
        echo "Backup uninstalled!"
        sleep 3
    fi

    if [[ $option == 3 ]]; then
        clear
        if [[ -f mirzadatabackup.sh ]]; then
            echo "Running backup script..."
            ./mirzadatabackup.sh
            echo "Backup sent manually."
        else
            echo "mirzadatabackup.sh not found! Please install first."
        fi
        sleep 3
    fi

    if [[ $option == 4 ]]; then
        clear
        echo "Exiting Backuper. Bye!"
        exit 0
    fi

    if [[ $option == 5 ]]; then
        clear
        echo "Current crontab jobs:"
        echo
        crontab -l 2>/dev/null | grep -v '^#'
        if [[ $? -ne 0 || -z "$(crontab -l 2>/dev/null | grep -v '^#')" ]]; then
            echo "No cron jobs found."
        fi
        echo
        echo "Press Enter to return..."
        read
    fi
done
