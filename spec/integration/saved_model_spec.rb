require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "models"))

describe "integration" do

  use_real_transport!

  before :each do
    create_users_and_memberships
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

  describe "count" do

    it "should return the number of users" do
      User.count.should >= 2
    end

  end

  describe "all" do

    it "should include the saved user" do
      User.all.should include(@user_one)
      User.all.should include(@user_two)
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

  describe "birthday" do

    it "should return the correct date" do
      @user_one.reload
      @user_one.birthday.should == Date.parse("2000/07/07")

      @user_two.reload
      @user_two.birthday.should == Date.parse("2010/02/20")
    end

  end

  describe "lunch" do

    it "should return the correct time" do
      @user_one.reload
      @user_one.lunch.should == Time.parse("2010/10/21 12:13:14")

      @user_two.reload
      @user_two.lunch.should == Time.parse("2010/10/21 12:13:14")
    end

  end

end
