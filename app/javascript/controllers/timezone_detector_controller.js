import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timezone-detector"
export default class extends Controller {
  static targets = ["select", "searchInput", "suggestion", "optionsList"]
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
    if (!this.hasSuggestionTarget) return
    
    // Get translated text, replacing %{timezone} placeholder with the actual timezone
    const detectedText = this.detectedTextValue.replace('%{timezone}', `<strong>${railsTimezone}</strong>`)
    
    // Create suggestion HTML
    const suggestionHTML = `
      <div class="flex items-center justify-between p-3 bg-muted border border-border rounded-md">
        <div class="flex items-center space-x-2">
          <svg class="w-4 h-4 text-muted-foreground" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path>
          </svg>
          <span class="text-sm text-foreground">
            ${detectedText}
          </span>
        </div>
        <div class="flex space-x-2">
          <button type="button" 
                  data-action="click->timezone-detector#acceptSuggestion" 
                  data-timezone="${railsTimezone}"
                  class="text-sm text-primary hover:text-primary/80 font-medium">
            ${this.useThisTextValue}
          </button>
          <button type="button" 
                  data-action="click->timezone-detector#dismissSuggestion"
                  class="text-sm text-muted-foreground hover:text-foreground">
            ${this.dismissTextValue}
          </button>
        </div>
      </div>
    `
    
    this.suggestionTarget.innerHTML = suggestionHTML
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