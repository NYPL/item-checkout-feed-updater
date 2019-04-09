require 'atom'

class S3Writer
  def s3_client
    @s3_client = S3Client.new if @s3_client.nil?
    @s3_client
  end

  def feed_xml(checkouts)
    feed = Atom::Feed.new

    checkouts.each do |checkout|
      e = Atom::Entry.new
      e.title = checkout.title
      e.author = checkout.author

      feed.entries << e
    end






      

    Application.logger.debug "Entry #{feed}"

     # Application.logger.debug "Check out entry: #{entry}"

    feed.to_s
  end

  def write(checkouts)
    xml = feed_xml checkouts
    Application.logger.debug "Generated atom feed: #{xml}"
  end
end
