# Item Checkout Feed Updater

This app listens on the Item kinesis stream to identify Item updates that *look like* checkouts. When it encounters an item checkout, it adds the checkout as an event to a list of checkouts maintained in-memory. The checkout item contains the following information:

 * title: Title of book (needs to be queried from Bib service based on bibId in item record
 * author: Author(s) of book (also needs to be derived from Bib service based on bibId)
 * time: Time of checkout as an ISO date
 * id: Item identifier (unique to item)
 * barcode: Item barcode (unique to item)
 * isbn: Item ISBN (for use looking up cover art?)

 That list of items is periodically uploaded as an atom feed to S3 for consumption by any client interested in showing a feed of checkouts.

## Setup
### Installation

```
bundle install; bundle install --deployment
```

### Setup

All config is in sam.[ENVIRONMENT].yml templates, encrypted as necessary.

## Contributing

### Git Workflow

 * Cut branches from development.
 * Create PR against development.
 * After review, PR author merges.
 * Merge development > qa
 * Merge qa > master
 * Tag version bump in master

### Running events locally

The following will invoke the lambda against the sample event jsons:

```
sam local invoke --event event.json --region us-east-1 --template sam.local.yml --profile nypl-digital-dev
```

### Gemfile Changes

Given that gems are installed with the `--deployment` flag, Bundler will complain if you make changes to the Gemfile. To make changes to the Gemfile, exit deployment mode:

```
bundle install --no-deployment
```

## Testing

```
bundle exec rspec
```

## Deploy

Deployments are entirely handled by Travis-ci.com. To deploy to development, qa, or production, commit code to the `development`, `qa`, and `master` branches on origin, respectively.


