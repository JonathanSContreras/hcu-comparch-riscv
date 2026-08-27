/* lab05/compute.c — small C functions, written to be read as assembly.
 *
 * You are not going to run this file. You are going to compile it to
 * assembly with `make cbuild` and read what the compiler produced.
 *
 * Each function is here because it turns into something worth looking at.
 * Keep them small; the point is to be able to hold the whole translation in
 * your head at once.
 */

/* Leaf, no memory access. Should become three or four instructions. */
long add_two(long a, long b)
{
    return a + b;
}

/* A loop. Find the backward branch. */
long sum_to(long n)
{
    long total = 0;
    for (long i = 1; i <= n; i++)
        total += i;
    return total;
}

/* Recursion. This one must build a stack frame -- find the prologue. */
long fact(long n)
{
    if (n <= 1)
        return 1;
    return n * fact(n - 1);
}

/* Array walk. Watch how the compiler steps the pointer. */
long largest(const long *values, long count)
{
    long best = values[0];
    for (long i = 1; i < count; i++)
        if (values[i] > best)
            best = values[i];
    return best;
}

/* Multiplication and division by constant powers of two. The compiler will
 * not emit mul or div here. Work out what it does instead. */
long scale(long x)
{
    return (x * 8) / 4;
}
