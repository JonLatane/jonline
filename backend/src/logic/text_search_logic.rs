// Turns free-form user search input into a tsquery string matching any lexeme that *starts with*
// any of its whitespace-separated words (AND'd together) via Postgres's `:*` prefix-match
// operator - e.g. "bob" -> `bob:*`, matching a username like "bobothy" too (or, for Posts, a
// title word like "xylophonecollector" for a search of "xylophone"), not just an exact/stemmed
// "bob"/"xylophone" lexeme (which is all `websearch_to_tsquery` would match - see
// `rpcs::posts::get_posts::get_search_posts`/`rpcs::users::get_users::get_all_users` and
// friends). Shared by both, so the two full-text searches stay consistent rather than drifting.
//
// Only alphanumeric runs are kept from each word (a word that's nothing else is dropped
// entirely) so user input can never inject tsquery syntax (`&`, `|`, `:`, `(`, `)`, quotes, etc.)
// into the query text passed to Postgres - unlike `websearch_to_tsquery`, plain `to_tsquery`
// errors on malformed syntax rather than degrading gracefully, so this can't just pass the raw
// search text through as-is. Empty (e.g. `search_text` was all punctuation) if nothing usable
// remains - callers should treat that the same as a missing/blank `search_text` altogether.
pub fn prefix_tsquery_text(search_text: &str) -> String {
    search_text
        .split_whitespace()
        .map(|word| word.chars().filter(|c| c.is_alphanumeric()).collect::<String>())
        .filter(|word| !word.is_empty())
        .map(|word| format!("{}:*", word))
        .collect::<Vec<_>>()
        .join(" & ")
}
