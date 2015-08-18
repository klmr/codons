# Implement various helpers to normalise data.
# All these functions expect tidy data.
# TODO: All functions require documentation.

transform_counts = function (counts, fs, ...)
    dplyr::mutate_each_(counts, dplyr::funs_(lazyeval::lazy(fs)),
                        dplyr:::dots(...))

fpkm = function (counts, transcript_lengths)
    exp(log(counts) - log(transcript_lengths) - log(sum(counts)) + log(1e9))

tpm = function (counts, transcript_lengths) {
    rate = log(counts) - log(transcript_lengths)
    exp(rate - log(sum(exp(rate))) + log(1E6))
}

size_factors = function (counts) {
    log_counts = log(counts)
    log_means = rowMeans(log_counts)
    finite = ! is.infinite(log_means)
    dplyr::summarise_each(log_counts,
                          dplyr::funs(exp(median((. - log_means)[finite]))))
}
