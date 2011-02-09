require File.join(File.dirname(__FILE__), '../spec_helper')

describe Subscription, 'on creation' do
  before do
    Subscription.gateway = @gateway = TestGateway.new
    Timecop.freeze
    @s = Subscription.new(
      :token => @tok = TestGateway.get_token
    )
  end

  it "should create a new paypal profile" do
    @gateway.should_receive(:create_profile).with(@tok, 
      Subscription.profile_options.merge({
        :start_date => Time.now
      })
    ).and_return(
      @resp = successful_create_profile_response_mock
    )
    
    @s.save.should be_true
    @s.paypal_profile_id.should eql @resp.params['profile_id']
  end
  
  it "should create a new profile with an initial amount" do
    @gateway.should_receive(:create_profile).with(@tok, 
      Subscription.profile_options.merge({
        :start_date     => Time.now,
        :initial_amount => @initial_amount = 1000
      })
    ).and_return(
      @resp = successful_create_profile_response_mock
    )
    
    @s.initial_amount = @initial_amount
    @s.save.should be_true
  end
  
  it "should not be saved if the create profile request was not successful" do
    @gateway.should_receive(:create_profile).and_return(
      @resp = failed_create_profile_response_mock
    )
    
    @s.save.should be_false
    @s.errors.on(:base).should include @resp.message
  end
end

describe Subscription, 'on cancellation' do
  before do 
    Subscription.gateway = @gateway = TestGateway.new
    @s = Subscription.create
  end
  
  it 'should cancel the paypal profile' do
    @gateway.should_receive('cancel_profile').and_return(successful_cancel_profile_response_mock)
    @s.cancel.should be_true
  end
end

describe Subscription, 'without gateway' do
  it "should throw an exception if the gateway is not configured" do
    Subscription.gateway = nil
    lambda {
      Subscription.gateway
    }.should raise_error(PRS::GatewayNotConfigured)
  end
end
