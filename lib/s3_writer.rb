require 'atom/feed'

class S3Writer
  def s3_client
    @s3_client = S3Client.new if @s3_client.nil?
    @s3_client
  end

  def feed_xml(checkouts)
    feed = Atom::Feed.new
    checkouts.each do |checkout|
      entry = Atom::Entry.new
      entry.title = checkout.title

      # TODO Add other properties

      feed << entry
    end

    feed.to_s
  end

  def write(checkouts)
    xml = feed_xml checkouts
    Application.logger.debug "Generated atom feed: #{xml}"
    # 
  end
end
