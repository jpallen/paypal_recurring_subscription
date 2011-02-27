class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t| 
      t.string  :paypal_profile_id, :null => false
      t.string  :state, :null => false
      t.integer :pending_subscription_id
      t.date    :modify_on
      t.timestamps
      
      t.string  :plan_code, :null => false
      t.boolean :active
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
