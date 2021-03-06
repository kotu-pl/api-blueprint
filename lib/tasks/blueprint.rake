def compile(source, target)
  compiler = ApiBlueprint::Compile::Compile.new(:source => source, :target => target, :logger => :stdout)
  compiler.compile

  compiler
end

def regenerate_dumps
  Rake::Task["blueprint:collect:clear"].execute
  puts
  Rake::Task["blueprint:collect:generate"].execute
  puts
end

namespace :blueprint do
  desc 'Clear, generate and merge dumps for specified request spec(s)'
  task :collect => :environment do
    regenerate_dumps

    Rake::Task["blueprint:collect:merge"].execute
  end

  namespace :collect do
    desc 'Remove all generated request dumps'
    task :clear => :environment do
      files = ApiBlueprint::Collect::Storage.request_dumps

      puts "Clearing #{files.count} request dumps..."

      File.unlink(*files)
    end

    desc 'Generate request dumps for specified request spec(s)'
    task :generate => :environment do
      args = ApiBlueprint.blueprintfile['spec'] || "spec/requests/#{ENV['group'] || 'api'}"
      opts = { :order => 'default', :format => 'documentation' }
      cmd  = "API_BLUEPRINT_DUMP=1 bundle exec rspec #{opts.map{|k,v| "--#{k} #{v}"}.join(' ')} #{args}"

      puts "Invoking '#{cmd}'..."

      system(cmd)
    end

    desc 'Merge all existing request dumps into single blueprint'
    task :merge => :environment do
      target = ApiBlueprint.blueprintfile['blueprint'] || Rails.root.join('tmp', 'merge.md')

      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout, :naming => ApiBlueprint.blueprintfile['naming']).merge
    end
  end

  namespace :examples do
    desc 'Clear existing examples in blueprint'
    task :clear => :environment do
      target = ApiBlueprint.blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')

      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout).clear_examples
    end

    desc 'Uuse dumps to update examples in blueprint'
    task :update => :environment do
      target = ApiBlueprint.blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')

      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout).update_examples
    end

    desc 'Use dumps to replace examples in blueprint'
    task :replace => :environment do
      target = ApiBlueprint.blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')

      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout).clear_examples
      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout).update_examples
    end
  end

  desc 'Compile the blueprint into complete HTML documentation'
  task :compile => :environment do
    source = ApiBlueprint.blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')
    target = ApiBlueprint.blueprintfile(:write_blueprint => false)['html'] || source.to_s.sub(/\.md$/, '.html')

    compile(source, target)
  end

  desc 'Watch for changes in the blueprint and compile it into HTML on every change'
  task :watch => :environment do
    source = ApiBlueprint.blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')
    target = ApiBlueprint.blueprintfile(:write_blueprint => false)['html'] || source.to_s.sub(/\.md$/, '.html')

    files = compile(source, target).partials

    FileWatcher.new(files).watch do |filename|
      puts "\n--- #{Time.now} [#{filename.split('/').last}] ---\n\n"
      compile(source, target)
    end
  end

  desc 'Deploy the HTML documentation on remote target'
  task :deploy => :environment do
    Rake::Task["blueprint:compile"].execute

    source = ApiBlueprint.blueprintfile(:write_blueprint => false)['html']
    target = ApiBlueprint.blueprintfile(:write_blueprint => false)['deploy']
    deploy_port = ApiBlueprint.blueprintfile(:write_blueprint => false)['deploy_port']

    if source.present? && target.present?
      cmd = "scp #{target_port ? "-P #{deploy_port}": ''} -q #{source} #{target}"

      puts "\nDeploying to '#{target}'..."

      system(cmd)
    end
  end
end


