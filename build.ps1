$ErrorActionPreference = 'Stop'

# use only one of SonarQube or SonarCloud

# Configuration for SonarQube
#$SONAR_URL = "http://localhost:9000" # URL of the SonarQube server
#$SONAR_TOKEN = "f5f56032a938d29cf76d78de33991eb8c273a0ea" # access token from SonarQube projet creation page -Dsonar.login=XXXX
#$SONAR_PROJECT_KEY = "sonar_scanner_example" # project name from SonarQube projet creation page -Dsonar.projectKey=XXXX
#$SONAR_PROJECT_NAME = "sonar_scanner_example" # project name from SonarName projet creation page -Dsonar.projectName=XXXX

# Configuration for SonarCloud
#$SONAR_TOKEN = # access token from SonarCloud projet creation page -Dsonar.login=XXXX: set in the environment from the CI
$SONAR_PROJECT_KEY = "sonarcloud_example_cpp-cmake-windows-otherci" # project name from SonarCloud projet creation page -Dsonar.projectKey=XXXX
$SONAR_PROJECT_NAME = "sonarcloud_example_cpp-cmake-windows-otherci" # project name from SonarCloud projet creation page -Dsonar.projectName=XXXX
$SONAR_ORGANIZATION = "sonarcloud" # organization name from SonarCloud projet creation page -Dsonar.organization=ZZZZ

# Set default to SONAR_URL in not provided
$SONAR_URL = If ( $SONAR_URL ) { $SONAR_URL } else {"https://sonarcloud.io"}

mkdir $HOME/.sonar
$SONAR_SCANNER_VERSION = "4.2.0.1873"
$SONAR_SCANNER_HOME = "$HOME/.sonar/sonar-scanner-$SONAR_SCANNER_VERSION-windows"

# Download build-wrapper
$path = "$HOME/.sonar/build-wrapper-win-x86.zip"
rm build-wrapper-win-x86 -Recurse -Force -ErrorAction SilentlyContinue
rm $path -Force -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile("$SONAR_URL/static/cpp/build-wrapper-win-x86.zip", $path)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($path, "$HOME/.sonar")
$env:Path += ";$HOME/.sonar/build-wrapper-win-x86"

# Download sonar-scanner
$path = "$HOME/.sonar/sonar-scanner-cli-4.2.0.1873-windows.zip"
rm sonar-scanner -Recurse -Force -ErrorAction SilentlyContinue
rm $path -Force -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile("https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_SCANNER_VERSION-windows.zip", $path)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($path, "$HOME/.sonar")
$env:Path += ";$SONAR_SCANNER_HOME\bin"

# Setup the build system
rm build -Recurse -Force -ErrorAction SilentlyContinue
mkdir build
cd build
cmake ..
cd ..

# Build inside the build-wrapper
build-wrapper-win-x86-64 --out-dir build_wrapper_output_directory cmake --build build/ --config Release

# Run sonar scanner (here, arguments are passed through the command line but most of them can be written in the sonar-project.properties file)
$SONAR_TOKEN_CMD_ARG = If ( $SONAR_TOKEN ) { "-D sonar.login=$SONAR_TOKEN" }
$SONAR_ORGANIZATION_CMD_ARG = If ( $SONAR_ORGANIZATION ) { "-D sonar.organization=$SONAR_ORGANIZATION" }
$SONAR_PROJECT_NAME_CMD_ARG = If ( $SONAR_PROJECT_NAME ) { "-D sonar.projectName=$SONAR_PROJECT_NAME" }
$SONAR_OTHER_ARGS = @("-D sonar.projectVersion=1.0","-D sonar.sources=src","-D sonar.cfamily.build-wrapper-output=build_wrapper_output_directory","-D sonar.sourceEncoding=UTF-8")
sonar-scanner.bat -D sonar.host.url=$SONAR_URL -D sonar.projectKey=$SONAR_PROJECT_KEY $SONAR_OTHER_ARGS $SONAR_PROJECT_NAME_CMD_ARG $SONAR_TOKEN_CMD_ARG $SONAR_ORGANIZATION_CMD_ARG

