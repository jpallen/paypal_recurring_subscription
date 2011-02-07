require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

namespace :spec do
  desc "Run unit specs"
  Spec::Rake::SpecTask.new('unit') do |t|
    t.spec_files = FileList['spec/unit/*_spec.rb']
  end
end

desc "Run all specs"
task :spec => ['spec:unit']

