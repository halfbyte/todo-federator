# for URI::regexp
require 'uri'
require 'feedparser/html2text-parser'

# This class provides various converters
class String
  # is this text HTML ? search for tags. used by String#text2html
  def html?
    return (self =~ /<p>/) || (self =~ /<\/p>/) || (self =~ /<br>/) || (self =~ /<br\s*(\/)?\s*>/) || (self =~ /<\/a>/) || (self =~ /<img.*>/)
  end

  # returns true if the text contains escaped HTML (with HTML entities). used by String#text2html
  def escaped_html?
    return (self =~ /&lt;img src=/) || (self =~ /&lt;a href=/) || (self =~ /&lt;br(\/| \/|)&gt;/) || (self =~ /&lt;p&gt;/)
  end

  def escape_html
    r = self.gsub('&', '&amp;')
    r = r.gsub('<', '&lt;')
    r = r.gsub('>', '&gt;')
    r
  end

MY_ENTITIES = {}
FeedParser::HTML2TextParser::entities.each do |k, v|
  MY_ENTITIES["&#{k};"] = [v].pack('U*')
end

  # un-escape HTML in the text. used by String#text2html
  def unescape_html
    r = self
    MY_ENTITIES.each do |k, v|
      r = r.gsub(k, v)
    end
    r
  end

  # convert text to HTML
  def text2html(feed)
    text = self.clone
    if text.html?
      # do nothing
    elsif text.escaped_html?
      text = text.unescape_html
    else
      # paragraphs
      text.gsub!(/\A\s*(.*)\Z/m, '<p>\1</p>')
      text.gsub!(/\s*\n(\s*\n)+\s*/, "</p>\n<p>")
      # uris
      text.gsub!(/(#{URI::regexp(['http','ftp','https'])})/,
          '<a href="\1">\1</a>')
    end
    # Handle broken hrefs in <a> and <img>
    if feed and feed.link
      text.gsub!(/(\s(src|href)=['"])([^'"]*)(['"])/) do |m|
        begin
          first, url, last = $1, $3, $4
          if (url =~ /^\s*\w+:\/\//) or (url =~ /^\s*\w+:\w/)
            m
          elsif url =~ /^\//
            (first + feed.link.split(/\//)[0..2].join('/') + url + last)
          else
            t = feed.link.split(/\//)
            if t.length == 3 # http://toto with no trailing /
              (first + feed.link + '/' + url + last)
            else
              if feed.link =~ /\/$/
                (first + feed.link + url + last)
              else
                (first + t[0...-1].join('/') + '/' + url + last)
              end
            end
          end
        rescue
          m
        end
      end
    end
    text
  end

  # Remove white space around the text
  def rmWhiteSpace!
    return self.gsub!(/\A\s*/m, '').gsub!(/\s*\Z/m,'')
  end

  # Convert a text in inputenc to a text in UTF8
  # must take care of wrong input locales
  def toUTF8(inputenc)
    if inputenc.downcase != 'utf-8'
      # it is said it is not UTF-8. Ensure it is REALLY not UTF-8
      begin
        if self.unpack('U*').pack('U*') == self
          return self
        end
      rescue
        # do nothing
      end
      begin
        return self.unpack('C*').pack('U*')
      rescue
        return self #failsafe solution. but a dirty one :-)
      end
    else
      return self
    end
  end
end
