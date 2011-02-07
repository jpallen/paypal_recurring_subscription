require File.join(File.dirname(__FILE__), '../spec_helper')

class Subscription < ActiveRecord::Base
  include PaypalRecurringSubscription
  
  def profile_options
    self.class.profile_options
  end
end

def create_gateway_mock(options = {})
  gateway_mock = mock('ActiveMerchant::Billing::PaypalExpressRecurringGateway')
  return gateway_mock
end

def successful_create_profile_response_mock(options = {})
  response_mock = mock('ActiveMerchant::Billing::Response')
  response_mock.stub!('success?').and_return(true)
  response_mock.stub!('params').and_return({
    'profile_id' => get_profile_id
  })
  return response_mock
end

def successful_create_profile_response_mock(options = {})
  response_mock = mock('ActiveMerchant::Billing::Response')
  response_mock.stub!('success?').and_return(true)
  response_mock.stub!('params').and_return({
    'profile_id' => get_profile_id
  })
  return response_mock
end

def failed_create_profile_response_mock(options = {})
  response_mock = mock('ActiveMerchant::Billing::Response')
  response_mock.stub!('success?').and_return(false)
  response_mock.stub!('message').and_return('Profile was not created')
  return response_mock
end

def get_profile_id
  return (0...8).map{ (0..9).to_a[rand(9)].to_s }.join
end

def get_token
  get_profile_id
end

def get_profile_options
  {
    :description => 'Test subscription',
    :frequency   => 1,
    :amount      => 1000
  }
end

describe Subscription, 'on creation' do
  before do
    Subscription.stub!(:profile_options).and_return(get_profile_options)
    Subscription.gateway = @gateway_mock = create_gateway_mock
    Timecop.freeze
    @s = Subscription.new(
      :token => @tok = get_token
    )
  end

  it "should create a new paypal profile" do
    @gateway_mock.stub!(:create_profile).and_return(
      @resp = successful_create_profile_response_mock
    )
    @gateway_mock.should_receive(:create_profile).with(@tok, 
      Subscription.profile_options.merge({
        :start_date => Time.now
      })
    )
    
    @s.save.should be_true
    @s.paypal_profile_id.should eql @resp.params['profile_id']
  end
  
  it "should not be saved if a paypal profile was not created" do
    @gateway_mock.stub!(:create_profile).and_return(
      @resp = failed_create_profile_response_mock
    )
    
    @s.save.should be_false
    @s.errors.on(:base).should include @resp.message
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
