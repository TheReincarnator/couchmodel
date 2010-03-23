require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "couch_model"))

CouchModel::Configuration.design_directory = File.join File.dirname(__FILE__), "design"

DATABASE = {
  :url                => "http://localhost:5984/test",
  :create_if_missing  => true,
  :delete_if_exists   => true,
  :push_design        => true
}.freeze unless defined?(DATABASE)

class User < CouchModel::Base

  setup_database DATABASE

  key_accessor :username
  key_accessor :email

  has_many :memberships,
           :class_name  => "Membership",
           :view_name   => :by_user_id_and_created_at,
           :query       => lambda { |created_at| { :startkey => [ self.id, (created_at || nil) ], :endkey => [ self.id, (created_at || { }) ] } }

end

class Membership < CouchModel::Base

  setup_database DATABASE

  key_accessor :created_at

  belongs_to :user, :class_name => "User"

end

describe "integration" do

  use_real_transport!

  context "on new models" do

    before :each do
      @user = User.new :username => "user", :email => "email"
    end

    describe "setup" do

      it "should have been created the database" do
        User.database.exists?.should be_true
      end

      it "should have been created the design" do
        User.design.exists?.should be_true
      end

      it "should setup unique databases" do
        User.database.should === Membership.database
      end

      it "should setup designs for each model" do
        User.design.should_not == Membership.design
      end

    end

    describe "save" do

      it "should create the model" do
        @user.save
        @user.should_not be_new
      end

      it "should return true" do
        @user.save.should be_true
      end

    end

  end

  context "on saved models" do

    before :each do
      @user_one = User.create :username => "user one", :email => "email one"
      @user_two = User.create :username => "user two", :email => "email two"
      @membership_one = Membership.create :created_at => "yesterday", :user => @user_one
      @membership_two = Membership.create :created_at => "yesterday", :user => @user_two
    end

    describe "save" do

      before :each do
        @user_one.username = "new username"
      end

      it "should update the model" do
        @user_one.save
        @user_one.username.should == "new username"
      end

      it "should return true" do
        @user_one.save.should be_true
      end

    end

    describe "destroy" do

      it "should return true" do
        @user_one.destroy.should be_true
      end

      it "should set the model to new" do
        @user_one.destroy
        @user_one.should be_new
      end

    end

    describe "all" do

      it "should include the saved user" do
        User.all.should include(@user_one)
        User.all.should include(@user_two)
      end

    end

    describe "count" do

      it "should return the number of users" do
        User.count.should >= 2
      end

    end

    describe "belongs_to" do

      it "should return the related model" do
        @membership_one.user.should == @user_one
        @membership_two.user.should == @user_two
      end

    end

    describe "has_many" do

      it "should include the related model" do
        @user_one.memberships.should include(@membership_one)
        @user_two.memberships.should include(@membership_two)
      end

      it "should not include the not-related model" do
        @user_one.memberships.should_not include(@membership_two)
        @user_two.memberships.should_not include(@membership_one)
      end

      it "should use the selector" do
        @user_one.memberships("yesterday").should include(@membership_one)
        @user_one.memberships("today").should_not include(@membership_one)
      end

    end

    describe "user_count" do

      before :each do
        @rows = User.user_count :returns => :rows
      end

      it "should return the user count" do
        @rows.first.value.should >= 2
      end

    end

  end

end
