require "bundler/gem_tasks"

require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/*_test.rb"]
  t.ruby_opts = ["-w"]
  t.verbose = true
end
task default: :test

# task :mutant, [:class] do |task, args|
#   klass = args[:class] || 'Surrounded'
#   sh "bundle exec mutant --include lib --require surrounded --use minitest #{klass}"
# end
