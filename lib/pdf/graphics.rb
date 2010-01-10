module PDF
  module Graphics
    def move_to(x,y)
      add_content("%.3f %.3f m" % [x, y])
    end

    def line_to(x,y)
      add_content("%.3f %.3f l" % [x, y])
    end

    def stroke
      add_content("S")
    end
  end
end
