package com.practicals;

/**
 * Practical 4 — Factorial
 *
 * <p>Calculates the factorial of a non-negative integer using {@code long}.
 *
 * <h3>Range of {@code long}</h3>
 * A Java {@code long} is a 64-bit signed integer.  The largest factorial that
 * fits without overflow is <b>20! = 2,432,902,008,176,640,000</b>.
 * Inputs greater than 20 cause silent overflow in a plain multiplication loop;
 * this implementation detects that and throws {@link ArithmeticException}.
 *
 * <h3>Valid input range</h3>
 * <ul>
 *   <li>0 through 20 (inclusive) — exact results returned as {@code long}.</li>
 *   <li>Negative integers — rejected with {@link IllegalArgumentException}.</li>
 *   <li>Integers greater than 20 — rejected with {@link ArithmeticException}.</li>
 * </ul>
 */
public class Factorial {

    /** The largest {@code n} for which {@code n!} fits in a {@code long}. */
    public static final int MAX_SUPPORTED_N = 20;

    /**
     * Computes {@code n!} (n factorial).
     *
     * @param n a non-negative integer, 0 ≤ n ≤ {@value #MAX_SUPPORTED_N}
     * @return n!
     * @throws IllegalArgumentException if {@code n} is negative
     * @throws ArithmeticException      if {@code n} > {@value #MAX_SUPPORTED_N}
     *                                  (result would overflow {@code long})
     */
    public static long compute(int n) {
        if (n < 0) {
            throw new IllegalArgumentException(
                "Factorial is not defined for negative numbers. Received: " + n);
        }
        if (n > MAX_SUPPORTED_N) {
            throw new ArithmeticException(
                n + "! overflows long. Maximum supported input is " + MAX_SUPPORTED_N + ".");
        }

        long result = 1L;
        for (int i = 2; i <= n; i++) {
            result *= i;
        }
        return result;
    }

    /**
     * Console demonstration — not required for testing.
     */
    public static void main(String[] args) {
        int[] samples = {0, 1, 5, 10, 20};
        for (int n : samples) {
            System.out.printf("%d! = %d%n", n, compute(n));
        }

        // Demonstrate exception for negative input
        try {
            compute(-1);
        } catch (IllegalArgumentException e) {
            System.out.println("compute(-1) -> " + e.getMessage());
        }

        // Demonstrate exception for overflow input
        try {
            compute(21);
        } catch (ArithmeticException e) {
            System.out.println("compute(21) -> " + e.getMessage());
        }
    }
}
