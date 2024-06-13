#!/bin/bash

# Function to clear the terminal
clear_screen() {
    clear
}

# Function for user login
user_login() {
    local username password
    read -rp "Username: " username
    read -rsp "Password: " password
    echo

    if [[ "$username" == "admin" && "$password" == "admin" ]]; then
        echo "Login successful!"
        sleep 1
    else
        echo "Invalid username or password. Exiting..."
        exit 1
    fi
}

# Function to perform vulnerability scanning
scan_vulnerability() {
    local url=$1
    local params
    params=$(extract_params "$url")

    if [[ -z $params ]]; then
        echo -e "\n[+] $url [ini ga vuln]"
        return
    fi

    local vulnerable_params=()
    for param in $params; do
        if test_vulnerability "$url" "$param"; then
            vulnerable_params+=("$param")
        fi
    done

    if [[ ${#vulnerable_params[@]} -gt 0 ]]; then
        echo -e "\n[+] $url [ini vuln]"
        echo -e "\e[32mVulnerable parameters:\e[0m"
        for param in "${vulnerable_params[@]}"; do
            echo "   $param"
        done
        execute_sqlmap "$url"
    else
        echo -e "\n[+] $url [ini ga vuln]"
    fi
}

# Function to extract parameters from URL
extract_params() {
    local url=$1
    local params
    params=$(echo "$url" | grep -oP '(?<=\?)[^#]*' | sed 's/&/\n/g' | cut -d= -f1)
    echo "$params"
}

# Function to test vulnerability
test_vulnerability() {
    local url=$1
    local param=$2
    local original_url modified_url confirmed_modified_url
    original_url=$url
    modified_url=$(modify_url "$url" "$param")
    
    local r1 r2 r3
    r1=$(curl -s "$original_url")
    r2=$(curl -s "$modified_url")

    if [[ "$r1" == "$r2" ]]; then
        return 1
    fi

    confirmed_modified_url=$(modify_url "$modified_url" "$param" "confirm")
    r3=$(curl -s "$confirmed_modified_url")

    if [[ "$r1" == "$r3" ]]; then
        return 0
    fi

    return 1
}

# Function to modify URL for vulnerability testing
modify_url() {
    local url=$1
    local param=$2
    local confirm=$3
    local modified_query modified_url

    if [[ -z $confirm ]]; then
        modified_query=$(echo "$url" | sed "s/$param=[^&]*/$param='/" )
    else
        modified_query=$(echo "$url" | sed "s/$param=[^&]*/$param='--+-/" )
    fi

    modified_url=$modified_query
    echo "$modified_url"
}

# Function to execute SQLMap
execute_sqlmap() {
    local url=$1
    echo -e "\e[33mSilakan jalankan SQLMap untuk mengeksploitasi kerentanan pada: $url\e[0m"
}

# Function to identify WAF
identify_waf() {
    local url=$1
    local headers waf
    headers=$(curl -s -I -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" "$url")
    waf=$(echo "$headers" | grep -i "WAF")

    if [[ -n $waf ]]; then
        echo -e "\n[+] $url menggunakan WAF: $waf"
    else
        echo -e "\n[+] $url tidak menggunakan WAF"
    fi
}

# Main menu
main_menu() {
    while true; do
        clear_screen
        print_header
        echo "[1] Scanning Single URL"
        echo "[2] Mass Scanning"
        echo "[3] Dork Scanning"
        echo "[4] WAF Identification (Single)"
        echo "[5] WAF Identification (Mass)"
        echo "[6] Webshell Finder"
        echo "[0] Keluar"

        read -rp "Pilih fitur yang ingin digunakan: " choice

        case $choice in
            1)
                read -rp "Masukkan URL untuk melakukan scanning: " url
                scan_vulnerability "$url"
                read -rp "Tekan Enter untuk kembali ke menu utama..."
                ;;
            2)
                read -rp "Masukkan path ke file TXT yang berisi list URL: " file_path
                if [[ -f $file_path ]]; then
                    while read -r url; do
                        scan_vulnerability "$url"
                    done < "$file_path"
                else
                    echo "[!] File tidak ditemukan: $file_path"
                fi
                read -rp "Tekan Enter untuk kembali ke menu utama..."
                ;;
            3)
                echo "Dork Scanning belum diimplementasikan."
                read -rp "Tekan Enter untuk kembali ke menu utama..."
                ;;
            4)
                read -rp "Masukkan URL untuk identifikasi WAF: " url
                identify_waf "$url"
                read -rp "Tekan Enter untuk kembali ke menu utama..."
                ;;
            5)
                echo "Mass WAF Identification belum diimplementasikan."
                read -rp "Tekan Enter untuk kembali ke menu utama..."
                ;;
            6)
                echo "Webshell Finder belum diimplementasikan."
                read -rp "Tekan Enter untuk kembali ke menu utama..."
                ;;
            0)
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid. Silakan pilih lagi."
                ;;
        esac
    done
}

