import { Controller } from "@hotwired/stimulus"

export default class ThemeController extends Controller {
  static targets = ["sun", "moon"]

  connect() {
    this.#applyThemeFromStorage()
  }

  toggle() {
    const html = document.documentElement
    const isDark = html.classList.contains("dark")

    if (isDark) {
      html.classList.remove("dark")
      html.classList.add("light")
      localStorage.setItem("theme", "light")
    } else {
      html.classList.remove("light")
      html.classList.add("dark")
      localStorage.setItem("theme", "dark")
    }
  }

  #applyThemeFromStorage() {
    const theme = localStorage.getItem("theme")
    const html = document.documentElement

    if (theme === "light") {
      html.classList.remove("dark")
      html.classList.add("light")
    } else if (theme === "dark" || !theme) {
      html.classList.remove("light")
      html.classList.add("dark")
    }
  }
}
