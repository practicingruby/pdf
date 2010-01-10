require "stringio"

module PDF
  class Document

     PAGE_SIZES = { "4A0" => [4767.87, 6740.79],
                    "2A0" => [3370.39, 4767.87],
                     "A0" => [2383.94, 3370.39],
                     "A1" => [1683.78, 2383.94],
                     "A2" => [1190.55, 1683.78],
                     "A3" => [841.89, 1190.55],
                     "A4" => [595.28, 841.89],
                     "A5" => [419.53, 595.28],
                     "A6" => [297.64, 419.53],
                     "A7" => [209.76, 297.64],
                     "A8" => [147.40, 209.76],
                     "A9" => [104.88, 147.40],
                    "A10" => [73.70, 104.88],
                     "B0" => [2834.65, 4008.19],
                     "B1" => [2004.09, 2834.65],
                     "B2" => [1417.32, 2004.09],
                     "B3" => [1000.63, 1417.32],
                     "B4" => [708.66, 1000.63],
                     "B5" => [498.90, 708.66],
                     "B6" => [354.33, 498.90],
                     "B7" => [249.45, 354.33],
                     "B8" => [175.75, 249.45],
                     "B9" => [124.72, 175.75],
                    "B10" => [87.87, 124.72],
                     "C0" => [2599.37, 3676.54],
                     "C1" => [1836.85, 2599.37],
                     "C2" => [1298.27, 1836.85],
                     "C3" => [918.43, 1298.27],
                     "C4" => [649.13, 918.43],
                     "C5" => [459.21, 649.13],
                     "C6" => [323.15, 459.21],
                     "C7" => [229.61, 323.15],
                     "C8" => [161.57, 229.61],
                     "C9" => [113.39, 161.57],
                    "C10" => [79.37, 113.39],
                    "RA0" => [2437.80, 3458.27],
                    "RA1" => [1729.13, 2437.80],
                    "RA2" => [1218.90, 1729.13],
                    "RA3" => [864.57, 1218.90],
                    "RA4" => [609.45, 864.57],
                   "SRA0" => [2551.18, 3628.35],
                   "SRA1" => [1814.17, 2551.18],
                   "SRA2" => [1275.59, 1814.17],
                   "SRA3" => [907.09, 1275.59],
                   "SRA4" => [637.80, 907.09],
              "EXECUTIVE" => [521.86, 756.00],
                  "FOLIO" => [612.00, 936.00],
                  "LEGAL" => [612.00, 1008.00],
                 "LETTER" => [612.00, 792.00],
                "TABLOID" => [792.00, 1224.00] }



    include PDF::Graphics

    # :info - PDF metadata
    # :optimize_objects 
    # page_dimensions
    def initialize(options={})
      @store            = ObjectStore.new(options.fetch(:info, {}))
      @version          = 1.3
      @optimize_objects = options.fetch(:optimize_objects, false)
      @page_content     = nil
      @page_number      = 0
      @trailer          = {}
      @page_dimensions  = options.fetch(:page_dimensions, PAGE_SIZES["LETTER"])
    end

    attr_reader :page_dimensions

    def start_new_page
      build_new_page_content

      @store.pages.data[:Kids].insert(@page_number, current_page)
      @store.pages.data[:Count] += 1
      @page_number += 1

      add_content "q"
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

    # Grabs the reference for the current page content
    #
    def page_content
      @active_stamp_stream || @store[@page_content]
    end

    # Appends a raw string to the current page content.
    #                               
    #  # Raw line drawing example:           
    #  x1,y1,x2,y2 = 100,500,300,550
    #  pdf.add_content("%.3f %.3f m" % [ x1, y1 ])  # move 
    #  pdf.add_content("%.3f %.3f l" % [ x2, y2 ])  # draw path
    #  pdf.add_content("S") # stroke                    
    #
    def add_content(str)
      page_content << str << "\n"
    end  

   # Renders the PDF document to string
    #
    def render
      output = StringIO.new
      finalize_all_page_contents

      render_header(output)
      render_body(output)
      render_xref(output)
      render_trailer(output)
      str = output.string
      str.force_encoding("ASCII-8BIT")
      str
    end
    
    # Write out the PDF Header, as per spec 3.4.1
    #
    def render_header(output)
      # pdf version
      output << "%PDF-#{@version}\n"

      # 4 binary chars, as recommended by the spec
      output << "%\xFF\xFF\xFF\xFF\n"
    end

    # Write out the PDF Body, as per spec 3.4.2
    #
    def render_body(output)
      @store.compact if @optimize_objects
      @store.each do |ref|
        ref.offset = output.size
        output << ref.object
      end
    end

    # Write out the PDF Cross Reference Table, as per spec 3.4.3
    #
    def render_xref(output)
      @xref_offset = output.size
      output << "xref\n"
      output << "0 #{@store.size + 1}\n"
      output << "0000000000 65535 f \n"
      @store.each do |ref|
        output.printf("%010d", ref.offset)
        output << " 00000 n \n"
      end
    end

    # Write out the PDF Trailer, as per spec 3.4.4
    #
    def render_trailer(output)
      trailer_hash = {:Size => @store.size + 1, 
                      :Root => @store.root,
                      :Info => @store.info}
      trailer_hash.merge!(@trailer) if @trailer

      output << "trailer\n"
      output << PDF.serialize(trailer_hash) << "\n"
      output << "startxref\n" 
      output << @xref_offset << "\n"
      output << "%%EOF" << "\n"
    end

    # Re-opens the page with the given (1-based) page number so that you can
    # draw on it. Does not restore page state such as margins, page orientation,
    # or paper size, so you'll have to handle that yourself.
    #
    # See Prawn::Document#number_pages for a sample usage of this capability.
    #
    def go_to_page(k)
      @page_number = k
      jump_to = @store.pages.data[:Kids][k-1]
      @current_page = jump_to.identifier
      @page_content = jump_to.data[:Contents].identifier
    end

    # Returns true if content streams will be compressed before rendering,
    # false otherwise
    #
    def compression_enabled?
      !!@compress
    end

    # The Resources dictionary for the current page
    #
    def page_resources
      current_page.data[:Resources] ||= {}
    end

    # Grabs the reference for the current page
    #
    def current_page
      @active_stamp_dictionary || @store[@current_page]
    end

    def page_count
      @store.pages.data[:Count]
    end

    private

    def finalize_all_page_contents
      (1..page_count).each do |i|
        go_to_page i
        add_content "Q"
        page_content.compress_stream if compression_enabled?
        page_content.data[:Length] = page_content.stream.size
      end
    end

    def build_new_page_content
      @page_content = ref(:Length => 0)

      @current_page = ref(:Type      => :Page,
                          :Parent    => @store.pages,
                          :MediaBox  => page_dimensions,
                          :Contents  => page_content)

      # include all proc sets, all the time (recommended by PDF 1.4 Reference 
      # section 9.1)
      page_resources[:ProcSet] = [:PDF, :Text, :ImageB, :ImageC, :ImageI]
    end
      
  end
end
