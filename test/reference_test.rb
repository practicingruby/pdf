# encoding: ASCII-8BIT

require File.join(File.expand_path(File.dirname(__FILE__)), "test_helper")

class PdfReference < Test::Unit::TestCase

  context "A Reference object" do
    test "should produce a PDF reference on #to_s call" do
      ref = PDF::Reference(1,true)
      assert_equal "1 0 R", ref.to_s
    end                                        
    
    test "should allow changing generation number" do
      ref = PDF::Reference(1,true)
      ref.gen = 1
      assert_equal "1 1 R", ref.to_s
    end
    
    test "should generate a valid PDF object for the referenced data" do
      ref = PDF::Reference(2,[1,"foo"]) 
        
      assert_equal "2 0 obj\n#{PDF.serialize([1,"foo"])}\nendobj\n",
                   ref.object
    end             
    
    test "should automatically open a stream when #<< is used" do
       ref = PDF::Reference(1, :Length => 41)
       ref << "BT\n/F1 12 Tf\n72 712 Td\n( A stream ) Tj\nET"   
       expected = "1 0 obj\n<< /Length 41\n>>\nstream"+
                  "\nBT\n/F1 12 Tf\n72 712 Td\n( A stream ) Tj\nET" +
                  "\nendstream\nendobj\n"

       assert_equal expected, ref.object
    end

    test "should compress a stream upon request" do
      ref = PDF::Reference(2,{})
      ref << "Hi There " * 20

      cref = PDF::Reference(2,{})
      cref << "Hi There " * 20
      cref.compress_stream

      assert cref.stream.size < ref.stream.size, 
        "compressed stream expected to be smaller than source but wasn't"
      assert_equal :FlateDecode, cref.data[:Filter]
    end

    test "should copy the data and stream from another ref on #replace" do
      from = PDF::Reference(3, {:foo => 'bar'})
      from << "has a stream too"

      to = PDF::Reference(4, {:foo => 'baz'})
      to.replace from

      # should preserve identifier but copy data and stream
      assert_equal 4, to.identifier
      assert_equal from.data, to.data
      assert_equal from.stream, to.stream
    end

    test "should copy a compressed stream from a compressed ref on #replace" do
      from = PDF::Reference(5, {:foo => 'bar'})
      from << "has a stream too " * 20
      from.compress_stream

      to = PDF::Reference(6, {:foo => 'baz'})
      to.replace(from)

      assert_equal 6, to.identifier
      assert_equal from.data, to.data
      assert_equal from.stream, to.stream
      assert to.compressed?
    end

    context "generated via PDF::Document" do
      test "should return a proper reference on ref!" do
        pdf = PDF::Document.new
        assert_kind_of(PDF::Reference, pdf.ref!({}))
      end

      test "should return an identifier on ref" do
        pdf = PDF::Document.new
        assert_kind_of(Integer, pdf.ref({}))
      end
    end
  end

end



