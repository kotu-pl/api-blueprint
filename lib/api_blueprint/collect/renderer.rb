class ApiBlueprint::Collect::Renderer
  attr_reader :action, :resource

  def parameter_table(params, level = 0, nested_name = '')
    text = ''

    if level == 0
      text += "#### Parameters:\n\n"
      text += "Name | Type | Description\n"
      text += "-----|------|---------|------------\n"
    end

    params.each do |name, info|
      comment = info[:type] == 'array' ? "Params for each #{name.singularize}:" : ''

      md_name = level > 0 ? "#{nested_name}_#{name}" : name
      create_parameter_md(md_name, "*#{info[:type]}*#{info[:example].present? ? " `Example: #{info[:example]}`" : ''}", comment)
      text += "#{'[]' * level} #{name} | <require:param/#{resource}/#{action}/#{md_name}_type> | <require:param/#{resource}/#{action}/#{md_name}_comment>\n"

      if info[:type] == 'nested' || info[:type] == 'array'
        text += parameter_table(info[:params], level + 1, name)
      end
    end
    text += "\n" if level == 0
    text
  end

  def resource_header(content)
    create_resource_md
    "# Resource: #{content}\n\n<require:desc/#{resource}>\n\n"
  end

  def action_header
    "## Action: #{action}\n\n"
  end

  def description_header
    create_action_md
    "### Description:\n\n<require:desc/#{resource}_#{action}>\n\n"
  end

  def signature(url, method)
    "#### Signature:\n\n**#{method}** `#{url}`\n\n"
  end

  def examples_header
    "### Examples:\n\n"
  end

  def example_header(content)
    "#### Example: #{content}\n\n"
  end

  def example_subheader(content)
    content = content.to_s.humanize + ':' if content.is_a?(Symbol)

    "##### #{content}\n\n"
  end

  def code_block(content)
    content.split("\n").collect { |line| " " * 4 + line }.join("\n") + "\n\n"
  end

  def action=(value)
    @action = safe_name(value)
  end

  def resource=(value)
    @resource = safe_name(value)
  end

  private

  def chapters_path
    @chapters_path ||= ApiBlueprint.blueprintfile(write_blueprint: false, force_load: true)['blueprint'].gsub(/\/?[^\/]+$/, '') + '/chapters'
  end

  def create_resource_md
    unless File.exists?(filepath = "#{chapters_path}/desc/#{resource}.md")
      FileUtils.mkdir_p("#{chapters_path}/desc") unless File.exists?("#{chapters_path}/desc")
      File.open(filepath, 'w') { |file| file.write("#{resource.singularize.capitalize} object preview:\n\n") }
    end
  end

  def create_action_md
    unless File.exists?(filepath = "#{chapters_path}/desc/#{resource}_#{action}.md")
      FileUtils.mkdir_p("#{chapters_path}/desc") unless File.exists?("#{chapters_path}/desc")
      File.open(filepath, 'w') { |file| file.write("Method #{action} related to #{resource.singularize.capitalize} resource") }
    end
  end

  def create_parameter_md(name, type, comment)
    unless File.directory?(dirpath = "#{chapters_path}/param/#{resource}/#{action}")
      FileUtils.mkdir_p(dirpath)
    end

    unless File.exists?(filepath = "#{dirpath}/#{name}_type.md")
      File.open(filepath, 'w') { |file| file.write(type) }
    end

    unless File.exists?(filepath = "#{dirpath}/#{name}_comment.md")
      File.open(filepath, 'w') { |file| file.write(comment) }
    end
  end

  def safe_name(value)
    ActiveSupport::Inflector.parameterize(value, '_').downcase
  end
end
