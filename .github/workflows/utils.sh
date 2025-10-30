###############################
# setup environment variables #
###############################
function setup_env_variables() {
  # module info
  mkdir -p build
  echo -e "{\"platform\": \"$PLATFORM\", \"module\": \"$MODULE_NAME\", \"silence\": $SILENCE}" > build/module_info.json

  # module config directory
  module_name_lower=$(echo "${MODULE_NAME}" | tr '[:upper:]' '[:lower:]')
  module_cfg_dir="${GITHUB_WORKSPACE}/module_config/module_${module_name_lower}"
  if [ ! -d "${module_cfg_dir}" ]; then
      platform_name_str=$(echo "${PLATFORM}" | sed 's/PLATFORM_//')
      module_name_lower=$(echo "${platform_name_str}" | tr '[:upper:]' '[:lower:]')
      module_cfg_dir="${GITHUB_WORKSPACE}/module_config/module_${module_name_lower}_default"
  else
      module_cfg_dir="${GITHUB_WORKSPACE}/module_config/module_${module_name_lower}"
  fi
  echo "current configuration dir: ${module_cfg_dir}"
  echo "module_cfg_dir=${module_cfg_dir}" >> $GITHUB_ENV

  # sdkconfig file
  if [ "$SILENCE" = "0" ]; then
      at_sdkconfig_file="${module_cfg_dir}/sdkconfig.defaults"
  elif [ "$SILENCE" = "1" ]; then
      at_sdkconfig_file="${module_cfg_dir}/sdkconfig_silence.defaults"
  else
      at_sdkconfig_file="na"
  fi
  echo "current sdkconfig file: ${at_sdkconfig_file}"
  echo "at_sdkconfig_file=${at_sdkconfig_file}" >> $GITHUB_ENV

  # firmware source
  echo "AT firmware from ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
  echo "ESP_AT_FIRMWARE_FROM=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}" >> "$GITHUB_ENV"
}

#############################
# Update sdkconfig.defaults #
#############################
function enable_at_debug() {
  echo -e "CONFIG_LOG_DEFAULT_LEVEL_DEBUG=y" >> ${at_sdkconfig_file}
  echo -e "CONFIG_MBEDTLS_DEBUG=y" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_DEBUG=y" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_NET_DEBUG=y" >> ${at_sdkconfig_file}
}

function enable_all_wifi_cmds() {
  echo -e "CONFIG_AT_WS_COMMAND_SUPPORT=y" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_FS_COMMAND_SUPPORT=y" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_DRIVER_COMMAND_SUPPORT=y" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_EAP_COMMAND_SUPPORT=y" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_WEB_SERVER_SUPPORT=y" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_WEB_CAPTIVE_PORTAL_ENABLE=y" >> ${at_sdkconfig_file}
}

function disable_all_wifi_cmds() {
  echo -e "CONFIG_AT_WS_COMMAND_SUPPORT=n" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_FS_COMMAND_SUPPORT=n" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_ETHERNET_SUPPORT=n" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_EAP_COMMAND_SUPPORT=n" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_DRIVER_COMMAND_SUPPORT=n" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_WEB_SERVER_SUPPORT=n" >> ${at_sdkconfig_file}
  echo -e "CONFIG_AT_WEB_CAPTIVE_PORTAL_ENABLE=n" >> ${at_sdkconfig_file}
}
