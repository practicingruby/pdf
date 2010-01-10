# encoding: utf-8

# object_store.rb : Implements PDF object repository for PDF
#
# Copyright August 2009, Brad Ediger.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
module PDF
  class ObjectStore #:nodoc:
    include Enumerable

    BASE_OBJECTS = %w[info pages root]

    def initialize(info={})
      @objects = {}
      @identifiers = []
      
      # Create required PDF roots
      @info    = ref(info).identifier
      @pages   = ref(:Type => :Pages, :Count => 0, :Kids => []).identifier
      @root    = root_ref(info[:outlines]).identifier
    end
    
    def root_ref(outlines = nil)
      root_hash = {:Type => :Catalog, :Pages => pages }
      root_hash.merge(:Outlines => "") if outlines
      ref(root_hash)
    end

    def ref(data, &block)
      push(size + 1, data, &block)
    end                                               

    def info
      @objects[@info]
    end

    def pages
      @objects[@pages]
    end

    def root
      @objects[@root]
    end

    # Adds the given reference to the store and returns the reference object.
    # If the object provided is not a PDF::Reference, one is created from the
    # arguments provided.
    def push(*args, &block)
      reference = if args.first.is_a?(PDF::Reference)
              args.first
            else
              PDF::Reference.new(*args, &block)
            end
 

      @objects[reference.identifier] = reference
      @identifiers << reference.identifier
      reference
    end
    alias_method :<<, :push

    def each
      @identifiers.each do |id|
        yield @objects[id]
      end
    end

    def [](id)
      @objects[id]
    end

    def size
      @identifiers.size
    end

    alias_method :length, :size

    def compact
      # Clear live markers
      each { |o| o.live = false }

      # Recursively mark reachable objects live, starting from the roots
      # (the only objects referenced in the trailer)
      root.mark_live
      info.mark_live

      # Renumber live objects to eliminate gaps (shrink the xref table)
      if @objects.any?{ |_, o| !o.live }
        new_id = 1
        new_objects = {}
        new_identifiers = []

        each do |obj|
          if obj.live
            obj.identifier = new_id
            new_objects[new_id] = obj
            new_identifiers << new_id
            new_id += 1
          end
        end

        @objects = new_objects
        @identifiers = new_identifiers
      end
    end

  end
end
