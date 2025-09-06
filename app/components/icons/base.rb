class Components::Icons::Base < Components::Base
  def initialize(size: :md, class: nil, **attributes)
    @size = size
    @class = grab(class:)
    @attributes = attributes
  end

  private

  attr_reader :size, :attributes

  def svg_attributes
    base_attributes = {
      class: merged_classes,
      fill: "currentColor",
      viewBox: viewbox,
      xmlns: "http://www.w3.org/2000/svg",
      **attributes
    }

    # Add aria-hidden unless explicitly overridden
    base_attributes["aria-hidden"] = "true" unless attributes.key?("aria-hidden") || attributes.key?(:"aria-label")

    base_attributes
  end

  def merged_classes
    size_classes = case size
    when :sm, :small
      "w-4 h-4"
    when :md, :medium
      "w-5 h-5"
    when :lg, :large
      "w-6 h-6"
    when :xl
      "w-8 h-8"
    else
      size.to_s
    end

    [ size_classes, @class ].compact.join(" ")
  end

  def viewbox
    "0 0 24 24"
  end
end
