#!/usr/bin/env bash
# Grab the execution directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SCRIPT_DIR

# Include utils script
. "${SCRIPT_DIR}/inc/bb-utils.sh"
# TEST_ROOT directory default
TEST_ROOT="./test-root"
TEST_BASELINES_ROOT="${TEST_ROOT}/baselines"
TEST_INSTALL_ROOT="${TEST_ROOT}/jhove"
CANDIADATE_ROOT="${TEST_ROOT}/candidates"
TARGET_ROOT="${TEST_ROOT}/targets"
BASELINE_VERSION=1.16

# Create the JHOVE test root if it doesn't exist
[[ -d "${TEST_ROOT}" ]] || mkdir -p "${TEST_ROOT}"
# Create the JHOVE test installation root if it doesn't exist
[[ -d "${TEST_INSTALL_ROOT}" ]] || mkdir -p "${TEST_INSTALL_ROOT}"
# Create the JHOVE baseline installation root if it doesn't exist
[[ -d "${TEST_BASELINES_ROOT}" ]] || mkdir -p "${TEST_BASELINES_ROOT}"

# Install v1.16 and create test baseline
if [[ ! -d "${TEST_INSTALL_ROOT}/${BASELINE_VERSION}" ]]; then
	installJhoveFromURL "http://software.openpreservation.org/rel/jhove/jhove-${BASELINE_VERSION}.jar" "${TEST_INSTALL_ROOT}" "${BASELINE_VERSION}"
fi

if [[ ! -d "${TEST_BASELINES_ROOT}/${BASELINE_VERSION}" ]]; then
	mkdir "${TEST_BASELINES_ROOT}/${BASELINE_VERSION}"
  bash "$SCRIPT_DIR/baseline-jhove.sh" -j "${TEST_INSTALL_ROOT}/${BASELINE_VERSION}" -c "${TEST_ROOT}/corpora" -o "${TEST_BASELINES_ROOT}/${BASELINE_VERSION}"
fi

# Create the JHOVE baseline installation root if it doesn't exist
[[ -d "${CANDIADATE_ROOT}" ]] || mkdir -p "${CANDIADATE_ROOT}"

# Set up the temp install location for JHOVE development
tempInstallLoc="/tmp/to-test";
if [[ -d "${tempInstallLoc}" ]]; then
	rm -rf "${tempInstallLoc}"
fi

# Create the test target root if it doesn't exist
[[ -d "${TARGET_ROOT}" ]] || mkdir -p "${TARGET_ROOT}"

# Grab the Major and Minor versions from the full Maven project version string
MVN_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec)
MAJOR_MINOR_VER="${MVN_VERSION%.*}"
MVN_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec)
JHOVE_INSTALLER="./jhove-installer/target/jhove-xplt-installer-${MVN_VERSION}.jar"

if [[ ! -e "${JHOVE_INSTALLER}" ]]
then
	mvn clean package
fi

if [[ ! -d "${TARGET_ROOT}/${MAJOR_MINOR_VER}" ]]
then
	installJhoveFromFile "${JHOVE_INSTALLER}" "${tempInstallLoc}"
	mkdir -p "${TEST_ROOT}/candidates/${MAJOR_MINOR_VER}"
	bash "$SCRIPT_DIR/baseline-jhove.sh" -j "${tempInstallLoc}" -c "${TEST_ROOT}/corpora" -o "${TEST_ROOT}/candidates/${MAJOR_MINOR_VER}"
	bash "${SCRIPT_DIR}/create-${MAJOR_MINOR_VER}-target.sh" -b "${BASELINE_VERSION}" -c "${MAJOR_MINOR_VER}"
fi

bash "${SCRIPT_DIR}/bbt-jhove.sh" -b "${TEST_ROOT}/targets/${MAJOR_MINOR_VER}" -c "${TEST_ROOT}/corpora" -j . -o "${TEST_ROOT}/candidates" -k "dev-${MAJOR_MINOR_VER}" -i
exit $?
