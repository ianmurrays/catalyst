import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timezone-detector"
export default class extends Controller {
  static targets = ["select", "searchInput", "suggestion", "optionsList", "template"]
  static values = { 
    detectedText: String, 
    useThisText: String, 
    dismissText: String 
  }
  
  connect() {
    this.detectTimezone()
    this.setupSearch()
    this.originalOptions = this.getAllOptions()
  }

  detectTimezone() {
    try {
      // Get browser's timezone
      const browserTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone
      
      // Try to map browser timezone to Rails timezone name
      const railsTimezone = this.mapBrowserTimezoneToRails(browserTimezone)
      
      if (railsTimezone && this.hasSelectTarget) {
        const currentValue = this.selectTarget.value
        
        // Only suggest if different from current selection and timezone is available
        if (currentValue !== railsTimezone && this.isTimezoneAvailable(railsTimezone)) {
          this.showSuggestion(railsTimezone, browserTimezone)
        }
      }
    } catch (error) {
      console.debug("Timezone detection failed:", error)
    }
  }

  setupSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.addEventListener('input', this.filterTimezones.bind(this))
    }
  }

  filterTimezones(event) {
    const searchTerm = event.target.value.toLowerCase()
    
    if (!this.hasSelectTarget) return
    
    const options = this.selectTarget.querySelectorAll('option')
    
    options.forEach(option => {
      const text = option.textContent.toLowerCase()
      const value = option.value.toLowerCase()
      const matches = text.includes(searchTerm) || value.includes(searchTerm)
      
      option.style.display = matches ? 'block' : 'none'
    })
  }

  clearSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
      this.showAllOptions()
    }
  }

  showAllOptions() {
    if (!this.hasSelectTarget) return
    
    const options = this.selectTarget.querySelectorAll('option')
    options.forEach(option => {
      option.style.display = 'block'
    })
  }

  acceptSuggestion(event) {
    const suggestedTimezone = event.currentTarget.dataset.timezone
    
    if (this.hasSelectTarget && this.isTimezoneAvailable(suggestedTimezone)) {
      this.selectTarget.value = suggestedTimezone
      this.hideSuggestion()
      
      // Dispatch change event to notify other controllers/form validation
      this.selectTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }
  }

  dismissSuggestion() {
    this.hideSuggestion()
  }

  // Private methods
  
  mapBrowserTimezoneToRails(browserTimezone) {
    // Common mappings from IANA timezone names to Rails-friendly names
    const timezoneMap = {
      'America/New_York': 'Eastern Time (US & Canada)',
      'America/Chicago': 'Central Time (US & Canada)',
      'America/Denver': 'Mountain Time (US & Canada)',
      'America/Los_Angeles': 'Pacific Time (US & Canada)',
      'America/Anchorage': 'Alaska',
      'Pacific/Honolulu': 'Hawaii',
      'Europe/London': 'London',
      'Europe/Paris': 'Paris',
      'Europe/Berlin': 'Berlin',
      'Europe/Rome': 'Rome',
      'Asia/Tokyo': 'Tokyo',
      'Asia/Shanghai': 'Beijing',
      'Australia/Sydney': 'Sydney',
      'Australia/Melbourne': 'Melbourne'
    }
    
    // First try direct mapping
    if (timezoneMap[browserTimezone]) {
      return timezoneMap[browserTimezone]
    }
    
    // For unmapped timezones, try to find a close match in the select options
    if (this.hasSelectTarget) {
      const options = Array.from(this.selectTarget.options)
      
      // Look for exact match first
      const exactMatch = options.find(option => 
        option.value === browserTimezone || 
        option.textContent.includes(browserTimezone.split('/')[1])
      )
      
      if (exactMatch) {
        return exactMatch.value
      }
    }
    
    // Fallback to the browser timezone itself if it's available
    return this.isTimezoneAvailable(browserTimezone) ? browserTimezone : null
  }

  isTimezoneAvailable(timezone) {
    if (!this.hasSelectTarget) return false
    
    const options = Array.from(this.selectTarget.options)
    return options.some(option => option.value === timezone)
  }

  showSuggestion(railsTimezone, browserTimezone) {
    if (!this.hasSuggestionTarget || !this.hasTemplateTarget) return
    
    // Clone the template content
    const templateClone = this.templateTarget.content.cloneNode(true)
    
    // Get translated text, replacing %{timezone} placeholder with the actual timezone
    const detectedText = this.detectedTextValue.replace('%{timezone}', `<strong>${railsTimezone}</strong>`)
    
    // Update dynamic content in the cloned template
    const detectedTextSpan = templateClone.querySelector('[data-timezone-detector-target="detectedText"]')
    if (detectedTextSpan) {
      detectedTextSpan.innerHTML = detectedText
    }
    
    const acceptButton = templateClone.querySelector('[data-timezone-detector-target="acceptButton"]')
    if (acceptButton) {
      acceptButton.textContent = this.useThisTextValue
      acceptButton.dataset.timezone = railsTimezone
    }
    
    const dismissButton = templateClone.querySelector('[data-timezone-detector-target="dismissButton"]')
    if (dismissButton) {
      dismissButton.textContent = this.dismissTextValue
    }
    
    // Clear existing content and append the cloned template
    this.suggestionTarget.innerHTML = ''
    this.suggestionTarget.appendChild(templateClone)
    this.suggestionTarget.classList.remove('hidden')
  }

  hideSuggestion() {
    if (this.hasSuggestionTarget) {
      this.suggestionTarget.classList.add('hidden')
      this.suggestionTarget.innerHTML = ''
    }
  }

  getAllOptions() {
    if (!this.hasSelectTarget) return []
    
    return Array.from(this.selectTarget.options).map(option => ({
      value: option.value,
      text: option.textContent,
      element: option
    }))
  }
}