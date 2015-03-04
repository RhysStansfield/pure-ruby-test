require 'sinatra'

require './lib/pure'

get '/' do
  open('views/home/template.html')
end

get '/who', provides: 'html' do
  template  = Nokogiri::HTML(open('views/who/template.html'))
  data      = open('views/who/data.json').read
  directive = open('views/who/directive.json').read

  Renderer.render(template, data, directive)

  template.to_html
end
