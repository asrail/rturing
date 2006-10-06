task :default do
  Dir.glob('tests/*').each { |test|
    require test
  }
end

task :doc do
  require 'rdoc/rdoc'
  RDoc::RDoc.new.document([])
end

task :clean do
  Dir.rm_r('doc')
end
