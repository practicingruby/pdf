# encoding: ASCII-8BIT

require File.join(File.expand_path(File.dirname(__FILE__)), "test_helper")

class PdfNameTree < Test::Unit::TestCase

  context "Name Tree" do     

    def setup
      @pdf = PDF::Document.new
      @pdf.extend(ExposeObjectStore)
    end

    test "should have no children when first initialized" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      assert_equal 0, node.children.length
    end

    test "should have no subtrees while child limit is not reached" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3])
      assert_tree_dump "[one=1,three=3,two=2]", node
    end

    test "should split into subtrees when limit is exceeded" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3], ["four", 4])
      assert_tree_dump "[[four=4,one=1],[three=3,two=2]]", node
    end

    test "should create a two new references when root is split" do
      ref_count = @pdf.object_store.length
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3], ["four", 4])
      assert_equal ref_count + 2,  @pdf.object_store.length
    end
    
    test "should create a one new reference when subtree is split" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3], ["four", 4])

      ref_count = @pdf.object_store.length # save when root is split
      tree_add(node, ["five", 5], ["six", 6], ["seven", 7])
      
      assert_tree_dump "[[five=5,four=4,one=1],[seven=7,six=6],[three=3,two=2]]", node

      assert_equal ref_count + 1, @pdf.object_store.length
    end

    test "should keep tree balanced when subtree split cascades to root" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3], ["four", 4])
      tree_add(node, ["five", 5], ["six", 6], ["seven", 7], ["eight", 8])

      expected = "[[[eight=8,five=5],[four=4,one=1]],"+
                  "[[seven=7,six=6],[three=3,two=2]]]"

      assert_tree_dump expected, node
    end

    test "should maintain order of already properly ordered nodes" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["eight", 8], ["five", 5], ["four", 4], ["one", 1])
      tree_add(node, ['seven', 7], ['six', 6], ['three', 3], ['two', 2])
      expected = "[[[eight=8,five=5],[four=4,one=1]]," +
                  "[[seven=7,six=6],[three=3,two=2]]]"

      assert_tree_dump expected, node
    end

    test "should emit only :Names key with to_hash if root is only node" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3])
      expected =  { :Names => [tree_value("one", 1), 
                               tree_value("three", 3), 
                               tree_value("two", 2)] }

      assert_equal expected, node.to_hash
    end

    test "should emit only :Kids key with to_hash if root has children" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3], ["four", 4])
      
      expected = { :Kids => node.children.map { |child| child.ref } }
      assert_equal expected, node.to_hash
    end

    test "should emit :Limits and :Names keys with to_hash for leaf node" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3], ["four", 4])
      expected = 
        { :Limits => %w(four one),
          :Names => [tree_value("four", 4), tree_value("one", 1)] }

      assert_equal expected, node.children.first.to_hash
    end

    test "should emit :Limits and :Kids keys with to_hash for inner node" do
      node = PDF::NameTree::Node.new(@pdf, 3)
      tree_add(node, ["one", 1], ["two", 2], ["three", 3], ["four", 4])
      tree_add(node, ["five", 5], ["six", 6], ["seven", 7], ["eight", 8])
      tree_add(node, ["nine", 9], ["ten", 10], ["eleven", 11], ["twelve", 12])
      tree_add(node, ["thirteen", 13], ["fourteen", 14], ["fifteen", 15], ["sixteen", 16])
      expected = 
        { :Limits => %w(eight one),
          :Kids => node.children.first.children.map { |child| child.ref } }

      assert_equal expected, node.children.first.to_hash
    end
  end

  def assert_tree_dump(str, node)
    assert_equal str, tree_dump(node)
  end

  def tree_dump(tree)
    if tree.is_a?(PDF::NameTree::Node)
      "[" + tree.children.map { |child| tree_dump(child) }.join(",") + "]"
    else
      "#{tree.name}=#{tree.value}"
    end
  end

  def tree_add(tree, *args)
    args.each do |(name, value)|
      tree.add(name, value)
    end
  end

  def tree_value(name, value)
    PDF::NameTree::Value.new(name, value)
  end

  module ExposeObjectStore
    def object_store
      @store
    end
  end

end


