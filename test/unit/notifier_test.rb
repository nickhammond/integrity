require File.dirname(__FILE__) + "/../helpers"

class NotifierTest < Test::Unit::TestCase
  specify "IRC fixture is valid and can be saved" do
    lambda do
      Notifier.generate(:irc).tap do |project|
        project.should be_valid
        project.save
      end
    end.should change(Project, :count).by(1)
  end

  specify "Twitter fixture is valid and can be saved" do
    lambda do
      Notifier.generate(:twitter).tap do |project|
        project.should be_valid
        project.save
      end
    end.should change(Project, :count).by(1)
  end

  describe "Properties" do
    before(:each) do
      @notifier = Notifier.generate(:irc)
    end

    it "has a name" do
      @notifier.name.should == "IRC"
    end

    it "has a config" do
      @notifier.config.should == {:uri => "irc://irc.freenode.net/integrity"}
    end
  end

  describe "Validation" do
    it "requires a name" do
      lambda do
        Notifier.generate(:irc, :name => nil)
      end.should_not change(Notifier, :count)
    end

    it "requires a config" do
      lambda do
        Notifier.generate(:irc, :config => nil)
      end.should_not change(Notifier, :count)
    end

    it "requires a project" do
      lambda do
        Notifier.generate(:irc, :project => nil)
      end.should_not change(Notifier, :count)
    end

    it "requires an unique name in project scope" do
      project = Project.generate
      irc     = Notifier.gen(:irc, :project => project)

      project.tap { |project| project.notifiers << irc }.save

      lambda do
        project.tap { |project| project.notifiers << irc }.save
      end.should_not change(project.notifiers, :count).from(1).to(2)

      lambda { Notifier.gen(:irc) }.should change(Notifier, :count).to(2)
    end
  end

  it "knows which notifiers are available" do
    Notifier.gen(:irc)
    Notifier.gen(:twitter)
    Notifier.should have(2).available
    Notifier.available.should include(Integrity::Notifier::IRC)
    Notifier.available.should include(Integrity::Notifier::Twitter)
  end

  it "knows how to notify the world of a build" do
    irc   = Notifier.generate(:irc)
    build = Integrity::Build.generate
    Notifier::IRC.expects(:notify_of_build).with(build, irc.config)
    irc.notify_of_build(build)
  end
end
