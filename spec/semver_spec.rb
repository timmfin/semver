require 'semver-tribe'
require 'tempfile'

describe SemVer do

  it "should compare against another version versions" do
    v1 = SemVer.new 0,1,0
    v2 = SemVer.new 0,1,1
    v1.should < v2
  end

  it "should serialize to and from a file" do
    tf = Tempfile.new 'semver.spec'
    path = tf.path
    tf.close!

    v1 = SemVer.new 1,10,33
    v1.save path
    v2 = SemVer.new
    v2.load path

    v1.should == v2
  end

  it "should find an ancestral .semver" do
    SemVer.find.should be_a_kind_of(SemVer)
  end
  
  # Semantic Versioning 2.0.0-rc.1
  
  it "should format with fields" do
    v = SemVer.new 10, 33, 4, 'beta'
    v.format("v%M.%m.%p%s").should == "v10.33.4-beta"
  end

  it "should to_s with dash" do
    v = SemVer.new 4,5,63, 'alpha.45'
    v.to_s.should == 'v4.5.63-alpha.45'
  end
  
  it "should format with dash" do
    v = SemVer.new 2,5,11,'a.5'
    v.format("%M.%m.%p%s").should == '2.5.11-a.5'
  end
  
  it "should not format with dash if no special" do
    v = SemVer.new 2,5,11
    v.format("%M.%m.%p%s").should == "2.5.11"
  end
  
  it "should not to_s with dash if no special" do
    v = SemVer.new 2,5,11
    v.to_s.should == "v2.5.11"
  end
  
  it "should behave like the readme says" do
    v = SemVer.new(0,0,0)
    v.major                     # => "0"
    v.major += 1
    v.major                     # => "1"
    v.special = 'alpha.46'
    v.format "%M.%m.%p%s"       # => "1.1.0-alpha.46"
    v.to_s                      # => "v1.1.0"
  end


  it "should parse formats correctly" do
    semver_strs = [
      'v1.2.3',
      'v1.2.3',
      '0.10.100-b32',
      'version:3-0-45',
      '3$2^1',
      '3$2^1-bla567',
    ]

    formats = [
      nil,
      SemVer::TAG_FORMAT,
      '%M.%m.%p%s',
      'version:%M-%m-%p',
      '%M$%m^%p',
      '%M$%m^%p%s',
    ]

    semvers= [
      SemVer.new(1, 2, 3),
      SemVer.new(1, 2, 3),
      SemVer.new(0, 10, 100, 'b32'),
      SemVer.new(3, 0, 45),
      SemVer.new(3, 2, 1),
      SemVer.new(3, 2, 1, 'bla567'),
    ]

    semver_strs.zip(formats, semvers).each do |args|
      str, format, semver = args
      SemVer.parse(str, format).should eq(semver)
    end
  end

  it "should only allow missing version parts when allow_missing is set" do
    semver_strs = [
      'v1',
      'v1',
      'v1',

      'v1.2',
      'v1.2',
    ]

    formats = [
      'v%M',
      'v%m',
      'v%p',

      'v%M.%m',
      'v%m.%p',
    ]

    semvers= [
      SemVer.new(1, 0, 0),
      SemVer.new(0, 1, 0),
      SemVer.new(0, 0, 1),

      SemVer.new(1, 2, 0),
      SemVer.new(0, 1, 2),
    ]

    semver_strs.zip(formats, semvers).each do |args|
      str, format, semver = args

      SemVer.parse(str, format).should eq(semver)
      SemVer.parse(str, format, true).should eq(semver)

      SemVer.parse(str, format, false).should be_nil
    end
  end

  it "should parse wildcard versiosn" do
    semver_strs = [
      'v1.2.x',
      'v1.x.x',
      'v1.x.x-beta',
    ]

    semvers= [
      SemVerRange.new(1, 2, 'x'),
      SemVerRange.new(1, 'x', 'x'),
      SemVerRange.new(1, 'x', 'x', 'beta'),
    ]

    semver_strs.zip(semvers).each do |args|
      str, semver = args
      parsed_semvar = SemVer.parse(str)
      parsed_semvar.is_wildcard?.should be_true
      parsed_semvar.should eq(semver)
    end
  end
end

describe 'SemVerRange' do

  it "should have format output with x's" do
    semver_ranges = [
      SemVerRange.new(1, 2, 'x'),
      SemVerRange.new(1, 'x', 'x'),
      SemVerRange.new(1, 'x', 'x', 'beta'),
    ]

    results = [
      'v1.2.x',
      'v1.x.x',
      'v1.x.x-beta',
    ]

    semver_ranges.zip(results).each do |(range, output)|
      range.to_s.should eq(output)
    end
  end

  it "should have upper bounds" do
    semver_ranges = [
      SemVerRange.new(1, 2, 'x'),
      SemVerRange.new(1, 'x', 'x'),
      SemVerRange.new(1, 'x', 'x', 'beta'),
    ]

    semvers= [
      SemVer.new(1, 3, 0),
      SemVer.new(2, 0, 0),
      SemVer.new(2, 0, 0, 'beta'),
    ]

    semver_ranges.zip(semvers).each do |args|
      range, semver = args
      range.upper_bound.should eq(semver)
    end
  end

  it "should wildcard prefixes" do
    semver_ranges = [
      SemVerRange.new(1, 2, 'x'),
      SemVerRange.new(1, 'x', 'x'),
      SemVerRange.new(1, 'x', 'x', 'beta'),
    ]

    prefixes = [
      '1.2',
      '1',
      '1',
    ]

    semver_ranges.zip(prefixes).each do |(range, prefix)|
      range.non_wildcard_prefix.should eq(prefix)
    end
  end

end
