# frozen_string_literal: true

require "rspec"

# Helper method to easily mock the actor-helper
# This is useful when your site-client wants to use the actor-helper
# but you want to save on the extra HTTP call on the test
# Usage:
#
# include_context "actor-helper stubber"
# before { stub_actor(config, "actor", "female") }
#
shared_context "actor-helper stubber" do
  def disable_actor_fetch(config)
    allow(config).to receive(:actor_helper).and_return(_stub_actor_helper)
    allow(_stub_actor_helper).to receive(:auto_fetch!)
    allow(_stub_actor_helper).to receive(:male?).and_return(true)
    allow(_stub_actor_helper).to receive(:female?).and_return(true)
  end

  def stub_actor(config, actor, gender)
    allow(config).to receive(:actor_helper).and_return(_stub_actor_helper)

    allow(_stub_actor_helper).to receive(:auto_fetch!).with(actor)
    case gender
    when "male"
      allow(_stub_actor_helper).to receive(:male?).with(actor).and_return(true)
      allow(_stub_actor_helper).to receive(:female?).with(actor).and_return(false)
    when "female"
      allow(_stub_actor_helper).to receive(:male?).with(actor).and_return(false)
      allow(_stub_actor_helper).to receive(:female?).with(actor).and_return(true)
    else
      raise "unsupported actor (#{gender}) provided for actor"
    end
  end

  def _stub_actor_helper
    @_stub_actor_helper ||= instance_double("XxxRename::ActorsHelper")
  end
end
