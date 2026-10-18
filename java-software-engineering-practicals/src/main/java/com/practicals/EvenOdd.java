package com.practicals;

/**
 * Practical 2 — Even or Odd
 *
 * <p>Determines whether an integer is even or odd.
 * Works correctly for positive, negative, and zero values.
 */
public class EvenOdd {

    /**
     * Checks whether the given integer is even.
     *
     * <p>Uses {@code n % 2 == 0}.  Java's {@code %} operator preserves the sign
     * of the dividend, so {@code -4 % 2} is {@code 0} and {@code -3 % 2} is
     * {@code -1}, both of which are handled correctly here.
     *
     * @param n the integer to check
     * @return {@code "Even"} if {@code n} is even, {@code "Odd"} otherwise
     */
    public static String classify(int n) {
        if (n % 2 == 0) {
            return "Even";
        }
        return "Odd";
    }

    /**
     * Console demonstration — not required for testing.
     */
    public static void main(String[] args) {
        int[] samples = {0, 1, -2, -7, 100, Integer.MAX_VALUE};
        for (int n : samples) {
            System.out.printf("%d -> %s%n", n, classify(n));
        }
    }
}
