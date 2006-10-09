require 'rake/packagetask'

PACKAGE = 'rturing'
RTURING_VERSION = '0.0.1'

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
  p.need_tar = true
  p.package_files.include('turing/*.rb')
  p.package_files.include('rturing')
  p.package_files.include('machines/*')
end

task :clean do
  Dir.rm_rf('doc')
  Dir.rm_rf('pkg')
end

task :tagrelease do
  system("svn copy https://intranet.dcc.ufba.br/svn/rturing/trunk https://intranet.dcc.ufba.br/svn/rturing/tags/#{RTURING_VERSION}")
end
