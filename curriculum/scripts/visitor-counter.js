/**
 * Visitor Counter Script
 * ======================
 * 
 * This script handles the visitor counter functionality for the Cloud CV.
 * It communicates with the AWS Lambda function through API Gateway.
 */

// API Configuration
// This will be replaced by the actual API endpoint after Terraform deployment
const API_ENDPOINT = window.API_ENDPOINT || 'https://YOUR_API_ID.execute-api.eu-west-1.amazonaws.com';
const VISITS_URL = `${API_ENDPOINT}/visits`;

/**
 * Display the visitor count on the page
 * @param {Object} data - Visit data from the API
 */
function displayVisitCount(data) {
    const counterElement = document.getElementById('visitor-count');
    if (!counterElement) return;

    const totalVisits = data.total_visits || 0;
    const uniqueVisitors = data.unique_visitors || 0;
    const yourVisits = data.visitor_visits || 0;

    counterElement.innerHTML = `
        👁️ <strong>${totalVisits}</strong> visitas totales | 
        👥 <strong>${uniqueVisitors}</strong> visitantes únicos | 
        🎯 Tú: <strong>${yourVisits}</strong> visitas
    `;
}

/**
 * Display error message
 * @param {string} message - Error message to display
 */
function displayError(message) {
    const counterElement = document.getElementById('visitor-count');
    if (!counterElement) return;

    counterElement.innerHTML = `⚠️ ${message}`;
    counterElement.style.backgroundColor = '#ef4444';
}

/**
 * Register a new visit
 */
async function registerVisit() {
    try {
        const response = await fetch(VISITS_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        displayVisitCount(data);
        
        console.log('Visit registered:', data);
    } catch (error) {
        console.error('Error registering visit:', error);
        // Try to at least get the current count
        getVisitCount();
    }
}

/**
 * Get current visit count without registering a new visit
 */
async function getVisitCount() {
    try {
        const response = await fetch(VISITS_URL, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        displayVisitCount(data);
        
        console.log('Visit count retrieved:', data);
    } catch (error) {
        console.error('Error getting visit count:', error);
        displayError('No se pudo cargar el contador');
    }
}

/**
 * Check if this is a new session
 * Uses sessionStorage to avoid counting multiple page loads as visits
 */
function isNewSession() {
    const visited = sessionStorage.getItem('cv_visited');
    if (!visited) {
        sessionStorage.setItem('cv_visited', 'true');
        return true;
    }
    return false;
}

/**
 * Initialize the visitor counter
 */
function initVisitorCounter() {
    // Check if API endpoint is configured
    if (VISITS_URL.includes('YOUR_API_ID')) {
        const counterElement = document.getElementById('visitor-count');
        if (counterElement) {
            counterElement.innerHTML = '🔧 API no configurada - Despliega con Terraform primero';
        }
        console.warn('API endpoint not configured. Please deploy infrastructure first.');
        return;
    }

    // Register visit only for new sessions
    if (isNewSession()) {
        registerVisit();
    } else {
        // Just get the count for returning sessions
        getVisitCount();
    }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initVisitorCounter);
} else {
    initVisitorCounter();
}

// Export for testing (if using modules)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        displayVisitCount,
        displayError,
        registerVisit,
        getVisitCount,
        isNewSession,
        initVisitorCounter
    };
}
