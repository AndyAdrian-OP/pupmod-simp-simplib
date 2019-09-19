# Returns the location of whatever called the item that called this function (two levels up)
#
# WARNING: Uses **EXPERIMENTAL** features from Puppet, may break at any time.
Puppet::Functions.create_function(:'simplib::caller', Puppet::Functions::InternalFunction) do

  # @param print
  #   Whether or not to print to the visual output
  #
  # @return [Array]
  #   The caller
  dispatch :caller do
    scope_param()
    optional_param 'Boolean', :print
  end

  def caller(scope, print=false)

    calling_file = 'TOPSCOPE'

    stack_trace = call_function('simplib::debug::stacktrace', false)

    if stack_trace.size > 2
      calling_file = stack_trace[-2]
    end

    return calling_file
  end
end
