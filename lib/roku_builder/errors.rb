# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder
  class InvalidConfig < StandardError
  end

  class ParseError < StandardError
  end

  class InvalidOptions < StandardError
  end

  class ManifestError < StandardError
  end

  class DeviceError < StandardError
  end
end
