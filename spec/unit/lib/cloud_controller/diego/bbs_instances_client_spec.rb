require 'spec_helper'

module VCAP::CloudController::Diego
  RSpec.describe BbsInstancesClient do
    subject(:client) { BbsInstancesClient.new(bbs_client) }
    let(:bbs_client) { instance_double(::Diego::Client) }

    describe '#lrp_instances' do
      let(:bbs_response) { ::Diego::Bbs::Models::ActualLRPGroupsResponse.new(actual_lrp_groups: actual_lrp_groups) }
      let(:actual_lrp_groups) { [actual_lrp_group] }
      let(:actual_lrp_group) { ::Diego::Bbs::Models::ActualLRPGroup.new(instance: actual_lrp) }
      let(:actual_lrp) { ::Diego::Bbs::Models::ActualLRP.new(state: 'potato') }
      let(:process) { VCAP::CloudController::AppFactory.make }
      let(:process_guid) { ProcessGuid.from_process(process) }

      before do
        allow(bbs_client).to receive(:actual_lrp_groups_by_process_guid).with(process_guid).and_return(bbs_response)
      end

      it 'sends the lrp instances request to diego' do
        client.lrp_instances(process)
        expect(bbs_client).to have_received(:actual_lrp_groups_by_process_guid).with(process_guid)
      end

      it 'returns a resolved list of actual LRPs' do
        resolved_actual_lrp = ::Diego::Bbs::Models::ActualLRP.new(state: 'yuca')
        allow(::Diego::ActualLRPGroupResolver).to receive(:get_lrp).with(actual_lrp_group).and_return(resolved_actual_lrp)
        expect(client.lrp_instances(process)).to eq([resolved_actual_lrp])
      end

      context 'when the response contains an error' do
        let(:bbs_response) do
          ::Diego::Bbs::Models::ActualLRPGroupsResponse.new(error: ::Diego::Bbs::Models::Error.new(message: 'error-message'))
        end

        it 'raises' do
          expect {
            client.lrp_instances(process)
          }.to raise_error(CloudController::Errors::InstancesUnavailable, 'error-message')
        end
      end

      context 'when a Diego error is thrown' do
        before do
          allow(bbs_client).to receive(:actual_lrp_groups_by_process_guid).with(process_guid).and_raise(::Diego::Error.new('boom'))
        end

        it 're-raises with a CC Error' do
          expect {
            client.lrp_instances(process)
          }.to raise_error(CloudController::Errors::InstancesUnavailable, 'boom')
        end
      end
    end
  end
end
