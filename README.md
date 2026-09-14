# BandTools API Ruby Example

[![CI](https://github.com/bandtools-app/bandtools-api-ruby-example/actions/workflows/ci.yml/badge.svg)](https://github.com/bandtools-app/bandtools-api-ruby-example/actions/workflows/ci.yml)

This repository contains example Ruby code for authenticating with and using the BandTools REST API.
It is intended as a practical starting point for developers who want to build their own integrations with BandTools.
This is example code rather than an official SDK. The [BandTools API reference](https://bandtools.app/help/api) remains the source of truth for supported endpoints, request formats, and response formats.

## Installation

Use Ruby 3.4 or newer.

```bash
bundle install
```

The client itself uses only the Ruby standard library. The development dependencies install `minitest`, `rake`, `rubocop`, and `rubocop-minitest`.

## Usage

Create a client with a BandTools API token. In a real integration, load the token from your environment or secret manager rather than hard-coding it.
The API endpoint can also be passed in; this example uses `BANDTOOLS_API_URL` when present and falls back to the production API URL.

```ruby
require "bandtools"

client = BandTools::Client.new(
  api_token: ENV.fetch("BANDTOOLS_API_TOKEN"),
  base_url: ENV.fetch("BANDTOOLS_API_URL", BandTools::Client::DEFAULT_BASE_URL)
)
```

The client is organised by resource area:

```ruby
client.subscribers
client.account
client.newsletters
client.automatic_newsletters
client.webhooks
```

### Subscribers

List, create, fetch, delete, and import subscribers.

```ruby
subscribers = client.subscribers.list(
  per_page: 25,
  sort: "subscribed_recent",
  filter: "confirmed"
)
puts subscribers

subscriber = client.subscribers.add("fan@example.com")
subscriber_id = subscriber.dig("data", "id")

same_subscriber = client.subscribers.get(subscriber_id)
puts same_subscriber

client.subscribers.delete(subscriber_id)
```

Bulk imports can be sent as JSON or uploaded from a CSV file:

```ruby
import_job = client.subscribers.import_emails(
  [
    "first@example.com",
    "second@example.com"
  ]
)

csv_import_job = client.subscribers.import_csv("subscribers.csv")

status = client.subscribers.import(import_job.dig("data", "id"))
puts status
```

### Account Settings

Read and update account, app, newsletter, theme, page design, and confirmation email settings.

```ruby
account = client.account.get
puts account
puts account.dig("data", "features", "subscriber_limit")

client.account.update(
  {
    account: {
      name: "Example Band",
      website_url: "https://example.com",
      social_links: {
        bandcamp: "https://exampleband.bandcamp.com",
        instagram: "https://instagram.com/exampleband",
        spotify: "https://open.spotify.com/artist/example"
      }
    }
  }
)

client.account.update_social_links(
  bandcamp: "https://exampleband.bandcamp.com",
  instagram: "https://instagram.com/exampleband",
  youtube: nil
)

client.account.update_newsletter_settings(
  {
    newsletter_settings: {
      newsletter_name: "Example Band Updates",
      newsletter_description: "News, tour dates, and releases.",
      display_social_links_in_footer: true
    }
  }
)

theme = client.account.create_theme(
  {
    theme: {
      name: "High contrast",
      body_background_colour: "#ffffff",
      body_text_colour: "#111111",
      link_colour: "#005fcc"
    }
  }
)

client.account.update_page_design(
  :subscribe,
  {
    subscribe_page: {
      page_theme_id: theme.dig("data", "id"),
      content: "<p>Join the mailing list.</p>"
    }
  }
)
```

### Newsletters

Request bodies are hashes that mirror the BandTools API reference.

```ruby
draft = client.newsletters.create(
  {
    subject: "Spring tour dates",
    message: "<p>Tickets are on sale now.</p>"
  }
)

client.newsletters.send_preview(draft.dig("data", "id"), "you@example.com")
```

Newsletter drafts can be updated, duplicated, scheduled, sent, archived, pinned, and deleted.

```ruby
newsletter_id = draft.dig("data", "id")

client.newsletters.update(
  newsletter_id,
  {
    subject: "Spring tour dates announced",
    message: "<p>New shows have been added.</p>"
  }
)

copy = client.newsletters.duplicate(newsletter_id)
copy_id = copy.dig("data", "id")

client.newsletters.schedule(newsletter_id, "2026-06-01T10:00:00Z")
client.newsletters.cancel_schedule(newsletter_id)

client.newsletters.send(newsletter_id)

client.newsletters.add_to_archive(newsletter_id)
client.newsletters.pin(newsletter_id)
client.newsletters.unpin(newsletter_id)
client.newsletters.remove_from_archive(newsletter_id)

client.newsletters.delete(copy_id)
```

When updating a shared draft as a collaborator, first load the newsletter and
include its current `lock_version`. Owners may omit this field.

```ruby
latest = client.newsletters.get(newsletter_id)
client.newsletters.update(
  newsletter_id,
  {
    message: "<p>Updated by a collaborator.</p>",
    lock_version: latest.dig("data", "lock_version")
  }
)
```

A previously sent newsletter can also be sent only to subscribers who joined after the original send.

```ruby
result = client.newsletters.send_to_new_subscribers(newsletter_id)
puts result.dig("data", "new_subscribers_count")
```

Collaborator and lock helpers are available for shared editing workflows:

```ruby
client.newsletters.invite_collaborator(newsletter_id, "collaborator@example.com")
collaborators = client.newsletters.collaborators(newsletter_id)

lock = client.newsletters.acquire_lock(newsletter_id)
client.newsletters.refresh_lock(newsletter_id)
client.newsletters.release_lock(newsletter_id)
```

### Uploads

Uploads accept filesystem paths.

Newsletter attachments can be PDF, JPEG, PNG, GIF, WebP, MP3, MP4, or MPEG
video files up to 20 MiB. The content type is inferred from the filename; pass
`content_type:` when the filename does not identify it or when uploading MP4
audio.

```ruby
attachment = client.newsletters.upload_attachment("poster.jpg")
audio = client.newsletters.upload_attachment("track.bin", content_type: "audio/mp4")
puts attachment

client.account.upload_picture("profile.png")
client.account.upload_page_background_image(:subscribe, "background.jpg")
```

### Automatic Newsletters

Automatic newsletters can be created from feed URLs, paused, resumed, and validated.

```ruby
validation = client.automatic_newsletters.validate_feed("https://example.com/feed.xml")
puts validation

automatic = client.automatic_newsletters.create(
  {
    automatic_newsletter: {
      name: "Blog updates",
      feed_url: "https://example.com/feed.xml",
      behaviour: "draft",
      frequency: "daily"
    }
  }
)

automatic_id = automatic.dig("data", "id")
client.automatic_newsletters.pause(automatic_id)
client.automatic_newsletters.resume(automatic_id)
```

### Webhooks

Use webhooks to receive BandTools events in your own application.

```ruby
webhook = client.webhooks.create(
  {
    webhook: {
      name: "Production sync",
      url: "https://example.com/bandtools/webhooks",
      event_types: ["subscriber.created", "newsletter.sent"]
    }
  }
)

webhook_id = webhook.dig("data", "id")
client.webhooks.rotate_signing_secret(webhook_id)
client.webhooks.update(webhook_id, { webhook: { enabled: true } })
client.webhooks.delete(webhook_id)
```

### Error Handling

API errors and connection failures are exposed as BandTools-specific exceptions.

```ruby
begin
  client.subscribers.add("not-an-email")
rescue BandTools::APIError => e
  warn "#{e.status_code}: #{e.message}"
  warn e.response.inspect
rescue BandTools::ConnectionError => e
  warn "Could not reach BandTools: #{e.message}"
end
```

## Development

```bash
bundle exec rake test
bundle exec rubocop
```

The tests use a fake HTTP transport and do not call the live BandTools API.
GitHub Actions runs RuboCop and the unit tests on Ruby 3.4.

## Copyright

Copyright (c) 2026 BandTools Ltd.

This project is licensed under the MIT licence. See [LICENSE](LICENSE).
