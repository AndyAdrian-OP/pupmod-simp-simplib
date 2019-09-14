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
#   * blacklist => An Array of operating system strings that should cause
#                  validation to fail. This is mostly useful for profiles.
#   * os
#       * validate => Whether or not to validate the OS settings
#       * options
#           * release_match
#             * none  -> No match on minor release (default)
#             * full  -> Full release must match
#             * major -> Only the major release must match
#
# @return [None]
#
function simplib::module_metadata::os_supported (
  String[1] $module_name,
  Optional[Struct[{
    blacklist => Optional[Struct[{
      operatingsystem        => String[1],
      operatingsystemrelease => Optional[Variant[String[1],Array[String[1]]]]
    }]],
    blacklist_validation => Optional[Struct[{
      validate => Optional[Boolean],
      options  => Struct[{
        release_match => Enum['none','full','major']
      }]
    }]],
    os_validation => Optional[Struct[{
      validate        => Optional[Boolean],
      options         => Struct[{
        release_match => Enum['none','full','major']
      }]
    }]]
  }]] $options = undef
) >> Boolean {

  $_default_blacklist_validation = {
    'validate'        => true,
    'options'         => {
      'release_match' => 'none'
    }
  }

  $_default_os_validation = {
    'validate' => true,
    'options'  => {
      'release_match' => 'none'
    }
  }

  if $options and $options['os_validation'] {
    $_os_validation = deep_merge($_default_os_validation, $options['os_validation'])
  }
  else {
    $_os_validation = $_default_os_validation
  }

  if $options and $options['blacklist_validation'] {
    $_blacklist_validation = deep_merge($_default_blacklist_validation, $options['blacklist_validation'])
  }
  else {
    $_blacklist_validation = $_default_blacklist_validation
  }

  if $_os_validation['enable'] {

    $metadata = load_module_metadata($module_name)

    if empty($metadata) {
      fail("Could not find metadata for module '${module_name}'")
    }

    if $_os_validation['os']['validate'] {
      if !$metadata['operatingsystem_support'] or empty($metadata['operatingsystem_support']) {
        debug("'operatingsystem_support' was not found in module '${module_name}'")

        $result = true
      }

      if $options and $options['blacklist'] and !defined('$result') {
        if ($facts['os']['name'] in $options['blacklist']['operatingsystem_support'].map |Simplib::Puppet::Metadata::OS_support $os_info| { $os_info['operatingsystem'] }) {
          $result = false
        }
        else {
          $options['blacklist']['operatingsystem_support'].each |Simplib::Puppet::Metadata::OS_support $os_info| {
            if $os_info['operatingsystem'] == $facts['os']['name'] {
              case $_os_validation['os']['options']['release_match'] {
                'full': {
                  if ($facts['os']['release']['full'] in $os_info['operatingsystemrelease']) {
                    $result = false
                  }
                }
                'major': {
                  $_os_major_releases = $os_info['operatingsystemrelease'].map |$os_release| {
                    split($os_release, '\.')[0]
                  }

                  if ($facts['os']['release']['major'] in $_os_major_releases) {
                    $result = false
                  }
                }
              }
            }
          }
        }
      }

      unless defined('$result') {
        unless ($facts['os']['name'] in $metadata['operatingsystem_support'].map |Simplib::Puppet::Metadata::OS_support $os_info| { $os_info['operatingsystem'] }) {
          $result = false
        }
        else {
          $metadata['operatingsystem_support'].each |Simplib::Puppet::Metadata::OS_support $os_info| {
            if $os_info['operatingsystem'] == $facts['os']['name'] {
              case $_os_validation['os']['options']['release_match'] {
                'full': {
                  unless ($facts['os']['release']['full'] in $os_info['operatingsystemrelease']) {
                    $result = false
                  }
                }
                'major': {
                  $_os_major_releases = $os_info['operatingsystemrelease'].map |$os_release| {
                    split($os_release, '\.')[0]
                  }

                  unless ($facts['os']['release']['major'] in $_os_major_releases) {
                    $result = false
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  unless defined('$result') {
    $result = true
  }

  $result
}
