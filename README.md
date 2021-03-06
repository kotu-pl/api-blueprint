# api-blueprint

Semi-automatic solution for creating Rails app's API documentation. Here's how it works:

1. You start with method list generated from RSpec request specs. For each method, you get a list of parameters and examples.
2. Then, you can extend it in whatever way you need using Markdown syntax. You can organize documentation files into partials.
3. Upon any API change, like serializer change that changes responses, you can update automatically generated parts of docs.
4. Once done, you can compile your documentation into single, nicely styled HTML file. You can also auto-deploy it via SSH.

## Installation

Add to `Gemfile`:

```ruby
gem 'api_blueprint', group: [:development, :test]
```

Then run:

    bundle install

Add the following inside `RSpec.configure` block in `spec/spec_helper.rb`:

```ruby
config.include ApiBlueprint::Collect::SpecHook
```

## Usage

**api-blueprint** consists of two modules:

1. **Collect** module: allows to run RSpec request suite in order to auto-generate API method information.
2. **Compile** module: allows to turn whole Markdown documentation into single, ready-to-publish HTML file.

### Collect

In order to auto-generate API method information you should invoke:

    rake blueprint:collect

> By default, all specs inside `spec/requests/api` are run. You can configure that by creating a [Blueprintfile](#configuration) configuration.

This will generate the `doc/api.md` file with a Markdown documentation. If this file already exists, **api-blueprint** will not override it. It will write to `tmp/merge.md` instead so you can merge both existing and generated documentation manually in whatever way you want.

Some reusable pieces of documentation will be placed in `doc/chapters/desc` and `doc/chapters/param` directories in addition. *desc* directory is a place for resource structure preview and methods' descriptions.

Params directory keeps each method's parameters' types and descriptions, you can adjust them by giving better example and comments.

Placeholders from `doc/api.md` markup will be replaced with the ones from *desc*/*param* directories, but you need to divide `api.md` into "chapters" manually and put them into `chapters` directory.

Final `api.md` file (with resources extracted and moved to chapters) should look similar to:

    Title: Example.com API

    Host: http://example.com

    Copyright: Some company name

    <require:chapters/introduction>
    <require:chapters/changelog>
    <require:chapters/resource1>
    <require:chapters/resource2>
    <require:chapters/resource3>
    <require:chapters/resource4>
    <require:chapters/resource5>
    <require:chapters/errors>

#### Regenerate examples

You get the RSpec-based example listing for every auto-generated API method documentation. There's a chance that

### Compile

In order to turn your documentation into ready-to-publish HTML file you should invoke:

    rake blueprint:compile

This will create the final `doc/api.html`. You can deploy this file to configured SSH target with:

    rake blueprint:deploy

If you want to preview this file constantly when editing Markdown docs, you can do so with:

    rake blueprint:watch

> You should add `doc/**/*.html` to your `.gitignore` as there's no need to clutter your project history with compiled HTML that you can easily recreate on demand.

#### Require another file

You can split your documentation into separate files and directories in order to organize it better and reuse same fragments in multiple places. You can do that with the following Markdown:

```md
<require:fragments/deprecation_warning.md>
```

## Configuration

Configuration for **api-blueprint** lives in `Blueprintfile` inside application directory. It's basically a listing of documentations governed by **api-blueprint**, each with a set of options. It looks like this:

```yaml
api:
  spec: "spec/requests/api/v2"
  blueprint: "doc/api.md"
  html: "doc/api.html"
  deploy: "user@server.com:/home/app/public/api.html"
  deploy_port: "2022"
  bypass_params: ['on', 'format']
  naming:
    sessions:
      create: "Sign In"
```

Here's what specific per-documentation options stand for:

Option | Description
-------|------------
`spec` | RSpec spec suite directory
`blueprint` | Main documentation file (Markdown)
`html` | Target HTML file created after compilation
`deploy` | SSH address used for documentation deployment
`naming` | Dictionary of custom API method names

First group is always a default one. You can switch any rake task to work on other group by specifying its name with `rake blueprint:collect group=other`.