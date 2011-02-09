$: << File.join(File.dirname(__FILE__), '..', 'lib')

require File.join(File.dirname(__FILE__), 'test_gateway')
require 'paypal_recurring_subscription'

require 'rubygems'
require 'active_record'
require 'active_merchant'
require 'timecop'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => File.join(File.dirname(__FILE__), 'db/test.sqlite3')
)

Spec::Runner.configure do |config|
  # Start with a fresh database for each test
  config.before(:each) do
    ActiveRecord::Base.connection.execute('DELETE FROM subscriptions')
  end
end

# Stop our code looking like Java
PRS = PaypalRecurringSubscription

class Subscription < ActiveRecord::Base
  include PaypalRecurringSubscription
  
  def profile_options
    self.class.profile_options
  end
  
  def self.profile_options
    get_profile_options
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
    'profile_id' => TestGateway.get_profile_id
  })
  return response_mock
end

def failed_create_profile_response_mock(options = {})
  response_mock = mock('ActiveMerchant::Billing::Response')
  response_mock.stub!('success?').and_return(false)
  response_mock.stub!('message').and_return('Profile was not created')
  return response_mock
end

def successful_cancel_profile_response_mock
  response_mock = mock('ActiveMerchant::Billing::Response')
  response_mock.stub!('success?').and_return(true)
  return response_mock
end

def get_profile_options
  {
    :description => 'Test subscription',
    :frequency   => 1,
    :amount      => 1000
  }
end
