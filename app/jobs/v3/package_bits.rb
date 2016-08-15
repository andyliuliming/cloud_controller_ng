require 'cloud_controller/package_packer/package_packer'

module VCAP::CloudController
  module Jobs
    module V3
      class PackageBits
        def initialize(package_guid, package_zip_path, fingerprints)
          @package_guid     = package_guid
          @package_zip_path = package_zip_path
          @fingerprints     = fingerprints
        end

        def perform
          Steno.logger('cc.background').info("Packing the app bits for package '#{@package_guid}'")
          CloudController::PackagePacker::PackagePacker.new(@package_guid, @package_zip_path, @fingerprints).pack
        end

        def job_name_in_configuration
          :package_bits
        end

        def max_attempts
          1
        end
      end
    end
  end
end
