import { Controller } from "@hotwired/stimulus"

// Submits the enclosing filter form when any select/checkbox changes.
// Text inputs submit natively on Enter or via the Filter button, so typing
// is never interrupted.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
