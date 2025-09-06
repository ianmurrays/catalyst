class Components::Icons::Check < Components::Icons::Base
  def view_template
    svg(**svg_attributes) do |s|
      s.path(
        fill_rule: "evenodd",
        d: "M19.916 4.626a.75.75 0 01.208 1.04l-9 13.5a.75.75 0 01-1.154.114l-6-6a.75.75 0 011.06-1.06l5.353 5.353 8.493-12.739a.75.75 0 011.04-.208z",
        clip_rule: "evenodd"
      )
    end
  end
end
