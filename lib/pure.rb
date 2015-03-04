require 'nokogiri'
require 'json'
require 'pry'

class Renderer
  attr_reader :template, :data, :directives

  class << self
    def render(template, data, directives)
      new(template, data, directives).render!
    end
  end

  def initialize(template, data, directives)
    @template    = template
    @data        = data.is_a?(String)       ? JSON.parse(data)       : data
    __directives = directives.is_a?(String) ? JSON.parse(directives) : directives
    @directives  = DirectivesFactory.build_from(__directives, template, @data)
  end

  def render!
    directives.each(&:process!)

    # write_to_file
  end

  private

  def write_to_file(filename = 'output.html')
    File.open(filename, 'w') do |file|
      file.puts template.to_html
    end
  end
end

class DirectivesFactory
  class << self
    def build_from(directives, template, data)
      directives.map { |directive| Directive.new(directive, template, data) }
    end
  end
end

class Directive
  attr_reader :target, :instruction, :template, :data, :selector, :attribute, :node

  def initialize(instructions, template, data)
    @target, @instruction = instructions.to_a
    @template, @data      = template, data
    @selector, @attribute = extract_selector_and_attr

    @node = template.at_css(selector)
  end

  def process!
    case instruction
    when String
      attribute ? node[attribute] = data[instruction] : node.content = data[instruction]
    when Hash
      loop_data_target, loop_directive = instruction.to_a.flatten!

      m = /<-/.match(loop_data_target)
      data_collection    = data[m.post_match]
      singular_data_item = m.pre_match

      loop_target, loop_instruction = loop_directive.to_a.flatten!
      item_name, item_attr          = loop_instruction.split('.')

      data_collection.each_with_index do |data_hash, index|
        node_to_edit = node.css(loop_target)[index] || build_node_from(target, loop_target)
        node_to_edit.content = data_hash[item_attr]
      end
    end
  end

  private

  def build_node_from(parent, target_node)
    new_node = node.parent.add_child(Nokogiri::XML::Node.new(parent, template))
    new_node.add_child(Nokogiri::XML::Node.new(target_node, template))
  end

  def extract_selector_and_attr
    if (m = /@/.match(target))
      sel, atr = m.pre_match, m.post_match
    end

    [sel || target, atr]
  end
end
