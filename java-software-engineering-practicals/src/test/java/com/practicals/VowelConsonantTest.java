package com.practicals;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * JUnit 5 test suite for {@link VowelConsonant}.
 *
 * <p>Test categories:
 * <ul>
 *   <li>Lowercase vowels</li>
 *   <li>Uppercase vowels</li>
 *   <li>Lowercase consonants</li>
 *   <li>Uppercase consonants</li>
 *   <li>Non-alphabetic / invalid characters</li>
 * </ul>
 */
@DisplayName("Practical 1 – Vowel or Consonant Tests")
class VowelConsonantTest {

    // -----------------------------------------------------------------------
    // Lowercase vowels
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Lowercase 'a' should be Vowel")
    void testLowercaseA() {
        assertEquals("Vowel", VowelConsonant.classify('a'));
    }

    @Test
    @DisplayName("Lowercase 'e' should be Vowel")
    void testLowercaseE() {
        assertEquals("Vowel", VowelConsonant.classify('e'));
    }

    @Test
    @DisplayName("Lowercase 'i' should be Vowel")
    void testLowercaseI() {
        assertEquals("Vowel", VowelConsonant.classify('i'));
    }

    @Test
    @DisplayName("Lowercase 'o' should be Vowel")
    void testLowercaseO() {
        assertEquals("Vowel", VowelConsonant.classify('o'));
    }

    @Test
    @DisplayName("Lowercase 'u' should be Vowel")
    void testLowercaseU() {
        assertEquals("Vowel", VowelConsonant.classify('u'));
    }

    // -----------------------------------------------------------------------
    // Uppercase vowels
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Uppercase 'A' should be Vowel")
    void testUppercaseA() {
        assertEquals("Vowel", VowelConsonant.classify('A'));
    }

    @Test
    @DisplayName("Uppercase 'E' should be Vowel")
    void testUppercaseE() {
        assertEquals("Vowel", VowelConsonant.classify('E'));
    }

    @Test
    @DisplayName("Uppercase 'I' should be Vowel")
    void testUppercaseI() {
        assertEquals("Vowel", VowelConsonant.classify('I'));
    }

    @Test
    @DisplayName("Uppercase 'O' should be Vowel")
    void testUppercaseO() {
        assertEquals("Vowel", VowelConsonant.classify('O'));
    }

    @Test
    @DisplayName("Uppercase 'U' should be Vowel")
    void testUppercaseU() {
        assertEquals("Vowel", VowelConsonant.classify('U'));
    }

    // -----------------------------------------------------------------------
    // Consonants (lowercase)
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Lowercase 'b' should be Consonant")
    void testLowercaseB() {
        assertEquals("Consonant", VowelConsonant.classify('b'));
    }

    @Test
    @DisplayName("Lowercase 'z' should be Consonant")
    void testLowercaseZ() {
        assertEquals("Consonant", VowelConsonant.classify('z'));
    }

    @Test
    @DisplayName("Lowercase 's' should be Consonant")
    void testLowercaseS() {
        assertEquals("Consonant", VowelConsonant.classify('s'));
    }

    // -----------------------------------------------------------------------
    // Consonants (uppercase)
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Uppercase 'B' should be Consonant")
    void testUppercaseB() {
        assertEquals("Consonant", VowelConsonant.classify('B'));
    }

    @Test
    @DisplayName("Uppercase 'Z' should be Consonant")
    void testUppercaseZ() {
        assertEquals("Consonant", VowelConsonant.classify('Z'));
    }

    // -----------------------------------------------------------------------
    // Invalid / non-alphabetic input
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Digit '3' should throw IllegalArgumentException")
    void testDigitThrows() {
        assertThrows(IllegalArgumentException.class,
            () -> VowelConsonant.classify('3'));
    }

    @Test
    @DisplayName("Symbol '!' should throw IllegalArgumentException")
    void testSymbolThrows() {
        assertThrows(IllegalArgumentException.class,
            () -> VowelConsonant.classify('!'));
    }

    @Test
    @DisplayName("Space ' ' should throw IllegalArgumentException")
    void testSpaceThrows() {
        assertThrows(IllegalArgumentException.class,
            () -> VowelConsonant.classify(' '));
    }
}
