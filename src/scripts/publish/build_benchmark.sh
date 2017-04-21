set -ex

cd $(dirname $0)/../../test/IntegrationTesting/

BUILD_DIR=../../../artifacts/IntegrationTesting/

mkdir -p $BUILD_DIR

dotnet build ./DotBPE.IntegrationTesting.Client/DotBPE.IntegrationTesting.Client.csproj -c Release
dotnet build ./DotBPE.IntegrationTesting.QpsServer/DotBPE.IntegrationTesting.QpsServer.csproj -c Release