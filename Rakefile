require 'rake/packagetask'
require 'rake/loaders/makefile'

PACKAGE = 'rturing'
RTURING_VERSION="0.1.2"

task :default do
  Dir.glob('tests/*').each { |test|
    require test
  }
end

task :doc do
  require 'rdoc/rdoc'
  RDoc::RDoc.new.document(
    [ '--charset', 'utf-8' ] +
    [ '--inline-source', '--line-numbers' ] +
    Dir.glob('**/README') +
    Dir.glob('**/*.rb')
  )
end

Rake::PackageTask.new(PACKAGE, RTURING_VERSION) do |p|
  p.need_tar_gz = true
  p.package_files.include('turing/*')
  p.package_files.include('rturing')
  p.package_files.include('grturing')
  p.package_files.include('machines/*')
  p.package_files.include('Rakefile')
  p.package_files.include('README')
  p.package_files.include('tests/*')
  p.package_files.include('interface/*')
end

task :clean => [ :clobber_package ] do
  Dir.rm_rf('doc')
  Dir.rm_rf('pkg')
end


task :tag do
    system("svn copy https://intranet.dcc.ufba.br/svn/rturing/trunk https://intranet.dcc.ufba.br/svn/rturing/tags/#{RTURING_VERSION}")
end

