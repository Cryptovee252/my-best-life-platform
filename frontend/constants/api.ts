const rawBaseUrl = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:5000';

// Ensure we always hit the `/api` namespace exactly once
const API_BASE_URL = `${rawBaseUrl.replace(/\/$/, '')}/api`;

export { API_BASE_URL };
