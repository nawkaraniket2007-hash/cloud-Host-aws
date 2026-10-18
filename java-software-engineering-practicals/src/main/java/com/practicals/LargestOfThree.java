package com.practicals;

/**
 * Practical 3 — Largest of Three Numbers
 *
 * <p>Finds the largest of three integers.
 * Handles equal values, negative numbers, and mixed positive/negative inputs.
 */
public class LargestOfThree {

    /**
     * Returns the largest of three integers.
     *
     * <p>When two or more values are equal and jointly greatest, that value
     * is still returned — the method returns the maximum value, not its
     * position.
     *
     * @param a first integer
     * @param b second integer
     * @param c third integer
     * @return the largest value among {@code a}, {@code b}, and {@code c}
     */
    public static int findLargest(int a, int b, int c) {
        int largest = a;            // assume first is largest
        if (b > largest) {
            largest = b;            // second is larger
        }
        if (c > largest) {
            largest = c;            // third is larger
        }
        return largest;
    }

    /**
     * Console demonstration — not required for testing.
     */
    public static void main(String[] args) {
        System.out.println("Largest of 3, 7, 5  -> " + findLargest(3, 7, 5));
        System.out.println("Largest of -1, -5, -3 -> " + findLargest(-1, -5, -3));
        System.out.println("Largest of 4, 4, 4  -> " + findLargest(4, 4, 4));
    }
}
