import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger"]

  open() {
    // Programmatically click the hidden sheet trigger
    if (this.triggerTarget) {
      this.triggerTarget.click()
    }
  }

  close() {
    // Find and click the sheet close button
    const closeButton = document.querySelector('[data-action*="ruby-ui--sheet-content#close"]')
    if (closeButton) {
      closeButton.click()
    }
  }

  // Close menu when escape key is pressed
  keydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  connect() {
    // Listen for escape key globally when menu might be open
    document.addEventListener("keydown", this.keydown.bind(this))
  }

  disconnect() {
    // Clean up event listener
    document.removeEventListener("keydown", this.keydown.bind(this))
  }
}