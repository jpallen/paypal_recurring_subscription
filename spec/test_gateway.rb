class TestGateway
  attr_reader   :profiles
  
  class << self
    def get_profile_id
      return (0...8).map{ (0..9).to_a[rand(9)].to_s }.join
    end
    
    def get_token
      get_profile_id
    end
  end

  def succeed_in_creating_profile
    if @succeed_in_creating_profile.nil?
      @succeed_in_creating_profile = true
    end
    @succeed_in_creating_profile
  end
  
  def profiles
    @profiles ||= {}
  end
  
  def create_profile(token, options)
    profile_id = TestGateway.get_profile_id
    self.profiles[profile_id] = profile_details_from_options(options)
    return ActiveMerchant::Billing::Response.new(
      true,
      'Profile Created',
      {
        'profile_id' => profile_id
      }
    )
  end
  
  def get_profile_details(profile_id)
    return ActiveMerchant::Billing::Response.new(
      true,
      'Profile Returned',
      self.profiles[profile_id]
    )
  end
  
  def cancel_profile(profile_id)
    self.profiles[profile_id]['profile_status'] = 'CancelledProfile'
    self.profiles[profile_id].delete('next_billing_date')
    return ActiveMerchant::Billing::Response.new(
      true,
      'Profile Cancelled',
      {}
    )
  end
  
private

  def profile_details_from_options(options)
    options.merge(
      'profile_status'    => 'ActiveProfile',
      'next_billing_date' => ((options[:start_date] || Time.now) + 1.month).to_s
    )
  end
end
