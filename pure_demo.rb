require './lib/pure'

@template = Nokogiri::HTML(open('views/who/template.html'))
@mod_template = @template.dup

@data = open('views/who/data.json').read
@directive = open('views/who/directive.json').read

Renderer.render(@mod_template, @data, @directive)

2.times { puts }
puts @template.to_html
2.times { puts }
puts @mod_template.to_html
