# Repository Guidelines

## Project Overview

This repository is example Ruby code for using the BandTools REST API. Keep it readable and practical for developers who want to adapt the code for their own integrations.

## Development Commands

- Install development dependencies with `bundle install`.
- Run tests with `bundle exec rake test`.
- Run linting with `bundle exec rubocop`.

## Code Style

- Support Ruby 3.4 and newer.
- Prefer explicit, dependency-light code using Ruby standard library APIs where practical.
- Keep resource methods small and named after BandTools API resources using Ruby idioms.
- Centralise HTTP behaviour, authentication, response parsing, multipart encoding, and error handling in `lib/bandtools/transport.rb`.
- Put endpoint-specific methods in the appropriate file under `lib/bandtools/resources/`.
- Do not add generated OpenAPI client output to this example repository.

## Testing

- Add focused unit tests for every new public client behaviour.
- Mock network access; unit tests must not call the live BandTools API.
- Cover error handling for non-2xx API responses and connection failures when changing request behaviour.

## Documentation

- Use UK spelling in prose, comments, test names, and documentation where practical.
- Keep `README.md` aligned with the public API exposed by `BandTools::Client`.
- Make it clear that this repository is example code, not an official SDK.
