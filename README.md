# Spiral

## Installation

Check out the [documentation](https://bderenzo.github.io/spiral/docs.html) made using itself.

## Benchmark

With 200 posts of 100 lines each it take less than 15 seconds to generate.

```
$ ls ./bench/ | wc -l
200

$ cat ./bench/20200101_post1.md | wc -l
100

$ time ./generate.sh -p ./bench
+ collecting categories...
+ creating template...
+ creating posts...
[********************] 100%
+ creating categories...

real    0m14,449s
user    0m17,108s
sys     0m6,247s
```
