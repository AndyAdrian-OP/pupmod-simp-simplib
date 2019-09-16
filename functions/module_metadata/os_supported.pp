# Returns whether or not the passed module has a supported OS per the module's
# metadata.json.
#
# If a blacklist is passed, then it will return `false` if the OS is in the
# blacklist and `true` otherwise.
#
# If the blacklist is not matched, the standard OS validation will be used.
#
# @param module_name
#   The name of the module that should be checked
#
# @param options
#   Behavior modifiers for the function
#
#   **Options**
#
#   * blacklist => An Array of Strings containing OS names or an Array of
#                  Hashes containing OS names as keys and an Array of versions to blacklist as
#                  values.
#
#   * blackalist_validation
#       * enable => Whether or not to validate the OS settings
#       * options
#           * release_match
#             * none  -> No match on release (default)
#             * full  -> Full release must match
#             * major -> Only the major release must match
#
#   * os_validation
#       * enable => Whether or not to validate the OS settings
#       * options
#           * release_match
#             * none  -> No match on release (default)
#             * full  -> Full release must match
#             * major -> Only the major release must match
#
# @return [Boolean]
#   true  => The OS + release is supported
#   false => The OS + release is not supported
#
function simplib::module_metadata::os_supported (
  String[1] $module_name,
  Optional[Struct[{
    enable => Optional[Boolean],
    blacklist => Optional[Array[Variant[String[1], Hash[String[1], Variant[String[1], Array[String[1]]]]]]],
    blacklist_validation => Optional[Struct[{
      enable => Optional[Boolean],
      options  => Struct[{
        release_match => Enum['none','full','major']
      }]
    }]],
    os_validation => Optional[Struct[{
      enable        => Optional[Boolean],
      options         => Struct[{
        release_match => Enum['none','full','major']
      }]
    }]]
  }]] $options = undef
) >> Boolean {

  $_default_options = {
    'enable'               => true,
    'blacklist_validation' => {
      'enable'             => true,
      'options'              => {
        'release_match'      => 'none'
      }
    },
    'os_validation' => {
      'enable'             => true,
      'options'              => {
        'release_match'      => 'none'
      }
    }
  }

  if $options {
    $_options = deep_merge($_default_options, $options)
  }
  else {
    $_options = $_default_options
  }

  if $_options['enable'] {

    $metadata = load_module_metadata($module_name)

    if empty($metadata) {
      fail("Could not find metadata for module '${module_name}'")
    }

    if $_options['os_validation']['enable'] {
      if !$metadata['operatingsystem_support'] or empty($metadata['operatingsystem_support']) {
        debug("'operatingsystem_support' was not found in module '${module_name}'")

        $result = true
      }

      if $_options['blacklist_validation']['enable'] and $_options['blacklist'] and !defined('$result') {
        if ($facts['os']['name'] in Array($_options['blacklist']).map |$os_info| {if $os_info =~ String { $os_info } else { $os_info[0] } }) {
          $result = false
        }
        else {
          $result = $_options['blacklist'].reduce(true) |$memo, $os_info| {
            $_os_name = keys($os_info)[0]

            # This could be a number so we have to force the Array cast
            $_os_versions = Array($os_info[$_os_name], true)

            if $_os_name == $facts['os']['name'] {
              $memo and case $_options['blacklist_validation']['options']['release_match'] {
                'full': {
                  !$facts['os']['release']['full'] in $_os_versions
                }
                'major': {
                  $_os_major_releases = $_os_versions.map |$os_release| { split($os_release, '\.')[0] }

                  !$facts['os']['release']['major'] in $_os_major_releases
                }
                default: { true }
              }
            }
            else { true and $memo }
          }
        }
      }

      unless defined('$result') {
        if $_options['os_validation']['enable'] {
          unless ($facts['os']['name'] in $metadata['operatingsystem_support'].map |Simplib::Puppet::Metadata::OS_support $os_info| { $os_info['operatingsystem'] }) {
            $result = false
          }
          else {
            $result = $metadata['operatingsystem_support'].reduce(true) |$memo, Simplib::Puppet::Metadata::OS_support $os_info| {
              if $os_info['operatingsystem'] == $facts['os']['name'] {
                $memo and case $_options['os_validation']['options']['release_match'] {
                  'full': {
                    $facts['os']['release']['full'] in $os_info['operatingsystemrelease']
                  }
                  'major': {
                    $_os_major_releases = $os_info['operatingsystemrelease'].map |$os_release| {
                      split($os_release, '\.')[0]
                    }

                    $facts['os']['release']['major'] in $_os_major_releases
                  }
                  default: { true }
                }
              }
              else { true and $memo }
            }
          }
        }
      }
    }
  }

  unless defined('$result') { $result = true }

  $result
}
