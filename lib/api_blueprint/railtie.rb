module ApiBlueprint
  class Railtie < Rails::Railtie
    railtie_name :api_blueprint

    initializer "api_blueprint.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        include ApiBlueprint::Collect::ControllerHook
      end
    end

    rake_tasks do
      load 'tasks/blueprint.rake'
    end
  end

  def self.blueprintfile(opts = {})
    @hash = (opts[:force_load] ? load_yaml : @hash) || load_yaml

    if opts[:write_blueprint] != false && @hash['blueprint'].present? && File.exists?(@hash['blueprint'])
      @hash.delete('blueprint')
    end

    ['spec', 'blueprint', 'html'].each do |param|
      @hash[param] = ENV[param] if ENV[param].present?
    end

    @hash
  end

  def self.load_yaml
    file = Rails.root.join("Blueprintfile")

    if File.exists?(file)
      file = YAML.load_file(file)

      if ENV['group']
        file[ENV['group']] || {}
      else
        file.any? ? file.first[1] : {}
      end
    else
      {}
    end
  end
end
