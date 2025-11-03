package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type LoginAttempt struct {
	Count     int
	FirstTime time.Time
	BlockedUntil time.Time
}

type LoginRateLimiter struct {
	mu sync.RWMutex
	attempts map[string]*LoginAttempt

	maxAttempts   int
	window        time.Duration
	blockDuration time.Duration
}

func NewLoginRateLimiter(maxAttempts int, window time.Duration, blockDuration time.Duration) *LoginRateLimiter {
	limiter := &LoginRateLimiter{
		attempts:      make(map[string]*LoginAttempt),
		maxAttempts:   maxAttempts,
		window:        window,
		blockDuration: blockDuration,
	}

	// Start cleanup goroutine
	go limiter.cleanup()

	return limiter
}

func (l *LoginRateLimiter) cleanup() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		l.mu.Lock()
		now := time.Now()
		for ip, attempt := range l.attempts {
			// Remove old entries
			if now.Sub(attempt.FirstTime) > l.window && now.After(attempt.BlockedUntil) {
				delete(l.attempts, ip)
			}
		}
		l.mu.Unlock()
	}
}

func (l *LoginRateLimiter) IsBlocked(ip string) (bool, time.Duration) {
	l.mu.RLock()
	defer l.mu.RUnlock()

	if attempt, exists := l.attempts[ip]; exists {
		if time.Now().Before(attempt.BlockedUntil) {
			remaining := time.Until(attempt.BlockedUntil)
			return true, remaining
		}
	}
	return false, 0
}

func (l *LoginRateLimiter) RecordAttempt(ip string, success bool) {
	l.mu.Lock()
	defer l.mu.Unlock()

	now := time.Now()

	if success {
		// Clear attempts on successful login
		delete(l.attempts, ip)
		return
	}

	// Record failed attempt
	attempt, exists := l.attempts[ip]
	if !exists {
		l.attempts[ip] = &LoginAttempt{
			Count:     1,
			FirstTime: now,
		}
		return
	}

	// Reset if window expired
	if now.Sub(attempt.FirstTime) > l.window {
		attempt.Count = 1
		attempt.FirstTime = now
		attempt.BlockedUntil = time.Time{}
		return
	}

	// Increment attempt count
	attempt.Count++

	// Block if max attempts reached
	if attempt.Count >= l.maxAttempts {
		attempt.BlockedUntil = now.Add(l.blockDuration)
	}
}

// Middleware for rate limiting
func (l *LoginRateLimiter) Limit() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()

		if blocked, remaining := l.IsBlocked(ip); blocked {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"success": false,
				"msg":     "Too many login attempts. Please try again later.",
				"blocked_for": remaining.Seconds(),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
