$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'paypal_recurring_subscription'

require 'rubygems'
require 'active_record'
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

