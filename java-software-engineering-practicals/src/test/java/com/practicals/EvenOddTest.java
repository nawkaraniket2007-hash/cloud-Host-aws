package com.practicals;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * JUnit 5 test suite for {@link EvenOdd}.
 *
 * <p>Test categories:
 * <ul>
 *   <li>Zero</li>
 *   <li>Positive even numbers</li>
 *   <li>Positive odd numbers</li>
 *   <li>Negative even numbers</li>
 *   <li>Negative odd numbers</li>
 *   <li>Boundary values (Integer.MIN_VALUE, Integer.MAX_VALUE)</li>
 * </ul>
 */
@DisplayName("Practical 2 – Even or Odd Tests")
class EvenOddTest {

    // -----------------------------------------------------------------------
    // Zero
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("0 should be Even")
    void testZeroIsEven() {
        assertEquals("Even", EvenOdd.classify(0));
    }

    // -----------------------------------------------------------------------
    // Positive even numbers
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("2 should be Even")
    void testPositiveEven_2() {
        assertEquals("Even", EvenOdd.classify(2));
    }

    @Test
    @DisplayName("100 should be Even")
    void testPositiveEven_100() {
        assertEquals("Even", EvenOdd.classify(100));
    }

    @Test
    @DisplayName("1000000 should be Even")
    void testPositiveEven_large() {
        assertEquals("Even", EvenOdd.classify(1_000_000));
    }

    // -----------------------------------------------------------------------
    // Positive odd numbers
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("1 should be Odd")
    void testPositiveOdd_1() {
        assertEquals("Odd", EvenOdd.classify(1));
    }

    @Test
    @DisplayName("7 should be Odd")
    void testPositiveOdd_7() {
        assertEquals("Odd", EvenOdd.classify(7));
    }

    @Test
    @DisplayName("999 should be Odd")
    void testPositiveOdd_999() {
        assertEquals("Odd", EvenOdd.classify(999));
    }

    // -----------------------------------------------------------------------
    // Negative even numbers
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("-2 should be Even")
    void testNegativeEven_minus2() {
        assertEquals("Even", EvenOdd.classify(-2));
    }

    @Test
    @DisplayName("-100 should be Even")
    void testNegativeEven_minus100() {
        assertEquals("Even", EvenOdd.classify(-100));
    }

    // -----------------------------------------------------------------------
    // Negative odd numbers
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("-1 should be Odd")
    void testNegativeOdd_minus1() {
        assertEquals("Odd", EvenOdd.classify(-1));
    }

    @Test
    @DisplayName("-7 should be Odd")
    void testNegativeOdd_minus7() {
        assertEquals("Odd", EvenOdd.classify(-7));
    }

    // -----------------------------------------------------------------------
    // Boundary values
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Integer.MAX_VALUE (2147483647) should be Odd")
    void testMaxValueIsOdd() {
        assertEquals("Odd", EvenOdd.classify(Integer.MAX_VALUE));
    }

    @Test
    @DisplayName("Integer.MIN_VALUE (-2147483648) should be Even")
    void testMinValueIsEven() {
        assertEquals("Even", EvenOdd.classify(Integer.MIN_VALUE));
    }
}
