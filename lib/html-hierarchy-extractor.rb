require 'nokogiri'
require 'digest/md5'

# Extract content from an HTML page in the form of items with associated
# hierarchy data
class HTMLHierarchyExtractor
  def initialize(input, options: {})
    @dom = Nokogiri::HTML(input)
    default_options = {
      css_selector: 'p'
    }
    @options = default_options.merge(options)

    warn '[DEPRECATION] The gem html-hierarchy-extractor has been renamed '\
         'to algolia_html_extractor and will no longer be supported. '\
         'Please switch to algolia_html_extractor as soon as possible.'
  end

  # Returns the outer HTML of a given node
  #
  # eg.
  # <p>foo</p> => <p>foo</p>
  def extract_html(node)
    node.to_s.strip
  end

  # Returns the inner HTML of a given node
  #
  # eg.
  # <p>foo</p> => foo
  def extract_text(node)
    node.content
  end

  # Returns the tag name of a given node
  #
  # eg
  # <p>foo</p> => p
  def extract_tag_name(node)
    node.name.downcase
  end

  # Returns the anchor to the node
  #
  # eg.
  # <h1 name="anchor">Foo</h1> => anchor
  # <h1 id="anchor">Foo</h1> => anchor
  # <h1><a name="anchor">Foo</a></h1> => anchor
  def extract_anchor(node)
    anchor = node.attr('name') || node.attr('id') || nil
    return anchor unless anchor.nil?

    # No anchor found directly in the header, search on children
    subelement = node.css('[name],[id]')
    return extract_anchor(subelement[0]) unless subelement.empty?

    nil
  end

  ##
  # Generate a unique identifier for the item
  def uuid(item)
    # We first get all the keys of the object, sorted alphabetically...
    ordered_keys = item.keys.sort

    # ...then we build a huge array of "key=value" pairs...
    ordered_array = ordered_keys.map do |key|
      value = item[key]
      # We apply the method recursively on other hashes
      value = uuid(value) if value.is_a?(Hash)
      "#{key}=#{value}"
    end

    # ...then we build a unique md5 hash of it
    Digest::MD5.hexdigest(ordered_array.join(','))
  end

  ##
  # Get a relative numeric value of the importance of the heading
  # 100 for top level, then -10 per heading
  def heading_weight(heading_level)
    weight = 100
    return weight if heading_level.nil?
    weight - ((heading_level + 1) * 10)
  end

  def extract
    heading_selector = 'h1,h2,h3,h4,h5,h6'
    # We select all nodes that match either the headings or the elements to
    # extract. This will allow us to loop over it in order it appears in the DOM
    all_selector = "#{heading_selector},#{@options[:css_selector]}"

    items = []
    current_hierarchy = {
      lvl0: nil,
      lvl1: nil,
      lvl2: nil,
      lvl3: nil,
      lvl4: nil,
      lvl5: nil
    }
    current_position = 0 # Position of the DOM node in the tree
    current_lvl = nil # Current closest hierarchy level
    current_anchor = nil # Current closest anchor

    @dom.css(all_selector).each do |node|
      # If it's a heading, we update our current hierarchy
      if node.matches?(heading_selector)
        # Which level heading is it?
        current_lvl = extract_tag_name(node).gsub(/^h/, '').to_i - 1
        # Update this level, and set all the following ones to nil
        current_hierarchy["lvl#{current_lvl}".to_sym] = extract_text(node)
        (current_lvl + 1..6).each do |lvl|
          current_hierarchy["lvl#{lvl}".to_sym] = nil
        end
        # Update the anchor, if the new heading has one
        new_anchor = extract_anchor(node)
        current_anchor = new_anchor if new_anchor
      end

      # Stop if node is not to be extracted
      next unless node.matches?(@options[:css_selector])

      # Stop if node is empty
      text = extract_text(node)
      next if text.empty?

      item = {
        html: extract_html(node),
        text: text,
        tag_name: extract_tag_name(node),
        hierarchy: current_hierarchy.clone,
        anchor: current_anchor,
        node: node,
        weight: {
          position: current_position,
          heading: heading_weight(current_lvl)
        }
      }
      item[:uuid] = uuid(item)
      items << item

      current_position += 1
    end

    items
  end
end
