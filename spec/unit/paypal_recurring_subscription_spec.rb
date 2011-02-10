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
      @s.profile_options.merge({
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
      @s.profile_options.merge({
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

describe Subscription, 'modification' do
  before do
    Subscription.gateway = @gateway = TestGateway.new
    Timecop.freeze
    @s = Subscription.create(
      :token => @tok = TestGateway.get_token
    )
  end
  
  describe 'with :timeframe => :now' do
    it 'should cancel the old profile' do
      @gateway.should_receive(:cancel_profile).with(@s.paypal_profile_id).and_return(
        @resp = successful_cancel_profile_response_mock
      )
      
      @s.modify(:token => TestGateway.get_token, :plan_code => 'plan_two', :timeframe => :now)
    end
    
    it 'should create a new subscription and profile' do
      @gateway.should_receive(:create_profile).and_return(
        @resp = successful_create_profile_response_mock
      )
      
      @s.modify(:token => TestGateway.get_token, :plan_code => 'plan_two')
      
      @new_s = Subscription.find(:all).reject{|s| s == @s}.first
      @new_s.paypal_profile_id.should eql @resp.params['profile_id']
      @new_s.state.should eql PRS::State::ACTIVE
      @new_s.plan_code.should eql 'plan_two'
    end
    
    it 'should deactivate the old subscription' do
      @s.should_receive(:deactivate)
      @s.modify(:token => @tok, :plan_code => 'plan_two', :timeframe => :now)
      @s.state.should eql PRS::State::INACTIVE
    end
    
    it 'should activate the new subscription'
    
    it 'should add an initial amount when upgrading' do
      Timecop.travel(@s.next_payment_due - 10.days)
      # We have paid $10 for this month, so should get back $10/3 (assuming
      # all months are 30 days). However, we need to pay $20/3 for the 
      # new subscription for the rest of the month. So we should should pay
      # $10/3 now, and then the regular subscription when the next payment
      # is due.
      @gateway.should_receive(:create_profile).with(
        @tok = TestGateway.get_token,
        Subscription.profiles['quarterly_2000_per_month'].merge({
          :start_date     => @s.next_payment_due,
          :initial_amount => (1000/3.0).to_i
        })
      ).and_return(@resp = successful_create_profile_response_mock)
      
      @s.modify(:token => @tok, :plan_code => 'quarterly_2000_per_month', :timeframe => :now)
      
      @new_s = Subscription.find(:all).reject{|s| s == @s}.first
      @new_s.paypal_profile_id.should eql @resp.params['profile_id']
      @new_s.state.should eql PRS::State::ACTIVE
      @new_s.plan_code.should eql 'quarterly_2000_per_month'
    end
    
    it 'should refund an amount when downgrading'
    
    it 'should fail gracefully'
    
    it 'should error if left in an inconsistent state'
  end
  
  describe 'with :timeframe => :renewal' do
    it 'should cancel the old profile' do
      @gateway.should_receive(:cancel_profile).with(@s.paypal_profile_id).and_return(
        @resp = successful_cancel_profile_response_mock
      )
      
      @s.modify(:token => @tok, :plan_code => 'plan_two', :timeframe => :renewal)
    end
    
    it 'should create a new subscription and profile' do
      @gateway.should_receive(:create_profile).with(
        @tok = TestGateway.get_token,
        Subscription.profiles['plan_two'].merge({
          :start_date => @s.next_payment_due
        })
      ).and_return(@resp = successful_create_profile_response_mock)
      
      @s.modify(:token => @tok, :plan_code => 'plan_two', :timeframe => :renewal)
      
      @new_s = @s.pending_subscription(true)
      @new_s.paypal_profile_id.should eql @resp.params['profile_id']
      @new_s.state.should eql PRS::State::PENDING
      @new_s.plan_code.should eql 'plan_two'
    end
    
    it 'should mark the old subscription as changed' do
      next_payment_date = @s.next_payment_due
      @s.modify(:token => @tok, :plan_code => 'plan_two', :timeframe => :renewal)
      @s.state.should eql PRS::State::CHANGED
      @s.modify_on.should eql next_payment_date
    end
    
    it 'should fail gracefully'
    
    it 'should error if left in an inconsistent state'
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
  
  it 'should deactivate the subscription immediately' do
    @s.should_receive(:deactivate)
    @s.cancel(:timeframe => :now).should be_true
    @s.state.should eql PRS::State::INACTIVE
  end
  
  it 'should schedule to subscription for deactivation when the next payment is due' do
    next_payment_date = @s.next_payment_due
    @s.should_not_receive(:deactivate)
    @s.cancel(:timeframe => :renewal).should be_true
    @s.state.should eql PRS::State::CANCELLED
    @s.modify_on.should eql next_payment_date
  end
  
  it 'should not be saved if the profile cancellation request was not successful' do
    @gateway.should_receive(:cancel_profile).with(@s.paypal_profile_id).and_return(
      @resp = failed_cancel_profile_response_mock
    )
    
    @s.cancel.should be_false
    @s.errors.on(:base).should include @resp.message
    @s.reload.state.should eql PRS::State::ACTIVE
  end
  
  it 'should not try to cancel an already cancelled profile' do
    @gateway.cancel_profile(@s.paypal_profile_id)
    @gateway.should_not_receive(:cancel_profile)
    @s.cancel
  end
  
  it 'should cancel the pending subscription' do
    @s.modify(:token => @tok, :plan_code => 'plan_two', :timeframe => :renewal)
    
    @s.should_not_receive(:cancel_profile)
    @s.pending_subscription.should_receive(:cancel)
    @s.cancel
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
