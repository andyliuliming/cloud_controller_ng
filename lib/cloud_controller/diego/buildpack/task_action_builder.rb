require 'cloud_controller/diego/task_protocol'

module VCAP::CloudController
  module Diego
    module Buildpack
      class TaskActionBuilder
        include ::Diego::ActionBuilder

        attr_reader :config, :task

        def initialize(config, task)
          @config = config
          @task = task
        end

        def action
          download_action = ::Diego::Bbs::Models::DownloadAction.new(
            artifact: 'app droplet',
            from:     task.droplet_uri,
            to:       '/tmp/app',
            user:     'vcap'
          )

          run_action = ::Diego::Bbs::Models::RunAction.new(
            path: 'tmp/lifecycle/launcher',
            user: 'vcap',
            args: ['app', task.command, ''],
            env: task.environment_variables,
            log_source: "APP/TASK?#{task.name}",
            resource_limits: ''
          )

          serial([
            download_action,
            run_action
          ])
        end

        def cached_dependencies
          dependencies = [
            ::Diego::Bbs::Models::CachedDependency.new(
              from:      LifecycleBundleUriGenerator.uri(config[:diego][:lifecycle_bundles][lifecycle_bundle_key]),
              to:        '/tmp/lifecycle',
              cache_key: "buildpack-#{stack}-lifecycle",
            )
          ]

          dependencies.concat(
            lifecycle_data[:buildpacks].map do |buildpack|
              next if buildpack[:name] == 'custom'

              ::Diego::Bbs::Models::CachedDependency.new(
                name:      buildpack[:name],
                from:      buildpack[:url],
                to:        "/tmp/buildpacks/#{Digest::MD5.hexdigest(buildpack[:key])}",
                cache_key: buildpack[:key],
              )
            end.compact
          )
        end

        def stack
          task.app.lifecycle_data.stack
        end

        def task_environment_variables
          [::Diego::Bbs::Models::EnvironmentVariable.new(name: 'LANG', value: STAGING_DEFAULT_LANG)]
        end

        private

        def lifecycle_bundle_key
          "buildpack/#{stack}".to_sym
        end

        def upload_buildpack_artifacts_cache_uri
          upload_buildpack_artifacts_cache_uri       = URI(config[:diego][:cc_uploader_url])
          upload_buildpack_artifacts_cache_uri.path  = "/v1/build_artifacts/#{staging_details.droplet.guid}"
          upload_buildpack_artifacts_cache_uri.query = {
            'cc-build-artifacts-upload-uri' => lifecycle_data[:build_artifacts_cache_upload_uri],
            'timeout'                       => config[:staging][:timeout_in_seconds],
          }.to_param
          upload_buildpack_artifacts_cache_uri.to_s
        end

        def upload_droplet_uri
          upload_droplet_uri       = URI(config[:diego][:cc_uploader_url])
          upload_droplet_uri.path  = "/v1/droplet/#{staging_details.droplet.guid}"
          upload_droplet_uri.query = {
            'cc-droplet-upload-uri' => lifecycle_data[:droplet_upload_uri],
            'timeout'               => config[:staging][:timeout_in_seconds],
          }.to_param
          upload_droplet_uri.to_s
        end
      end
    end
  end
end
