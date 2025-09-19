// Enhanced Login Form Component
// Compatible with all browsers

import React, { useState, useEffect } from 'react';

const EnhancedLoginForm = ({ onLoginSuccess, onSwitchToRegister }) => {
    const [formData, setFormData] = useState({
        email: '',
        password: ''
    });
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [isButtonDisabled, setIsButtonDisabled] = useState(false);

    // Handle input changes
    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
        
        // Clear error when user starts typing
        if (error) {
            setError('');
        }
    };

    // Handle form submission
    const handleSubmit = async (e) => {
        e.preventDefault();
        
        // Prevent multiple submissions
        if (isLoading || isButtonDisabled) {
            return;
        }

        // Validate form
        if (!formData.email || !formData.password) {
            setError('Please fill in all fields');
            return;
        }

        setIsLoading(true);
        setIsButtonDisabled(true);
        setError('');

        try {
            console.log('🔐 Submitting login form...');
            
            // Use the global auth service
            const result = await window.authService.login(formData.email, formData.password);
            
            if (result.success) {
                console.log('✅ Login successful');
                onLoginSuccess(result.user);
            } else {
                setError(result.error || 'Login failed');
            }
        } catch (error) {
            console.error('❌ Login error:', error);
            setError('An error occurred. Please try again.');
        } finally {
            setIsLoading(false);
            // Re-enable button after a short delay
            setTimeout(() => {
                setIsButtonDisabled(false);
            }, 1000);
        }
    };

    // Handle button click with additional validation
    const handleButtonClick = (e) => {
        e.preventDefault();
        
        if (isButtonDisabled) {
            console.log('⚠️ Button disabled, ignoring click');
            return;
        }
        
        handleSubmit(e);
    };

    return (
        <form onSubmit={handleSubmit} className="login-form">
            <div className="form-group">
                <label htmlFor="email">Email</label>
                <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    required
                    autoComplete="email"
                    disabled={isLoading}
                />
            </div>
            
            <div className="form-group">
                <label htmlFor="password">Password</label>
                <input
                    type="password"
                    id="password"
                    name="password"
                    value={formData.password}
                    onChange={handleInputChange}
                    required
                    autoComplete="current-password"
                    disabled={isLoading}
                />
            </div>
            
            {error && (
                <div className="error-message">
                    {error}
                </div>
            )}
            
            <button
                type="submit"
                onClick={handleButtonClick}
                disabled={isLoading || isButtonDisabled}
                className={`login-button ${isLoading ? 'loading' : ''}`}
            >
                {isLoading ? 'Logging in...' : 'Login'}
            </button>
            
            <div className="form-footer">
                <p>Don't have an account? 
                    <button 
                        type="button" 
                        onClick={onSwitchToRegister}
                        className="link-button"
                    >
                        Register here
                    </button>
                </p>
            </div>
        </form>
    );
};

export default EnhancedLoginForm;
