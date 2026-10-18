package com.practicals;

/**
 * Practical 5 — Positive, Negative, or Zero
 *
 * <p>Classifies an integer as Positive, Negative, or Zero.
 */
public class NumberSign {

    /**
     * Classifies the given integer.
     *
     * @param n the integer to classify
     * @return {@code "Positive"} if {@code n > 0},
     *         {@code "Negative"} if {@code n < 0},
     *         {@code "Zero"}     if {@code n == 0}
     */
    public static String classify(int n) {
        if (n > 0) {
            return "Positive";
        } else if (n < 0) {
            return "Negative";
        } else {
            return "Zero";
        }
    }

    /**
     * Console demonstration — not required for testing.
     */
    public static void main(String[] args) {
        int[] samples = {0, 42, -7, Integer.MAX_VALUE, Integer.MIN_VALUE};
        for (int n : samples) {
            System.out.printf("%d -> %s%n", n, classify(n));
        }
    }
}
