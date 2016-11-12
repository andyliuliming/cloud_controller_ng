require 'spec_helper'
require 'cloud_controller/diego/task_protocol'

module VCAP::CloudController
  module Diego
    module Buildpack
      RSpec.describe TaskActionBuilder do
        subject(:builder) { described_class.new(config, task) }

        let(:droplet) { DropletModel.make(:buildpack) }
        let(:config) do
          {
            skip_cert_verify: false,
            diego:            {
              cc_uploader_url:   'http://cc-uploader.example.com',
              file_server_url:   'http://file-server.example.com',
              lifecycle_bundles: {
                'buildpack/buildpack-stack': 'the-buildpack-bundle'
              },
            },
            staging:          {
              minimum_staging_file_descriptor_limit: 4,
              timeout_in_seconds:                    90,
            },
          }
        end
        let(:task) { TaskModel.make }
        let(:env) { double(:env) }
        let(:buildpacks) { [] }
        let(:generated_environment) { [::Diego::Bbs::Models::EnvironmentVariable.new(name: 'generated-environment', value: 'generated-value')] }

        before do
          allow(LifecycleBundleUriGenerator).to receive(:uri).with('the-buildpack-bundle').and_return('generated-uri')
          allow(BbsEnvironmentBuilder).to receive(:build).with(env).and_return(generated_environment)
        end

        describe '#action' do
          let(:download_app_droplet_action) do
            ::Diego::Bbs::Models::DownloadAction.new(
              artifact: 'app droplet',
              from:     'http://app_bits_download_uri.example.com/path/to/bits',
              to:       '/tmp/app',
              user:     'vcap'
            )
          end
          let(:run_task_action) do
            ::Diego::Bbs::Models::RunAction.new(
              path: 'tmp/lifecycle/launcher',
              user: 'vcap',
              args: ['app', task.command, ''],
              env: task.environment_variables,
              log_source: "APP/TASK?#{task.name}",
              resource_limits: ''
            )
          end

          it 'returns the correct buildpack-app task action structure' do
            result = builder.action

            serial_action = result.serial_action
            actions       = serial_action.actions

            expect(actions[0].download_action).to eq(download_app_droplet_action)
            expect(actions[1].run_action).to eq(run_task_action)
          end
        end

        describe '#cached_dependencies' do
          it 'always returns the builpdack lifecycle bundle dependency' do
            result = builder.cached_dependencies
            expect(result).to include(
              ::Diego::Bbs::Models::CachedDependency.new(
                from:      'generated-uri',
                to:        '/tmp/lifecycle',
                cache_key: 'buildpack-buildpack-stack-lifecycle',
              )
            )
          end

          context 'when there are buildpacks' do
            let(:buildpacks) do
              [
                { name: 'buildpack-1', key: 'buildpack-1-key', url: 'buildpack-1-url', skip_detect: false },
                { name: 'buildpack-2', key: 'buildpack-2-key', url: 'buildpack-2-url', skip_detect: true },
              ]
            end

            it 'includes buildpack dependencies' do
              buildpack_entry_1 = ::Diego::Bbs::Models::CachedDependency.new(
                name:      'buildpack-1',
                from:      'buildpack-1-url',
                to:        "/tmp/buildpacks/#{Digest::MD5.hexdigest('buildpack-1-key')}",
                cache_key: 'buildpack-1-key',
              )
              buildpack_entry_2 = ::Diego::Bbs::Models::CachedDependency.new(
                name:      'buildpack-2',
                from:      'buildpack-2-url',
                to:        "/tmp/buildpacks/#{Digest::MD5.hexdigest('buildpack-2-key')}",
                cache_key: 'buildpack-2-key',
              )

              result = builder.cached_dependencies
              expect(result).to include(buildpack_entry_1, buildpack_entry_2)
            end
          end

          context 'when there are custom buildpacks' do
            let(:buildpacks) do
              [
                { name: 'buildpack-1', key: 'buildpack-1-key', url: 'buildpack-1-url', skip_detect: false },
                { name: 'custom', key: 'custom-key', url: 'custom-url', skip_detect: true },
              ]
            end

            it 'does not include the custom buildpacks' do
              buildpack_entry_1 = ::Diego::Bbs::Models::CachedDependency.new(
                name:      'buildpack-1',
                from:      'buildpack-1-url',
                to:        "/tmp/buildpacks/#{Digest::MD5.hexdigest('buildpack-1-key')}",
                cache_key: 'buildpack-1-key',
              )
              buildpack_entry_2 = ::Diego::Bbs::Models::CachedDependency.new(
                name:      'custom',
                from:      'custom-url',
                to:        "/tmp/buildpacks/#{Digest::MD5.hexdigest('custom-key')}",
                cache_key: 'custom-key',
              )

              result = builder.cached_dependencies
              expect(result).to include(buildpack_entry_1)
              expect(result).not_to include(buildpack_entry_2)
            end
          end
        end

        describe '#stack' do
          it 'returns the stack' do
            expect(builder.stack).to eq('buildpack-stack')
          end
        end

        describe '#task_environment_variables' do
          it 'returns LANG' do
            lang_env = ::Diego::Bbs::Models::EnvironmentVariable.new(name: 'LANG', value: 'en_US.UTF-8')
            expect(builder.task_environment_variables).to match_array([lang_env])
          end
        end
      end
    end
  end
end
