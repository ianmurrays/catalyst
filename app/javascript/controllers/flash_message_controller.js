import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash-message"
export default class extends Controller {
  dismiss() {
    // Add a smooth fade-out animation before removing
    this.element.style.transition = "opacity 0.3s ease-out"
    this.element.style.opacity = "0"
    
    // Remove the element after animation completes
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}