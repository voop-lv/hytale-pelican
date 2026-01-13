#/bin/ash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HYTALE_SERVER_DOWNLOADER_URL="https://downloader.hytale.com/hytale-downloader.zip"

LOGIC_INSTALL_ENV=false
LOGIC_LAUNCH_SRV=true
LOGIC_AUTO_UPDATE=false

CONFIG_MAX_RAM="2048M"
CONFIG_SERVER_PORT="25565"

JAVA_OPS="-XX:MaxRAMPercentage=95.0 -Dterminal.jline=false -Dterminal.ansi=true --assets Assets.zip"
HYTALE_OPS="---auth-mode authenticated --accept-early-plugins"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --install)
            unset LOGIC_INSTALL_ENV LOGIC_LAUNCH_SRV
            LOGIC_INSTALL_ENV=true
            LOGIC_LAUNCH_SRV=false
            ;;
        --auto_update=*)
            unset LOGIC_AUTO_UPDATE
            # Read true or false or 1 or 0
            value="${key#*=}"
            if [ "$value" = "true" ] || [ "$value" = "1" ]; then
                LOGIC_AUTO_UPDATE=true
            else
                LOGIC_AUTO_UPDATE=false
            fi
            ;;
        --max_ram=*)
            unset CONFIG_MAX_RAM
            CONFIG_MAX_RAM="${key#*=}"
            ;;
        --port=*)
            unset CONFIG_SERVER_PORT
            CONFIG_SERVER_PORT="${key#*=}"
            ;;
        *)
            echo "Error: Unrecognized option '$key'"
            exit 1
            ;;
    esac
    shift
done

function DownloadAndExtractServer() {
    echo "Downloading Hytale Server..."
    wget -q --show-progress -O hytale-downloader.zip "${HYTALE_SERVER_DOWNLOADER_URL}"
    echo "Extracting Hytale Server..."
    unzip -o hytale-downloader.zip -d "${SCRIPT_DIR}"
    rm hytale-downloader.zip hytale-downloader-windows-amd64.exe QUICKSTART.md
    mv hytale-downloader-linux-amd64 hytale-downloader
    echo "Running Hytale Server Downloader..."
    hytale-downloader -download-path hytale_server.zip
    unzip hytale_server.zip
    mv Server/HytaleServer.jar .
    mv Server/HytaleServer.aot .
    echo "Cleaning up..."
    rm -rf Server hytale_server.zip hytale-downloader .hytale-downloader-credentials.json
    echo "Hytale Server installation complete."
}

function readJavaOpts() {
    # This has to return a value
    if [ -f java-opts.txt ]; then
        cat java-opts.txt
    else
        echo ""
    fi
}

function readHytaleOpts() {
    # This has to return a value
    if [ -f hytale-opts.txt ]; then
        cat hytale-opts.txt
    else
        echo ""
    fi
}

if [ "${LOGIC_INSTALL_ENV}" = true ]; then
    DownloadAndExtractServer
    echo "Installation completed. You can now run the server."
    echo "${JAVA_OPS}" >> java-opts.txt
    echo "${HYTALE_OPS}" >> hytale-opts.txt
    exit 0
fi

if [ "${LOGIC_AUTO_UPDATE}" = true ]; then
    echo "Auto-update enabled. Downloading latest server files..."
    rm -rf HytaleServer.jar HytaleServer.aot Assets.zip
    DownloadAndExtractServer
    echo "Update completed."
fi

FINAL_JAVA_OPS="-XX:AOTCache=HytaleServer.aot -Xms128M -Xmx${CONFIG_MAX_RAM} $(readJavaOpts) -jar HytaleServer.jar"
FINAL_HYTALE_OPS="--assets Assets.zip --auth-mode authenticated $(readHytaleOpts) --bind 0.0.0.0:${CONFIG_SERVER_PORT}"

java ${FINAL_JAVA_OPS} ${FINAL_HYTALE_OPS}