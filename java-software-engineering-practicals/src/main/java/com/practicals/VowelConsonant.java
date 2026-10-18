package com.practicals;

/**
 * Practical 1 — Vowel or Consonant
 *
 * <p>Checks whether a given character is a vowel or consonant.
 * Handles both uppercase and lowercase letters.
 * Throws {@link IllegalArgumentException} for non-alphabetic input.
 */
public class VowelConsonant {

    /**
     * Classifies the given character.
     *
     * @param ch the character to classify
     * @return {@code "Vowel"} if {@code ch} is a vowel,
     *         {@code "Consonant"} if {@code ch} is a consonant
     * @throws IllegalArgumentException if {@code ch} is not an English letter
     */
    public static String classify(char ch) {
        // Reject anything that is not an English letter
        if (!Character.isLetter(ch)) {
            throw new IllegalArgumentException(
                "Input '" + ch + "' is not an alphabetic character.");
        }

        // Convert to lowercase for a uniform vowel check
        char lower = Character.toLowerCase(ch);

        // The five English vowels
        if (lower == 'a' || lower == 'e' || lower == 'i'
                || lower == 'o' || lower == 'u') {
            return "Vowel";
        }

        return "Consonant";
    }

    /**
     * Console demonstration — not required for testing.
     */
    public static void main(String[] args) {
        char[] samples = {'a', 'E', 'b', 'Z', '3', '!'};
        for (char c : samples) {
            try {
                System.out.printf("'%c' -> %s%n", c, classify(c));
            } catch (IllegalArgumentException e) {
                System.out.printf("'%c' -> Invalid: %s%n", c, e.getMessage());
            }
        }
    }
}
