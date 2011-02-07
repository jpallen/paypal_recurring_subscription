# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "paypal_recurring_subscription/version"

Gem::Specification.new do |s|
  s.name        = "paypal_recurring_subscription"
  s.version     = PaypalRecurringSubscription::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James Allen"]
  s.email       = ["james@scribtex.com"]
  s.homepage    = ""
  s.summary     = %q{Handles the recurring billing logic behind creating, updating and cancelling recurring subscriptions via Paypal Websites Payments Pro.}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "paypal_recurring_subscription"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "active_merchant"
  s.add_development_dependency "rspec"
  s.add_development_dependency "timecop"
  s.add_development_dependency "active_record"
end
