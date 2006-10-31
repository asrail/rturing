


def url_e_rev
  url = nil
  rev = nil
  IO.popen("svn info --non-interactive") { |file|
    file.each_line { |line|
      if !url then
        line =~ /^URL: (.*)$/
        if $~ then
          url = $~[1]
        end
      end
      if !rev then
        line =~ /^Rev(.*)\: (.*)$/
        if $~ then
          rev = $~[2]
        end
      end
      
    } 
  }
  return [url, rev.to_i]
end

def url_e_rev_originais(path=".")
  url = File.open("#{path}/url_original") { |file|
    file.read }
  rev = File.open("#{path}/revision_original") { |file|
    file.read}
  return [url, rev.to_i]
end


def repo_root(url)
  url =~ /^(.*)trunk/
  return $~[1]
end


def create_branch(bname)
  url, rev = url_e_rev
  root = repo_root(url)
  puts url, rev, root
  tmpdir = "a_very_unlikely_name"
  branch_dir = root + "branches/"
  cmd1 = "svn co -N #{branch_dir} #{tmpdir}"
  puts cmd1
  system(cmd1)
  cmd1 = "svn cp #{url} #{tmpdir}/#{bname}"
  puts cmd1
  system(cmd1)
  system("touch #{tmpdir}/#{bname}/url_original")
  File.open("#{tmpdir}/#{bname}/url_original", "w") { |file|
    file.write(url)
  }
  system("touch #{tmpdir}/#{bname}/revision_original")
  File.open("#{tmpdir}/#{bname}/revision_original", "w") {|file|
    file.write(rev)
  }
  system("svn add #{tmpdir}/#{bname}/url_original #{tmpdir}/#{bname}/revision_original")
  system("svn ci #{tmpdir}/#{bname} -m \"criando branch #{bname} a de #{url} na rev #{rev}\"")
  system("rm -rf #{tmpdir}")
end


def pull_from_trunk
  url, rev = url_e_rev
  url_o, rev_o = url_e_rev_originais
  cmd = "svn merge #{url_o}@#{rev_o} #{url_o}@HEAD ."
  puts cmd
  system(cmd)
  File.open("revision_original", "w") {|file|
    file.write(rev)
  }
  puts "Favor corrigir algum conflito e dar o commit."
end


def pull_from_branch
  url, rev = url_e_rev
  
  
end
