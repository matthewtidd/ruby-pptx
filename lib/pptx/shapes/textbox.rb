module PPTX
  module Shapes
    class Textbox < Shape
      def initialize(transform, content, formatting={})
        super(transform)
        @content = content
        @formatting = formatting
      end

      def base_xml
        # TODO replace cNvPr descr, id and name
        """
          <p:sp xmlns:a='http://schemas.openxmlformats.org/drawingml/2006/main'
                xmlns:p='http://schemas.openxmlformats.org/presentationml/2006/main'>
              <p:nvSpPr>
                  <p:cNvPr id='2' name='TextBox'/>
                  <p:cNvSpPr txBox='1'/>
                  <p:nvPr/>
              </p:nvSpPr>
              <p:spPr>
              </p:spPr>
              <p:txBody>
                  <a:bodyPr rtlCol='0' wrap='square' vertOverflow='clip'>
                      <a:spAutoFit/>
                  </a:bodyPr>
                  <a:lstStyle/>
              </p:txBody>
          </p:sp>
        """
      end

      def build_node
        txbody = base_node.xpath('./p:sp/p:txBody', p:Presentation::NS).first

        @content.split("\n").each do |line|
          paragraph = build_paragraph line
          set_formatting(paragraph, @formatting)
          txbody.add_child paragraph
        end

        # txBody always needs a paragraph
        unless txbody.xpath('./a:p', a: DRAWING_NS).size >= 1
          txbody.add_child empty_paragraph
        end

        base_node
      end

      def build_paragraph(line)
        paragraph_xml = """
          <a:p xmlns:a='http://schemas.openxmlformats.org/drawingml/2006/main'>
              <a:pPr/>
              <a:r>
                  <a:rPr lang='en-US' smtClean='0'>
                     <a:latin/>
                  </a:rPr>
                  <a:t></a:t>
              </a:r>
              <a:endParaRPr lang='en-US'/>
          </a:p>
        """

        Nokogiri::XML::DocumentFragment.parse(paragraph_xml).tap do |node|
          tn = node.xpath('./a:p/a:r/a:t', a: DRAWING_NS).first
          tn.content = line
        end
      end

      def empty_paragraph
        paragraph_xml = """
          <a:p xmlns:a='http://schemas.openxmlformats.org/drawingml/2006/main'></a:p>
        """
        Nokogiri::XML::DocumentFragment.parse(paragraph_xml)
      end

      # Set paragraph and text run properties on a paragraph.
      # Node must already have pPr and rPr elements.
      def set_formatting(paragraph, formatting)
        formatting = formatting.dup
        color = formatting.delete(:color)
        align = formatting.delete(:align)
        typeface = formatting.delete(:typeface)
        bullet = formatting.delete(:bullet)
        bullet_color = formatting.delete(:bullet_color) rescue nil
        after_spacing = formatting.delete(:after_spacing) rescue nil

        p_properties = paragraph.xpath('./a:p/a:pPr', a: DRAWING_NS).first
        if align
          p_properties['algn'] = align
        end

        if typeface
          latin = paragraph.xpath('./a:p/a:r/a:rPr/a:latin', a: DRAWING_NS).first
          latin['typeface'] = typeface
        end

        run_properties = paragraph.xpath('.//a:rPr', a: DRAWING_NS).first
        formatting.each do |key, val|
          run_properties[key] = val
        end

        run_properties.prepend_child build_solid_fill(color) if color
        p_properties.prepend_child build_bullet(bullet, bullet_color) if bullet
        if bullet
          p_properties["marL"] = "119863"
          p_properties["indent"] = "-119863"
        end
        p_properties.prepend_child build_after_space(after_spacing) if after_spacing

      end
    end
  end
end
