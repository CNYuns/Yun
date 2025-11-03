axios.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
axios.defaults.timeout = 30000; // 30 second timeout

axios.interceptors.request.use(
    (config) => {
        if (config.data instanceof FormData) {
            config.headers['Content-Type'] = 'multipart/form-data';
        } else {
            config.data = Qs.stringify(config.data, {
                arrayFormat: 'repeat',
            });
        }
        return config;
    },
    (error) => {
        console.error('Request error:', error);
        return Promise.reject(error);
    },
);

axios.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response) {
            const statusCode = error.response.status;
            // Check the status code
            if (statusCode === 401) { // Unauthorized
                return window.location.reload();
            } else if (statusCode === 429) { // Too Many Requests
                const message = error.response.data?.msg || 'Too many requests. Please try again later.';
                if (typeof ant !== 'undefined' && ant.message) {
                    ant.message.error(message, 5);
                } else {
                    alert(message);
                }
            } else if (statusCode >= 500) { // Server Error
                const message = 'Server error. Please try again later.';
                if (typeof ant !== 'undefined' && ant.message) {
                    ant.message.error(message, 3);
                } else {
                    console.error(message, error);
                }
            } else if (statusCode === 403) { // Forbidden
                const message = 'Access denied.';
                if (typeof ant !== 'undefined' && ant.message) {
                    ant.message.warning(message, 3);
                }
            }
        } else if (error.request) {
            // Network error
            const message = 'Network error. Please check your connection.';
            if (typeof ant !== 'undefined' && ant.message) {
                ant.message.error(message, 3);
            } else {
                console.error('Network error:', error);
            }
        }
        return Promise.reject(error);
    }
);
