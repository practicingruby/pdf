# encoding: ASCII-8BIT

require File.join(File.expand_path(File.dirname(__FILE__)), "test_helper")

# See PDF Reference, Sixth Edition (1.7) pp51-60 for details 

class PdfObjectSeralization < Test::Unit::TestCase

  context "PDF Object Serialization" do     
                
    test "should convert Ruby's nil to PDF null" do
      assert_equal "null", PDF.serialize(nil)
    end
    
    test "should convert Ruby booleans to PDF booleans" do
      assert_equal "true",  PDF.serialize(true)
      assert_equal "false", PDF.serialize(false)
    end
                                            
    test "should convert a Ruby number to PDF number" do
      assert_equal "1", PDF.serialize(1)
      assert_equal "1.214112421", PDF.serialize(1.214112421)
    end
    
    test "should convert a Ruby time object to a PDF timestamp" do
      t = Time.now
      assert_equal t.strftime("(D:%Y%m%d%H%M%S%z").chop.chop + "'00')", 
                   PDF.serialize(t)
    end
    
    test "should convert a Ruby string to PDF string when inside a content stream" do       
      s = "I can has a string"
      assert_equal s, PDF::Inspector.parse(PDF.serialize(s, true))
    end                      

    test "should convert a Ruby string to a UTF-16 PDF string when outside a content stream" do       
      s = "I can has a string"
      s_utf16 = "\xFE\xFF" + s.unpack("U*").pack("n*")
      assert_equal s_utf16, PDF::Inspector.parse(PDF.serialize(s, false))
    end                      

    test "should pass through bytes regardless of content stream status for ByteString" do
      assert_equal "<DEADBEEF>",
        PDF.serialize(PDF::ByteString.new("\xDE\xAD\xBE\xEF")).upcase
    end
    
    test "should escape parens when converting from Ruby string to PDF" do
      s =  'I )(can has a string'      
      assert_equal s, PDF::Inspector.parse(PDF.serialize(s, true))
    end               
    
    test "should handle ruby escaped parens when converting to PDF string" do
      s = 'I can \\)( has string'
      assert_equal s, PDF::Inspector.parse(PDF.serialize(s, true))
    end      
    
    test "should convert a Ruby symbol to PDF name" do
      assert_equal "/my_symbol", PDF.serialize(:my_symbol)

      assert_equal "/A;Name_With−Various***Characters?",
         PDF.serialize(:"A;Name_With−Various***Characters?")
    end
   
    test "should not convert a whitespace containing Ruby symbol to a PDF name" do
      assert_raises(PDF::Errors::FailedObjectConversion) do 
        PDF.serialize(:"My Symbol With Spaces")
      end
    end    
    
    test "should convert a Ruby array to PDF Array when inside a content stream" do
      assert_equal "[1 2 3]", PDF.serialize([1,2,3])
      
      assert_equal [[1,2],:foo, "Bar"], 
        PDF::Inspector.parse(PDF.serialize([[1,2],:foo,"Bar"], true))
    end  

    test "should convert a Ruby array to PDF Array when outside a content stream" do
      bar = "\xFE\xFF" + "Bar".unpack("U*").pack("n*")
      assert_equal "[1 2 3]", PDF.serialize([1,2,3])
      assert_equal [[1,2],:foo, bar], 
        PDF::Inspector.parse(PDF.serialize([[1,2],:foo,"Bar"], false))
    end  
   
    test "should convert a Ruby hash to a PDF Dictionary when inside a content stream" do
      dict = PDF.serialize( {:foo  => :bar, 
                                "baz" => [1,2,3], 
                                :bang => {:a => "what", :b => [:you, :say] }}, true )     

      res = PDF::Inspector.parse(dict)           

      assert_equal :bar, res[:foo]
      assert_equal [1,2,3], res[:baz]
      assert_equal({ :a => "what", :b => [:you, :say] }, res[:bang])
    end      

    test "should convert a Ruby hash to a PDF Dictionary when outside a content stream" do
      what = "\xFE\xFF" + "what".unpack("U*").pack("n*")
      dict = PDF.serialize( {:foo  => :bar, 
                                "baz" => [1,2,3], 
                                :bang => {:a => "what", :b => [:you, :say] }}, false )

      res = PDF::Inspector.parse(dict)           

      assert_equal :bar, res[:foo]
      assert_equal [1,2,3], res[:baz]
      assert_equal({ :a => what, :b => [:you, :say] }, res[:bang])
    end      
    
    test "should not allow keys other than strings or symbols for PDF dicts" do
      assert_raises(PDF::Errors::FailedObjectConversion) do
        PDF.serialize(:foo => :bar, :baz => :bang, 1 => 4)
      end
    end  
    
    test "should convert a PDF::Reference to a PDF indirect object reference" do
      ref = PDF::Reference(1,true)
      assert_equal ref.to_s, PDF.serialize(ref)
    end

    test "should convert a NameTree::Node to a PDF hash" do
      node = PDF::NameTree::Node.new(PDF::Document.new, 10)
      node.add "hello", 1.0
      node.add "world", 2.0
      data = PDF.serialize(node)
      res = PDF::Inspector.parse(data)
      assert_equal({:Names => ["hello", 1.0, "world", 2.0]}, res)
    end
  end
end
