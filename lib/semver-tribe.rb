require 'yaml'
require 'semver-tribe/semvermissingerror'

class SemVer

  FILE_NAME = '.semver'
  TAG_FORMAT = 'v%M.%m.%p%s'
  WILDCARD = 'x'

  def SemVer.find dir=nil
    v = SemVer.new
    f = SemVer.find_file dir
    v.load f
    v
  end

  def SemVer.find_file dir=nil
    dir ||= Dir.pwd
    raise "#{dir} is not a directory" unless File.directory? dir
    path = File.join dir, FILE_NAME

    Dir.chdir dir do
      while !File.exists? path do
        raise SemVerMissingError, "#{dir} is not semantic versioned", caller if File.dirname(path).match(/(\w:\/|\/)$/i)
        path = File.join File.dirname(path), ".."
        path = File.expand_path File.join(path, FILE_NAME)
        puts "semver: looking at #{path}"
      end
      return path
    end

  end

  attr_accessor :major, :minor, :patch, :special

  def initialize major=0, minor=0, patch=0, special=''
    is_valid_part(major) or raise "invalid major: #{major}"
    is_valid_part(minor) or raise "invalid minor: #{minor}"
    is_valid_part(patch) or raise "invalid patch: #{patch}"

    unless special.empty?
      special =~ /[A-Za-z][0-9A-Za-z\.]+/ or raise "invalid special: #{special}"
    end

    @major, @minor, @patch, @special = major, minor, patch, special
  end

  def is_valid_part(part)
    part.kind_of? Integer
  end

  def is_wildcard?
    false
  end

  def load file
    @file = file
    hash = YAML.load_file(file) || {}
    @major = hash[:major] or raise "invalid semver file: #{file}"
    @minor = hash[:minor] or raise "invalid semver file: #{file}"
    @patch = hash[:patch] or raise "invalid semver file: #{file}"
    @special = hash[:special]  or raise "invalid semver file: #{file}"
  end

  def save file=nil
    file ||= @file

    hash = {
      :major => @major,
      :minor => @minor,
      :patch => @patch,
      :special => @special
    }

    yaml = YAML.dump hash
    open(file, 'w') { |io| io.write yaml }
  end

  def format fmt
    fmt = fmt.gsub '%M', @major.to_s
    fmt = fmt.gsub '%m', @minor.to_s
    fmt = fmt.gsub '%p', @patch.to_s
    if @special.nil? or @special.length == 0 then
      fmt = fmt.gsub '%s', ''
    else
      fmt = fmt.gsub '%s', "-" + @special.to_s
    end
    fmt
  end

  def to_s
    format TAG_FORMAT
  end

  def <=> other
    maj = major.to_i <=> other.major.to_i
    return maj unless maj == 0

    min = minor.to_i <=> other.minor.to_i
    return min unless min == 0

    pat = patch.to_i <=> other.patch.to_i
    return pat unless pat == 0

    spe = special <=> other.special
    return spec unless spe == 0

    0
  end

  include Comparable

  # Parses a semver from a string and format.
  def self.parse(version_string, format = nil, allow_missing = true)
    format ||= TAG_FORMAT
    regex_str = Regexp.escape format

    # Convert all the format characters to named capture groups
    regex_str.gsub! '%M', '(?<major>(\d+|x|X))'
    regex_str.gsub! '%m', '(?<minor>(\d+|x|X))'
    regex_str.gsub! '%p', '(?<patch>(\d+|x|X))'
    regex_str.gsub! '%s', '(?:-(?<special>[A-Za-z][0-9A-Za-z\.]+))?'

    regex = Regexp.new regex_str
    match = regex.match version_string

    if match
        major = minor = patch = nil
        special = ''

        # Extract out the version parts
        major = extract_part_from_matches :major, match
        minor = extract_part_from_matches :minor, match
        patch = extract_part_from_matches :patch, match

        special = match[:special] || '' if match.names.include? 'special'

        # Failed parse if major, minor, or patch wasn't found
        # and allow_missing is false
        return nil if !allow_missing and [major, minor, patch].any? {|x| x.nil? }

        # Otherwise, allow them to default to zero
        major ||= 0
        minor ||= 0
        patch ||= 0

        if major == WILDCARD or minor == WILDCARD or patch == WILDCARD
          SemVerRange.new major, minor, patch, special
        else
          SemVer.new major, minor, patch, special
        end
    end
  end

  private

  def self.extract_part_from_matches(part_name, match)
    if match.names.include? part_name.to_s
      value = match[part_name]
      value = value.to_i unless value == WILDCARD
      value
    end
  end
end

class SemVerRange < SemVer

  def initialize major=0, minor=0, patch=0, special=''
    if major != WILDCARD and minor != WILDCARD and patch != WILDCARD
      raise "Invalid SemVerRange: #{major}.#{minor}.#{patch}"
    end

    super
  end

  def is_wildcard?
    true
  end

  def is_complete_wildcard
    major == WILDCARD && minor == WILDCARD && patch == WILDCARD && special.empty?
  end

  def is_valid_part(part)
    super or part == WILDCARD
  end

  def <=> other
    maj = compare_part major, other.major
    return maj unless maj == 0

    min = compare_part minor, other.minor
    return min unless min == 0

    pat = compare_part patch, other.patch
    return pat unless pat == 0

    spe = special <=> other.special
    return spec unless spe == 0

    0
  end

  def compare_part(my_part, other_part)
    if my_part == WILDCARD and other_part == WILDCARD
      0
    elsif my_part == WILDCARD
      1
    elsif other_part == WILDCARD
      -1
    else
      my_part.to_i <=> other_part.to_i
    end
  end

  def contains?(other)
    raise "semver\#contains? is unimplemented"
  end

  def upper_bound
    if major == WILDCARD
      nil
    elsif minor == WILDCARD
      SemVer.new major + 1, 0, 0, special
    elsif patch == WILDCARD
      SemVer.new major, minor + 1, 0, special
    end
  end

  # The part of the version that isn't wildcarded. E.g.
  #
  #    1.2.x => "1.2"
  #    2.x.x => "1"
  #    3.4.5 => nil
  #
  def non_wildcard_prefix(format = '%M.%m')
    format = format.dup

    if major == WILDCARD
      nil
    elsif minor == WILDCARD
      major.to_s
    elsif patch == WILDCARD
      format.gsub!('%M', major.to_s).gsub('%m', minor.to_s)
    end
  end

end
