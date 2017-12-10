# SE Realtime

SE Realtime is a ruby API for the [Stack Exchange real time questions feed](https://stackexchange.com/questions?realtime). It allows various methods of retrieving questions from that page.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'se-realtime'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install se-realtime

## Usage

First of all, require it with `require 'se/realtime'`.

Then, pick a retrevial method:

### Retrieveal methods

#### Raw

To simply get exactly what the websocket is spitting out, use the raw retrevial method:

```ruby

SE::Realtime.ws do |data|
  puts data
end
```

This will print out exactly what comes out of the websocket (`JSON.parse`d).

> **Warning:**
>
> The only relevant part here is the data field of the json, which has a string value (because reasons), and so you must `JSON.parse(data['data'])` to get the real data.

#### JSON

To get a neatly formatted version of the post with nicer keys, use this method. The keys are all symbols:

- site: The simple name of the site
- body: A truncated version of the body of the post (with "..." appended)
- title: The title of the post
- last_active: The timestamp from SE of the last activity.
- site_url: The base url of the site that the post came from
- url: The url of the post
- owner_url: The url of the profile of the owner
- owner_display_name: The display name of the owner
- id: The ID of the post

Syntax:

```ruby
SE::Realtime.json do |data|
  puts data
end
```

This also accepts a `site: 'sitename'` parameter to filter by site.

#### Batched

This is identical to the JSON method, except it takes a batch size and returns an array of Hashes of the size passed. It passes all hash parameters on to json, so you can use filters such as `site: 'sitename'`.

Syntax:

```ruby
SE::Realtime.batch 10, site: 'stackoverflow' do |data|
  puts data
end
```

This will return arrays of 10 stackoverflow posts every time 10 have been retrieved.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/izwick-schachter/se-realtime.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
