// Browser Compatibility Script
// Ensures compatibility across all browsers including Safari

(function() {
    'use strict';
    
    console.log('🌐 Browser compatibility script loaded');
    
    // Check if required features are available
    function checkCompatibility() {
        const issues = [];
        
        // Check localStorage
        if (typeof Storage === 'undefined') {
            issues.push('localStorage not supported');
        }
        
        // Check fetch API
        if (typeof fetch === 'undefined') {
            issues.push('fetch API not supported');
        }
        
        // Check Promise
        if (typeof Promise === 'undefined') {
            issues.push('Promise not supported');
        }
        
        // Check JSON
        if (typeof JSON === 'undefined') {
            issues.push('JSON not supported');
        }
        
        if (issues.length > 0) {
            console.error('❌ Compatibility issues found:', issues);
            showCompatibilityError(issues);
            return false;
        }
        
        console.log('✅ Browser compatibility check passed');
        return true;
    }
    
    // Show compatibility error
    function showCompatibilityError(issues) {
        const errorDiv = document.createElement('div');
        errorDiv.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            background: #ff4444;
            color: white;
            padding: 10px;
            text-align: center;
            z-index: 10000;
            font-family: Arial, sans-serif;
        `;
        errorDiv.innerHTML = `
            <strong>Browser Compatibility Issue:</strong> 
            Your browser doesn't support required features: ${issues.join(', ')}. 
            Please use a modern browser like Chrome, Firefox, Safari, or Edge.
        `;
        document.body.appendChild(errorDiv);
    }
    
    // Enhanced fetch with better error handling
    if (typeof fetch !== 'undefined') {
        const originalFetch = window.fetch;
        window.fetch = function(url, options = {}) {
            // Add default headers for better compatibility
            const defaultOptions = {
                credentials: 'include',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                ...options
            };
            
            return originalFetch(url, defaultOptions)
                .then(response => {
                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }
                    return response;
                })
                .catch(error => {
                    console.error('Fetch error:', error);
                    throw error;
                });
        };
    }
    
    // Enhanced localStorage with error handling
    const storage = {
        setItem: function(key, value) {
            try {
                localStorage.setItem(key, value);
            } catch (error) {
                console.error('localStorage setItem error:', error);
            }
        },
        getItem: function(key) {
            try {
                return localStorage.getItem(key);
            } catch (error) {
                console.error('localStorage getItem error:', error);
                return null;
            }
        },
        removeItem: function(key) {
            try {
                localStorage.removeItem(key);
            } catch (error) {
                console.error('localStorage removeItem error:', error);
            }
        }
    };
    
    // Make storage available globally
    window.storage = storage;
    
    // Check compatibility on load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', checkCompatibility);
    } else {
        checkCompatibility();
    }
    
    console.log('🌐 Browser compatibility setup complete');
})();
