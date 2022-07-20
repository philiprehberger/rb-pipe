# philiprehberger-pipe

[![Tests](https://github.com/philiprehberger/rb-pipe/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pipe/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pipe.svg)](https://rubygems.org/gems/philiprehberger-pipe)
[![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-pipe)](https://github.com/philiprehberger/rb-pipe/releases)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-pipe)](https://github.com/philiprehberger/rb-pipe/commits/main)
[![License](https://img.shields.io/github/license/philiprehberger/rb-pipe)](LICENSE)
[![Bug Reports](https://img.shields.io/github/issues/philiprehberger/rb-pipe/bug)](https://github.com/philiprehberger/rb-pipe/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Feature Requests](https://img.shields.io/github/issues/philiprehberger/rb-pipe/enhancement)](https://github.com/philiprehberger/rb-pipe/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

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

### Error Handling

```ruby
require "philiprehberger/pipe"

result = Philiprehberger::Pipe.new(raw_input)
  .step(:parse) { |v| parse(v) }
  .step(:validate) { |v| validate(v) }
  .on_error { |e| default_value }
  .value
```

## API

| Method | Description |
|--------|-------------|
| `Pipe.new(initial_value)` | Create a new pipeline with a starting value |
| `#step(name = nil, guard_if: nil, guard_unless: nil, &block)` | Add a transformation step with optional name and guards |
| `#tee(&block)` | Add a side-effect step (value passes through unchanged) |
| `#tap_value(name = nil, &block)` | Capture and inspect intermediate values without affecting flow |
| `#compose(other)` | Chain two pipelines together, returns a new Pipe |
| `#>>(other)` | Alias for compose |
| `#on_error(&block)` | Set an error handler for the pipeline |
| `#value` | Execute the pipeline and return the final result |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this package useful, consider giving it a star on GitHub — it helps motivate continued maintenance and development.

[![LinkedIn](https://img.shields.io/badge/Philip%20Rehberger-LinkedIn-0A66C2?logo=linkedin)](https://www.linkedin.com/in/philiprehberger)
[![More packages](https://img.shields.io/badge/more-open%20source%20packages-blue)](https://philiprehberger.com/open-source-packages)

## License

[MIT](LICENSE)
