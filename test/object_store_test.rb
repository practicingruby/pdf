# encoding: ASCII-8BIT

require File.join(File.expand_path(File.dirname(__FILE__)), "test_helper")

class PdfObjectStore < Test::Unit::TestCase
  context "PDF::ObjectStore" do
    def setup
      @store = PDF::ObjectStore.new
    end

    test "should create required roots by default, including info passed to new" do
      store = PDF::ObjectStore.new(:Test => 3)
      assert_equal 3, store.size
      assert_equal 3, store.info.data[:Test]
      assert_equal 0, store.pages.data[:Count]
      assert_equal store.pages, store.root.data[:Pages]
    end

    test "should add to its objects when ref() is called" do
      count = @store.size
      @store.ref("blah")
      assert_equal count + 1, @store.size
    end

    test "should accept push with a PDF::Reference" do
      r = PDF::Reference(123, "blah")
      @store.push(r)
      assert_equal r, @store[r.identifier]
    end

    test "should accept arbitrary data and use it to create a PDF::Reference" do
      @store.push(123, "blahblah")
      assert_equal "blahblah", @store[123].data
    end

    test "should be Enumerable, yielding in order of submission" do
      # higher IDs to bypass the default roots
      [10, 11, 12].each do |id|
        @store.push(id, "some data #{id}")
      end
      
      assert_equal [10,11,12], @store.map{ |ref| ref.identifier }[-3..-1]
    end
  end

  context "PDF::ObjectStore#compact" do
    test "should do nothing to an ObjectStore with all live refs" do
      store = PDF::ObjectStore.new
      store.info.data[:Blah] = store.ref(:some => "structure")
      old_size = store.size
      store.compact

      assert_equal old_size, store.size
    end

    test "should remove dead objects, renumbering live objects from 1" do
      store = PDF::ObjectStore.new
      store.ref(:some => "structure")
      old_size = store.size
      store.compact
      
      assert store.size < old_size
      assert_equal (1..store.size).to_a, store.map{ |o| o.identifier }
    end

    test "should detect and remove dead objects that were once live" do
      store = PDF::ObjectStore.new
      store.info.data[:Blah] = store.ref(:some => "structure")
      store.info.data[:Blah] = :overwritten
      old_size = store.size
      store.compact
      
      assert store.size < old_size
      assert_equal (1..store.size).to_a, store.map { |o| o.identifier }
    end
  end
end

