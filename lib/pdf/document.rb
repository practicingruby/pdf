module PDF
  class Document

    # :info - PDF metadata
    #
    def initialize(options={})
      @store = ObjectStore.new(options[:info] || {})
    end

    # Creates a new Prawn::Reference and adds it to the Document's object
    # list.  The +data+ argument is anything that Prawn::PdfObject() can convert. 
    #
    # Returns the identifier which points to the reference in the ObjectStore   
    # 
    def ref(data)
      ref!(data).identifier
    end                                               

    # Like ref, but returns the actual reference instead of its identifier.
    # 
    # While you can use this to build up nested references within the object
    # tree, it is recommended to persist only identifiers, and them provide
    # helper methods to look up the actual references in the ObjectStore
    # if needed.  If you take this approach, Prawn::Document::Snapshot
    # will probably work with your extension
    #
    def ref!(data)
      @store.ref(data)
    end
  end
end
