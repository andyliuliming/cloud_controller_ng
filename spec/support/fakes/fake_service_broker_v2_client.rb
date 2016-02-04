class FakeServiceBrokerV2Client
  def initialize(_attrs)
  end

  def catalog
    {
      'services' => [{
        'id'          => 'service_id',
        'name'        => 'service_name',
        'description' => 'some description',
        'bindable'    => true,
        'plans'       => [{
          'id'          => 'fake_plan_id',
          'name'        => 'fake_plan_name',
          'description' => 'fake_plan_description'
        }]
      }]
    }
  end

  def provision(_instance, arbitrary_parameters: {}, accepts_incomplete: false)
    {
      instance:       {
        credentials:   {},
        dashboard_url: nil
      },
      last_operation: {
        type:        'create',
        description: '',
        state:       'succeeded'
      }
    }
  end

  def bind(_binding, _arbitrary_parameters)
    {
      credentials: { 'username' => 'cool_user' }
    }
  end
end
