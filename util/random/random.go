package random

import (
	"crypto/rand"
	"math/big"
)

var (
	numSeq      [10]rune
	lowerSeq    [26]rune
	upperSeq    [26]rune
	numLowerSeq [36]rune
	numUpperSeq [36]rune
	allSeq      [62]rune
)

func init() {
	for i := 0; i < 10; i++ {
		numSeq[i] = rune('0' + i)
	}
	for i := 0; i < 26; i++ {
		lowerSeq[i] = rune('a' + i)
		upperSeq[i] = rune('A' + i)
	}

	copy(numLowerSeq[:], numSeq[:])
	copy(numLowerSeq[len(numSeq):], lowerSeq[:])

	copy(numUpperSeq[:], numSeq[:])
	copy(numUpperSeq[len(numSeq):], upperSeq[:])

	copy(allSeq[:], numSeq[:])
	copy(allSeq[len(numSeq):], lowerSeq[:])
	copy(allSeq[len(numSeq)+len(lowerSeq):], upperSeq[:])
}

// Seq generates a cryptographically secure random string of length n
// using crypto/rand instead of math/rand for better security
func Seq(n int) string {
	runes := make([]rune, n)
	for i := 0; i < n; i++ {
		randNum, err := rand.Int(rand.Reader, big.NewInt(int64(len(allSeq))))
		if err != nil {
			// Fallback: if crypto/rand fails, this is a critical error
			// In production, you might want to handle this differently
			panic("failed to generate random number: " + err.Error())
		}
		runes[i] = allSeq[randNum.Int64()]
	}
	return string(runes)
}

// Num generates a cryptographically secure random integer in range [0, n)
func Num(n int) int {
	randNum, err := rand.Int(rand.Reader, big.NewInt(int64(n)))
	if err != nil {
		panic("failed to generate random number: " + err.Error())
	}
	return int(randNum.Int64())
}

// StrongPassword generates a cryptographically secure strong password
// The password contains uppercase, lowercase, numbers and special characters
func StrongPassword(length int) string {
	if length < 12 {
		length = 12 // Minimum password length
	}

	// Define character sets
	lower := "abcdefghijklmnopqrstuvwxyz"
	upper := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	digits := "0123456789"
	special := "!@#$%^&*()-_=+[]{}|;:,.<>?"

	allChars := lower + upper + digits + special

	// Ensure at least one character from each set
	password := make([]byte, length)

	// Add one from each required set
	password[0] = lower[mustRandomInt(len(lower))]
	password[1] = upper[mustRandomInt(len(upper))]
	password[2] = digits[mustRandomInt(len(digits))]
	password[3] = special[mustRandomInt(len(special))]

	// Fill the rest with random characters from all sets
	for i := 4; i < length; i++ {
		password[i] = allChars[mustRandomInt(len(allChars))]
	}

	// Shuffle the password to avoid predictable patterns
	for i := length - 1; i > 0; i-- {
		j := mustRandomInt(i + 1)
		password[i], password[j] = password[j], password[i]
	}

	return string(password)
}

// mustRandomInt generates a random integer in [0, max)
// Panics on error (should never happen with crypto/rand)
func mustRandomInt(max int) int {
	n, err := rand.Int(rand.Reader, big.NewInt(int64(max)))
	if err != nil {
		panic("failed to generate random number: " + err.Error())
	}
	return int(n.Int64())
}
