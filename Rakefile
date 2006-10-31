require 'rake/packagetask'

PACKAGE = 'rturing'

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
  p.need_tar_bz2 = true
  p.package_files.include('turing/*')
  p.package_files.include('rturing')
  p.package_files.include('machines/*')
  p.package_files.include('Rakefile')
  p.package_files.include('README')
  p.package_files.include('tests/*')
end

task :clean => [ :clobber_package ] do
  Dir.rm_rf('doc')
end


task :tag do
  begin
    system("svn copy https://intranet.dcc.ufba.br/svn/rturing/trunk https://intranet.dcc.ufba.br/svn/rturing/tags/${version}")
  rescue
    puts "Favor especificar version=VERSAO_DESEJADA na linha de comando."
  end
end
