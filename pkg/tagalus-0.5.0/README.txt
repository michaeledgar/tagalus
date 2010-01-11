= tagalus

* http://www.carboni.ca/projects/tagalus/

== DESCRIPTION:

This module encapsulates the API for tagal.us, a site which helps users
define tags on twitter or other websites. The basic elements are tags,
definitions, and comments - and these 3 objects can be written and read
to/from tagal.us using this gem.

There's just 6 useful methods - 3 that read, and 3 that write.

This module uses the Carboni.ca XML base, which means you can set which
XML parser it will use - simply use
   Tagalus.parser = :nokogiri # can be :nokogiri, :hpricot, :rexml, or :libxml
to change the parser.

== FEATURES/PROBLEMS:

* Full access to the Tagul.us API
* Swap out XML parsers - nokogiri, hpricot, rexml, and libxml-ruby are supported

== SYNOPSIS:

Exmaple usage:
   acc = Tagalus::Account.new("1290185015890")
   acc.define("apisandbox") #=> <Definition>
   acc.comments("apisandbox").each do |comm|
     puts comm.text+"\n"
   end
   acc.post_comment "apisandbox", "Testing, 1,2,3!" #=> <Comment>

== REQUIREMENTS:

* none, though an XML parser other than REXML will make it run quicker

== INSTALL:

* sudo gem install tagalus

== LICENSE:

(The MIT License)

Copyright (c) 2009 Michael J. Edgar

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
