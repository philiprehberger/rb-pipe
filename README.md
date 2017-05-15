# philiprehberger-pipe

[![Tests](https://github.com/philiprehberger/rb-pipe/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pipe/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pipe.svg)](https://rubygems.org/gems/philiprehberger-pipe)
[![License](https://img.shields.io/github/license/philiprehberger/rb-pipe)](LICENSE)

Functional pipeline composition with conditional steps and error handling for Ruby.

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem 'philiprehberger-pipe'
```

Or install directly:

```bash
gem install philiprehberger-pipe
```

## Usage

```ruby
require 'philiprehberger/pipe'

result = Philiprehberger::Pipe.new(10)
  .step { |v| v + 5 }
  .step { |v| v * 2 }
  .value
# => 30
```

### Conditional Steps

```ruby
Philiprehberger::Pipe.new(user_input)
  .step(if: ->(v) { v.is_a?(String) }) { |v| v.strip }
  .step(unless: ->(v) { v.empty? }) { |v| v.downcase }
  .value
```

### Side Effects with Tee

```ruby
Philiprehberger::Pipe.new(data)
  .step { |v| transform(v) }
  .tee { |v| logger.info("Transformed: #{v}") }
  .step { |v| finalize(v) }
  .value
```

### Error Handling

```ruby
Philiprehberger::Pipe.new(raw_input)
  .step { |v| parse(v) }
  .step { |v| validate(v) }
  .on_error { |e| default_value }
  .value
```

## API

| Method | Description |
|---|---|
| `Pipe.new(initial_value)` | Create a new pipeline with a starting value |
| `#step(if: nil, unless: nil, &block)` | Add a transformation step with optional guards |
| `#tee(&block)` | Add a side-effect step (value passes through unchanged) |
| `#on_error(&block)` | Set an error handler for the pipeline |
| `#value` | Execute the pipeline and return the final result |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
