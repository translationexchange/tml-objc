namespace :test do
  desc "Run All Tests"
  task :all => ['tml'] do |name|
    if $success
      puts "\033[0;32m** Test '#{name}' finished successfully."
    else
      puts "\033[0;31m! Test '#{name}' failed!"
    end
  end

  desc "TMLKit Tests"
  task :tml do
    $success = system("xctool -workspace TMLKit/TMLKit.xcworkspace -scheme 'TMLKit' -sdk iphonesimulator -configuration Release GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES test -test-sdk iphonesimulator")
  end
end

namespace :build do
  desc "Run All Builds"
  task :all => ['demo', 'tmlsandbox'] do |name|
    if $success
      puts "\033[0;32m** Build '#{name}' finished successfully."
    else
      puts "\033[0;31m! Build '#{name}' failed!"
    end
  end

  desc "Demo Build"
  task :demo do
    $success = system("xctool -workspace Demo/Demo.xcworkspace -scheme 'Demo' -sdk iphonesimulator -configuration Release build")
  end

  desc "TMLSandbox Build"
  task :tmlsandbox do
    $success = system("xctool -workspace TMLSandbox/TMLSandbox.xcworkspace -scheme 'TMLSandbox' -sdk iphonesimulator -configuration Release build")
  end
end

namespace :info do
  desc "All Info"
  task :all => [:versions] do
  end

  desc "Informational details"
  task :versions do
    puts "#{podspec_path} v.#{podspec_version}"
    puts "TMLKit v.#{tml_version}"
  end
end

desc "Execute all test and build tasks"
task :all => ['info:all', 'test:all', 'build:all'] do
end

task :default => 'all'

task :version do
  git_remotes = `git remote`.strip.split("\n")

  if git_remotes.count > 0
    puts "-- fetching version number from github"
    sh 'git fetch'

    remote_version = remote_podspec_version
  end

  if remote_version.nil?
    puts "There is no current released version. You're about to release a new Pod."
    version = "0.0.1"
  else
    puts "The current released version of your pod is " + remote_podspec_version.to_s()
    version = suggested_version_number
  end
  
  puts "Enter the version you want to release (" + version + ") "
  new_version_number = $stdin.gets.strip
  if new_version_number == ""
    new_version_number = version
  end

  replace_version_number(new_version_number)
end

desc "Release a new version of the Pod"
task :release do

  puts "* Running version"
  sh "rake version"

  unless ENV['SKIP_CHECKS']
    if `git symbolic-ref HEAD 2>/dev/null`.strip.split('/').last != 'master'
      $stderr.puts "[!] You need to be on the `master' branch in order to be able to do a release."
      exit 1
    end

    if `git tag`.strip.split("\n").include?(podspec_version)
      $stderr.puts "[!] A tag for version `#{podspec_version}' already exists. Change the version in the podspec"
      exit 1
    end

    puts "You are about to release `#{podspec_version}`, is that correct? [y/n]"
    exit if $stdin.gets.strip.downcase != 'y'
  end

  puts "* Linting the podspec"
  sh "pod lib lint"

  # Then release
  sh "git commit #{podspec_path} CHANGELOG.md -m 'Release #{podspec_version}'"
  sh "git tag -a #{podspec_version} -m 'Release #{podspec_version}'"
  sh "git push origin master"
  sh "git push origin --tags"
  sh "pod push master #{podspec_path}"
end

# @return [String] TMLKit version
#
def tml_version
  result = `plutil -p TMLKit/TMLKit/Info.plist | grep "CFBundleShortVersionString" | sed -E "s/[^0-9\.]+//g"`
  result
end

# @return [Pod::Version] The version as reported by the Podspec.
#
def podspec_version
  require 'cocoapods'
  spec = Pod::Specification.from_file(podspec_path)
  spec.version
end

# @return [Pod::Version] The version as reported by the Podspec from remote.
#
def remote_podspec_version
  require 'cocoapods-core'

  if spec_file_exist_on_remote?
    remote_spec = eval(`git show origin/master:#{podspec_path}`)
    remote_spec.version
  else
    nil
  end
end

# @return [Bool] If the remote repository has a copy of the podpesc file or not.
#
def spec_file_exist_on_remote?
  test_condition = `if git rev-parse --verify --quiet origin/master:#{podspec_path} >/dev/null;
  then
  echo 'true'
  else
  echo 'false'
  fi`

  'true' == test_condition.strip
end

# @return [String] The relative path of the Podspec.
#
def podspec_path
  podspecs = Dir.glob('TMLKit.podspec')
  if podspecs.count == 1
    podspecs.first
  else
    raise "Could not select a podspec"
  end
end
