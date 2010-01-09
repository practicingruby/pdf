module PDF

  extend self

  ByteString    = Class.new(String)
  LiteralString = Class.new(String)

  def serialize(obj, in_content_stream = false)
    case(obj)        
    when NilClass   then "null" 
    when TrueClass  then "true"
    when FalseClass then "false"
    when Numeric    then String(obj)
    when Array
      "[" << obj.map { |e| serialize(e, in_content_stream) }.join(' ') << "]"
    when PDF::LiteralString
      obj = obj.gsub(/[\\\n\(\)]/) { |m| "\\#{m}" }
      "(#{obj})"
    when Time
      obj = obj.strftime("D:%Y%m%d%H%M%S%z").chop.chop + "'00'"
      obj = obj.gsub(/[\\\n\(\)]/) { |m| "\\#{m}" }
      "(#{obj})"
    when PDF::ByteString
      "<" << obj.unpack("H*").first << ">"
    when String
      obj = "\xFE\xFF" + obj.unpack("U*").pack("n*") unless in_content_stream
      "<" << obj.unpack("H*").first << ">"
    when Symbol                                                         
       if (obj = obj.to_s) =~ /\s/
         raise PDF::Errors::FailedObjectConversion, 
           "A PDF Name cannot contain whitespace"  
       else
         "/" << obj   
       end 
    when ::Hash           
      output = "<< "
      obj.each do |k,v|                                                        
        unless String === k || Symbol === k
          raise PDF::Errors::FailedObjectConversion, 
            "A PDF Dictionary must be keyed by names"
        end                          
        output << serialize(k.to_sym, in_content_stream) << " " << 
                  serialize(v, in_content_stream) << "\n"
      end   
      output << ">>"  
    when PDF::Reference
      obj.to_s      
    when PDF::NameTree::Node
      serialize(obj.to_hash)
    when PDF::NameTree::Value
      serialize(obj.name) + " " + serialize(obj.value)
    else
      raise PDF::Errors::FailedObjectConversion, 
        "This object cannot be serialized to PDF"
    end     

  end
end


require "pdf/errors"
require "pdf/reference"
require "pdf/name_tree"
require "pdf/document"
