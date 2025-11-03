package crypto

import (
	"golang.org/x/crypto/bcrypt"
)

const (
	// Use cost factor of 12 for better security (default is 10)
	// This increases password hashing time to make brute-force attacks more difficult
	bcryptCost = 12
)

func HashPasswordAsBcrypt(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	return string(hash), err
}

func CheckPasswordHash(hash, password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
