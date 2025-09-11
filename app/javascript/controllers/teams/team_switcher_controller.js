// app/javascript/controllers/teams/team_switcher_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "loading", "currentTeamName", "input"]
  static outlets = ["ruby-ui--select-item"]
  static values = { 
    currentTeam: String,
    switchUrl: String,
    teamsMapping: Object
  }

  connect() {
    // Listen for Turbo events
    document.addEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    document.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  // Stimulus outlet callback - called when a SelectItem connects
  rubyUiSelectItemOutletConnected(outlet, element) {
    element.addEventListener("click", this.handleSelectItemClick.bind(this))
  }

  // Stimulus outlet callback - called when a SelectItem disconnects  
  rubyUiSelectItemOutletDisconnected(outlet, element) {
    element.removeEventListener("click", this.handleSelectItemClick.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    document.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  handleSelectItemClick(event) {
    const selectedTeamId = event.currentTarget.dataset.value
    const teamName = this.teamsMappingValue[selectedTeamId] || event.currentTarget.dataset.teamName || 'Unknown Team'
    
    if (selectedTeamId && selectedTeamId !== this.currentTeamValue) {
      this.switchToTeam(selectedTeamId, teamName)
    }
  }

  async switchToTeam(teamId, teamName) {
    try {
      this.showLoading()
      
      const response = await fetch(this.buildSwitchUrl(teamId), {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ 
          team_id: teamId,
          return_to: window.location.pathname
        })
      })

      if (response.ok) {
        const data = await response.json()
        this.handleSwitchSuccess(data, teamName)
      } else {
        const error = await response.json()
        this.handleSwitchError(error)
      }
    } catch (error) {
      this.handleSwitchError({ error: "Network error occurred" })
    }
  }

  handleSwitchSuccess(data, teamName) {
    this.hideLoading()
    this.currentTeamValue = data.team.id
    
    // Update the displayed team name
    if (this.hasCurrentTeamNameTarget) {
      this.currentTeamNameTarget.textContent = teamName
    }
    
    // Show success notification
    this.showSuccessNotification(teamName)
    
    // Refresh the page to update team context
    // Could be enhanced to use Turbo for partial updates
    setTimeout(() => {
      window.location.reload()
    }, 500)
  }

  handleSwitchError(error) {
    this.hideLoading()
    
    // Reset the select to current team
    const select = this.element.querySelector('select, input[name="team_id"]')
    if (select) {
      select.value = this.currentTeamValue
    }
    
    // Show error notification
    this.showErrorNotification(error.error || "Failed to switch teams")
  }

  handleSubmitStart(event) {
    if (this.element.contains(event.target)) {
      this.showLoading()
    }
  }

  handleSubmitEnd(event) {
    if (this.element.contains(event.target)) {
      this.hideLoading()
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
    
    if (this.hasTriggerTarget) {
      this.triggerTarget.disabled = true
      this.triggerTarget.classList.add("opacity-50")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
    
    if (this.hasTriggerTarget) {
      this.triggerTarget.disabled = false
      this.triggerTarget.classList.remove("opacity-50")
    }
  }

  buildSwitchUrl(teamId) {
    return this.switchUrlValue.replace(':team_id', teamId)
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  showSuccessNotification(teamName) {
    const message = `Switched to ${teamName}`
    this.showNotification(message, 'success')
  }

  showErrorNotification(message) {
    this.showNotification(message, 'error')
  }

  showNotification(message, type) {
    // Simple implementation - could be enhanced with toast component
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 p-4 rounded-md shadow-lg z-50 ${
      type === 'success' ? 'bg-green-600 text-white' : 'bg-red-600 text-white'
    }`
    notification.textContent = message
    
    document.body.appendChild(notification)
    
    setTimeout(() => {
      notification.remove()
    }, 3000)
  }
}