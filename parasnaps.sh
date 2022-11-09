#!/bin/bash

paradir="$HOME/.parasnaps"
paraurl="https://github.com/amforc/s3get/releases/latest/download/"
bucketrooturl="parasnaps.io"

RED='\033[0;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'


echo -e "\n${GREEN}Create working directory: $paradir\n"
mkdir -p $paradir && cd $paradir
echo -e "${GREEN}Download s3get"
curl --silent -o "${paradir}/s3get.sha256" "${paraurl}/s3get.sha256"
curl --silent -o "${paradir}/s3get" "${paraurl}/s3get"
chmod +x "${paradir}/s3get"

echo -e "Verify checksum\n"
if ! sha256sum --quiet -c "${paradir}/s3get.sha256"; then
    echo -e "${RED}Checksum failed" >&2
    exit 1
fi

#-- Select Download location
echo -e "${BLUE}Select the Download source for the snapshot (closest to the host):"

PS3='Please enter your choice: '
options=("(Europe) Ireland" "(Europe) Frankfurt" "(US East) N. Virginia" "(US West) Oregon" "(Asia Pacific) Singapore" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "(Europe) Ireland")
            echo -e "${GREEN}you chose $opt\n"
            bucketurl="euw1.${bucketrooturl}"
            break
            ;;
        "(Europe) Frankfurt")
            echo -e "${GREEN}you chose $opt\n"
            bucketurl="euc1.${bucketrooturl}"
            break
            ;;
        "(US East) N. Virginia")
            echo -e "${GREEN}you chose $opt\n"
            bucketurl="use1.${bucketrooturl}"
            break
            ;;
        "(US West) Oregon")
            echo -e "${GREEN}you chose $opt\n"
            bucketurl="usw2.${bucketrooturl}"
            break
            ;;
        "(Asia Pacific) Singapore")
            echo -e "${GREEN}you chose $opt\n"
            bucketurl="apse1.${bucketrooturl}"
            break
            ;;
        "Quit")
            echo -e "${RED}exiting exiting script\n"
            exit 1
            ;;
        *) echo -e "${RED}invalid option $REPLY${BLUE}";;
    esac
done
#++ Select Download location

#-- Select chain
echo -e "${BLUE}Select the chain:"

PS3='Please enter your choice: '
options=("polkadot" "kusama" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "polkadot")
            echo -e "${GREEN}you chose $opt\n"
            chainselection=$opt
            break
            ;;
        "kusama")
            echo -e "${GREEN}you chose $opt\n"
            chainselection=$opt
            break
            ;;
        "Quit")
            echo -e "${RED}exiting exiting script\n"
            exit 1
            ;;
        *) echo -e "${RED}invalid option $REPLY${BLUE}";;
    esac
done
#++ Select chain

#-- Select database format
echo -e "${BLUE}Select the chain:"

PS3='Please enter your choice: '
options=("rocksdb" "paritydb" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "rocksdb")
            echo -e "${GREEN}you chose $opt\n${BLUE}"
            dbformat=$opt
            break
            ;;
        "paritydb")
            echo -e "${GREEN}you chose $opt\n${BLUE}"
            dbformat=$opt
            break
            ;;
        "Quit")
            echo -e "${RED}exiting exiting script\n"
            exit 1
            ;;
        *) echo -e "${RED}invalid option $REPLY${BLUE}";;
    esac
done
#++ Select database format


#-- Select Directory 
if [ "$chainselection" == "kusama" ]; then
    chain_dir_name="ksmcc3"
else
    chain_dir_name="polkadot"
fi

default_dir="$HOME/.local/share/polkadot/chains/${chain_dir_name}/"
read -p "Enter download directory [$default_dir]:" download_dir
: ${download_dir:=$default_dir}

if [ ! -d "$download_dir" ]; then
    echo -e "${RED}Directory does not exist\n"
    exit 1
fi
echo -e "${GREEN}you chose $download_dir\n${BLUE}"
#++ Select Directory

# --Download file
file_name="${chainselection}_${dbformat}.tar"

echo -e "${BLUE}Downloading:"
${paradir}/s3get "s3://${bucketurl}/${file_name}" | tar -xf - -C $download_dir &
PID=$!
sleep 1
while [ -d /proc/$PID ]
do
    current_size=$(du -sh ${download_dir})
    echo -ne "${GREEN}$current_size\r"
    sleep 1
done
# ++ Downlaod file

echo -e "\n"
echo -e "${GREEN}SCRIPT FINISHED.\n"

# -- User part
echo -e "${BLUE}#Run the polkadot node with:\n${YELLOW}polkadot --chain=${chainselection} --database=${dbformat} --state-pruning=1000"
# ++ User part