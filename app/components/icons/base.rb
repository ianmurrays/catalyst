class Components::Icons::Base < Components::Base
  TAILWIND_MERGER = ::TailwindMerge::Merger.new.freeze

  def initialize(size: :md, **user_attrs)
    @size = size
    @attrs = mix(default_attrs, user_attrs)
    @attrs[:class] = TAILWIND_MERGER.merge(@attrs[:class]) if @attrs[:class]
  end

  private

  attr_reader :size, :attrs

  def svg_attributes
    base_attributes = mix(
      {
        fill: "currentColor",
        viewBox: viewbox,
        xmlns: "http://www.w3.org/2000/svg"
      },
      attrs
    )

    # Add aria-hidden unless explicitly overridden
    base_attributes["aria-hidden"] = "true" unless attrs.key?("aria-hidden") || attrs.key?(:"aria-label")

    base_attributes
  end

  def default_attrs
    { class: size_classes }
  end

  def size_classes
    case size
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
  end

  def viewbox
    "0 0 24 24"
  end

  def view_template
    svg(**svg_attributes) do |s|
      paths = svg_path
      if paths.is_a?(Array)
        paths.each { |path_attrs| s.path(**path_attrs) }
      else
        s.path(**paths)
      end
    end
  end

  # Subclasses must implement this method
  # Should return a hash of path attributes or an array of hashes for multiple paths
  def svg_path
    raise NotImplementedError, "#{self.class} must implement #svg_path"
  end
end
