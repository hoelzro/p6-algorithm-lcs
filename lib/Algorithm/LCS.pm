module Algorithm::LCS:ver<0.0.1>:auth<hoelzro> {
    my sub strip-prefix(@a, @b, &compare-i) {
        my $i = 0;
        my @prefix;

        while $i < (@a&@b) && &compare-i($i, $i) {
            @prefix.push: @a[$i++];
        }

        @prefix
    }

    my sub strip-suffix(@a, @b, &compare-i) {
        # XXX could be optimized, but this is easy for now
        strip-prefix(@a.reverse, @b.reverse, -> $i, $j {
            &compare-i(@a.end - $i, @b.end - $j)
        }).reverse
    }

    my sub build-lcs-matrix(@a, @b, &compare-i) {
        my @matrix  = 0 xx ((@a + 1) * (@b + 1));
        my $row-len = @a + 1;

        for 1 .. @b X 1 .. @a -> $row, $offset {
            my $index = $row * $row-len + $offset;

            if &compare-i($offset - 1, $row - 1) {
                @matrix[$index] = @matrix[$index - $row-len - 1] + 1;
            } else {
                @matrix[$index] = [max] @matrix[ $index - $row-len, $index - 1 ];
            }
        }

        @matrix
    }

    our sub lcs(@a, @b, :&compare=&infix:<eqv>, :&compare-i is copy) is export {
        unless &compare-i.defined {
            &compare-i = -> $i, $j {
                &compare(@a[$i], @b[$j])
            };
        }

        my @prefix = strip-prefix(@a, @b, &compare-i);
        my @suffix = strip-suffix(@a[+@prefix .. *], @b[+@prefix .. *], -> $i, $j {
            &compare-i($i + @prefix, $j + @prefix)
        });
        my @a-middle = @a[+@prefix .. @a.end - @suffix];
        my @b-middle = @b[+@prefix .. @b.end - @suffix];

        if @a-middle && @b-middle {
            my @matrix = build-lcs-matrix(@a-middle, @b-middle, -> $i, $j {
                &compare-i($i + @prefix, $j + @prefix)
            });

            my $matrix-row-len = @a-middle + 1;
            my $i = @matrix.end;

            my @result := gather while $i > 0 && @matrix[$i] > 0 {
                my $current-length  = @matrix[$i];
                my $next-row-length = @matrix[$i - $matrix-row-len];
                my $next-col-length = @matrix[$i - 1];

                if $current-length > $next-row-length && $next-row-length == $next-col-length {
                    take @b-middle[$i div $matrix-row-len - 1];
                    $i -= $matrix-row-len + 1;
                } elsif $next-row-length < $next-col-length {
                    $i--;
                } elsif $next-col-length <= $next-row-length {
                    $i -= $matrix-row-len;
                } else {
                    die "this should never be reached!";
                }
            };

            ( @prefix, @result.reverse, @suffix ).flat
        } else {
            ( @prefix, @suffix ).flat
        }
    }
}
