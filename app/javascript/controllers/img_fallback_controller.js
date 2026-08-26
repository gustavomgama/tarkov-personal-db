import { Controller } from "@hotwired/stimulus"

// Hides external images that failed to load (dead wiki URLs, hotlink blocks).
export default class extends Controller {
  connect() {
    if (this.element.complete && this.element.naturalWidth === 0) {
      this.hide()
    }
    this.element.addEventListener("error", () => this.hide(), { once: true })
  }

  hide() {
    this.element.hidden = true
  }
}
