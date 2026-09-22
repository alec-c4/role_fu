# frozen_string_literal: true

RSpec.describe RoleFu::Authorizable do
  let(:user) { User.create(name: "Test User") }

  let(:controller_class) do
    Class.new do
      include RoleFu::Authorizable

      attr_accessor :current_user
    end
  end

  let(:controller) { controller_class.new }

  before { controller.current_user = user }

  describe "#role_fu_authorize!" do
    it "returns true when the user has the role" do
      user.grant(:admin)
      expect(controller.role_fu_authorize!(:admin)).to be true
    end

    it "raises RoleFu::AccessDenied when the user lacks the role" do
      expect { controller.role_fu_authorize!(:admin) }.to raise_error(RoleFu::AccessDenied)
    end

    it "raises when there is no current user" do
      controller.current_user = nil
      expect { controller.role_fu_authorize!(:admin) }.to raise_error(RoleFu::AccessDenied)
    end
  end

  describe "#role_fu_can!" do
    it "returns true when the ability is granted" do
      role = user.add_role(:editor)
      role.permissions.create(action: "posts.update")

      expect(controller.role_fu_can!("posts.update")).to be true
    end

    it "raises RoleFu::AccessDenied when the ability is missing" do
      expect { controller.role_fu_can!("posts.update") }.to raise_error(RoleFu::AccessDenied)
    end

    it "respects field-level restrictions" do
      role = user.add_role(:support)
      role.permissions.create(action: "posts.update", field: "title")

      expect(controller.role_fu_can!("posts.update", field: :title)).to be true
      expect { controller.role_fu_can!("posts.update", field: :body) }.to raise_error(RoleFu::AccessDenied)
    end
  end

  it "supports overriding role_fu_current_user for non-controller objects" do
    job_class = Class.new do
      include RoleFu::Authorizable

      attr_accessor :actor

      def role_fu_current_user
        actor
      end
    end

    job = job_class.new
    job.actor = user
    user.grant(:admin)

    expect(job.role_fu_authorize!(:admin)).to be true
  end
end
