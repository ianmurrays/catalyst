class Components::Icons::ChevronDown < Components::Icons::Base
  def view_template
    svg(**svg_attributes) do |s|
      s.path(
        fill_rule: "evenodd",
        d: "M5.23 7.21a.75.75 0 011.06.02L12 13.939l5.71-6.719a.75.75 0 111.08 1.04l-6.25 7.5a.75.75 0 01-1.08 0l-6.25-7.5a.75.75 0 01.02-1.06z",
        clip_rule: "evenodd"
      )
    end
  end
end
