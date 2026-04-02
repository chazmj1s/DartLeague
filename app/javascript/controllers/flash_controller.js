// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

// Automatically fades out and removes flash messages after a short delay.
export default class extends Controller {
  connect() {
    // Slide in
    this.element.style.transform = "translateY(-100%)"
    this.element.style.transition = "transform 0.25s ease"
    requestAnimationFrame(() => {
      this.element.style.transform = "translateY(0)"
    })

    // Auto-dismiss after 3 seconds
    this.timeout = setTimeout(() => this.dismiss(), 3000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.transition = "opacity 0.4s ease, transform 0.4s ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-100%)"
    setTimeout(() => this.element.remove(), 400)
  }
}