# Function to print header ASCII art
print_header() {
    echo -e "\e[33m
                                     ####################
                               ##############++--++##############
                          #########--------------------------#########
                       #######----------------++#+----------------#######
                    ######--------+###-------+-####------####--------+######
                 ######-----------+####-------##-#-------+###-----------+######
               ######--------------#+#----------+----------+------++##-----######
             #####+------####+-------#----------+#-------+---------+###------#####
            ####+------#++###+----------------+#-+-------#---------####+#------#####
          #####--------#+##+-----------##++-#+---+--+##--#+-----+----##+#--------#####
         ####----------##+##----##-----########+++--+####+---##-----##+##----------####
        ####--------------++#+--#+##------#-#############----+#---+#++--------------####
      ####------------------###-+-----------#-################---###-----------------####
     ####--------------------+#++-+#----------#+--#+#########-++##+-------------------+###
     ###-----------------------###+---####---++--------####+--###----------------------+###
    ###-------------------------+#+#+##################++++++-++------------------------+###
   ####--------------------------+######################++-+-+---------------------------####
  ####--------------------------+########################++++-----------------------------###
  ###---------------------------########################++++++-+--------------------------+###
  ###---------------------#####+#######################++##+--+++#####---------------------###
 ###+++++++++++++++++++++++##++##+++######################+----++++##+++++++++++++++++++++++###
 ###+++++++++++++++++++++++++++###--######################+---+#++++++++++++++++++++++++++++###
 ###+++++++++++++++++++++++++++###-###------######++----##++--++++++++++++++++++++++++++++++###
###+++++++++++++++++++++++++++++###+--------+#+#+--------------+++++++++++++++++++++++++++++###
################################+##+#++-----+###-+---------------##############################
################################++#++#+---++####+++------+#+++---##############################
####################################----++#####--++#+-++---+-+--+##############################
##############################################----#+++####---++-###############################
 ###-----------------------------+-###########----+---#####---------------------------------###
 ###-###-------------------------+++#-+######+---------##+----------------------------------###
 ###---#---------------------------+##-#########-------#+------------------------------####-###
  ##-####------------------------#####+###########+-####---+###------------------------###-###
  ###-###-----------------------###################+------++####+----------------------+-+-###
  ####-+----------------------####+-####+##########-----+++--+####--------------------###-####
   ###-+###------------------####----##############+-+-++------####------------------#+#-###
   ####-###-----------------###------##############+##+#-+-------+##+---------------####-###
    ####-###+-------------+#+--------###################-----------+#+-------------####-####
     ####-##----------------------------###############--------------------------------####
      ####-##+#----------------------------######+#+-----------------------------####-####
       ####-+-##---------------------------------------------------------------##-##-####
        ####+##-##------------------------------------------------------------#-##-#####
         #####-####---------------------------------------------------------####+-####
           #####--#-++----------------------------------------------------###+--#####
             #####-#####------------------------------------------------+#-#--#####
              ######-#####------------------------------------------+##---#-#####
                 #####-####-##+-----------------------------------##-###-+#####
                   ######--##-###---------------------------+#-##+###--######
                     ########-###########--+---------##-###+##-#++-########
                        #########----####--##+#+#+##+###-##----########
                            ############-------+--+-----############
                                  ############################

                                       (CODE BY KADEZ-406)
                                  #THANKS FOR SUDATTACK CYBER TEAM
                                  #THANKS FOR CYBER SEDERHANA TEAM
                           ~this tools made by kadez-406 from {S.A.C.T~CST}~
                         [tools ini di buat untuk kalian yang sedang sakit hati]
    \e[0m"
}

# Main program loop with login
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    clear_screen
    print_header
    user_login
    main_menu
fi
