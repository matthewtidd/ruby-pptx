module PPTX
  module Shapes
    class Shape
      def initialize(transform)
        @transform = transform
      end

      def base_node
        @base_node ||= Nokogiri::XML::DocumentFragment.parse(base_xml).tap do |node|
          set_shape_properties(node, *@transform)
        end
      end

      def set_shape_properties(node, x, y, width, height)
        xml = """
          <p:spPr xmlns:a='http://schemas.openxmlformats.org/drawingml/2006/main'
                  xmlns:p='http://schemas.openxmlformats.org/presentationml/2006/main'>
              <a:xfrm>
                  <a:off x='#{x.to_i}' y='#{y.to_i}'/>
                  <a:ext cx='#{width.to_i}' cy='#{height.to_i}'/>
              </a:xfrm>
              <a:prstGeom prst='rect'>
                  <a:avLst/>
              </a:prstGeom>
          </p:spPr>
          """

        node.xpath('.//p:spPr', p: Presentation::NS)
            .first
            .replace(Nokogiri::XML::DocumentFragment.parse(xml))
      end

      def build_solid_fill(rgb_color)
        fill_xml = """
        <a:solidFill xmlns:a='http://schemas.openxmlformats.org/drawingml/2006/main'>
          <a:srgbClr val='SETME'/>
        </a:solidFill>
        """

        Nokogiri::XML::DocumentFragment.parse(fill_xml).tap do |node|
          node.xpath('.//a:srgbClr', a: DRAWING_NS).first['val'] = rgb_color
        end
      end

      def build_bullet(bullet = "•", color = "000000")
        bullet = "•" unless bullet.class == String
        bullet_xml = """
        <a:buClr>
          <a:srgbClr val='#{color}' />
        </a:buClr>
        <a:buChar char='#{bullet}' />
        """

        Nokogiri::XML::DocumentFragment.parse(bullet_xml)
      end

      def build_after_space(val = 0)
        after_space_xml = """
        <a:spcAft>
        <a:spcPts val='#{val}' />
        </a:spcAft>
        """

        Nokogiri::XML::DocumentFragment.parse(after_space_xml)
      end
    end
  end
end
