# philiprehberger-pipe

[![Tests](https://github.com/philiprehberger/rb-pipe/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pipe/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pipe.svg)](https://rubygems.org/gems/philiprehberger-pipe)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-pipe)](https://github.com/philiprehberger/rb-pipe/commits/main)

Functional pipeline composition with conditional steps and error handling for Ruby

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-pipe"
```

Or install directly:

```bash
gem install philiprehberger-pipe
```

## Usage

```ruby
require "philiprehberger/pipe"

result = Philiprehberger::Pipe.new(10)
  .step { |v| v + 5 }
  .step { |v| v * 2 }
  .value
# => 30
```

### Conditional Steps

```ruby
require "philiprehberger/pipe"

result = Philiprehberger::Pipe.new(user_input)
  .step(guard_if: ->(v) { v.is_a?(String) }) { |v| v.strip }
  .step(guard_unless: ->(v) { v.empty? }) { |v| v.downcase }
  .value
```

### Named Steps

```ruby
require "philiprehberger/pipe"

result = Philiprehberger::Pipe.new(raw_input)
  .step(:parse) { |v| JSON.parse(v) }
  .step(:validate) { |v| validate!(v) }
  .step(:transform) { |v| transform(v) }
  .on_error { |e| puts "Failed at step: #{e.step_name}" }
  .value
```

### Side Effects with Tee

```ruby
require "philiprehberger/pipe"

result = Philiprehberger::Pipe.new(data)
  .step { |v| transform(v) }
  .tee { |v| logger.info("Transformed: #{v}") }
  .step { |v| finalize(v) }
  .value
```

### Intermediate Value Capture

```ruby
require "philiprehberger/pipe"

captures = {}

result = Philiprehberger::Pipe.new(raw_data)
  .step(:parse) { |v| parse(v) }
  .tap_value(:after_parse) { |v| captures[:parsed] = v }
  .step(:validate) { |v| validate(v) }
  .tap_value(:after_validate) { |v| captures[:validated] = v }
  .value
```

### Pipeline Composition

```ruby
require "philiprehberger/pipe"

normalize = Philiprehberger::Pipe.new(input)
  .step { |v| v.strip }
  .step { |v| v.downcase }

validate_and_save = Philiprehberger::Pipe.new(nil)
  .step { |v| validate!(v) }
  .step { |v| save(v) }

result = (normalize >> validate_and_save).value
```

### Reusable Pipelines

Build a pipeline once and apply it to any input with `call`. Use `to_proc` for integration with `map`, `select`, and other Enumerable methods:

```ruby
require "philiprehberger/pipe"

normalize = Philiprehberger::Pipe.new
  .step { |v| v.strip }
  .step { |v| v.downcase }

normalize.call("  HELLO ")           # => "hello"
["  FOO ", " BAR "].map(&normalize)  # => ["foo", "bar"]
```

### Early Return (Halt)

Short-circuit a pipeline from any step with `Pipe.halt!(value)` — the pipeline returns `value` immediately and the remaining steps are skipped. Halts bypass `on_error` handlers because they aren't errors.

```ruby
require "philiprehberger/pipe"

result = Philiprehberger::Pipe.new(user_input)
  .step(:parse) { |v| JSON.parse(v) }
  .step(:short_circuit_if_cached) do |v|
    cached = Cache.get(v[:id])
    Philiprehberger::Pipe.halt!(cached) if cached
    v
  end
  .step(:expensive_work) { |v| heavy_compute(v) }
  .value
```

### Error Handling

```ruby
require "philiprehberger/pipe"

result = Philiprehberger::Pipe.new(raw_input)
  .step(:parse) { |v| parse(v) }
  .step(:validate) { |v| validate(v) }
  .on_error { |e| default_value }
  .value
```

### Inspecting Pipelines

```ruby
require 'philiprehberger/pipe'

pipeline = Philiprehberger::Pipe.new
                                .step { |x| x * 2 }
                                .step { |x| x + 1 }

pipeline.step_count # => 2
```

## API

| Method | Description |
|--------|-------------|
| `Pipe.new(initial_value)` | Create a new pipeline with a starting value |
| `Pipe.halt!(value)` | Short-circuit the running pipeline; the pipeline returns `value` and skips the remaining steps |
| `#step(name = nil, guard_if: nil, guard_unless: nil, &block)` | Add a transformation step with optional name and guards |
| `#tee(&block)` | Add a side-effect step (value passes through unchanged) |
| `#tap_value(name = nil, &block)` | Capture and inspect intermediate values without affecting flow |
| `#compose(other)` | Chain two pipelines together, returns a new Pipe |
| `#>>(other)` | Alias for compose |
| `#call(value)` | Execute the pipeline on a given value (reusable) |
| `#to_proc` | Convert to Proc for use with `&` operator |
| `#on_error(&block)` | Set an error handler for the pipeline |
| `#value` | Execute the pipeline using the initial value |
| `#step_count` | Returns the number of steps currently in the pipeline |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-pipe)

🐛 [Report issues](https://github.com/philiprehberger/rb-pipe/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-pipe/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
