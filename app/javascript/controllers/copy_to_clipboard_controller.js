import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="copy-to-clipboard"
export default class extends Controller {
  static values = {
    text: String
  }

  async copy() {
    try {
      const text = this.textValue || this.element.dataset.copyToClipboardText
      if (!text) return

      await navigator.clipboard.writeText(text)

      // Provide lightweight success feedback
      this.flash("Copied!")
    } catch (e) {
      console.error("Copy failed:", e)
      this.flash("Copy failed")
    }
  }

  flash(message) {
    // Create a transient toast-like element
    const toast = document.createElement("div")
    toast.textContent = message
    toast.className = "fixed bottom-4 right-4 z-50 rounded bg-gray-900 px-3 py-2 text-sm text-white opacity-90 shadow"

    document.body.appendChild(toast)

    setTimeout(() => {
      toast.style.transition = "opacity 250ms ease-out"
      toast.style.opacity = "0"
      setTimeout(() => toast.remove(), 250)
    }, 900)
  }
}
