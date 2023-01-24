
type RegExpErrorMatcher = {
  regex: RegExp,
  handler: (matches: RegExpMatchArray) => string,
}

const grpcErrorConversions: RegExpErrorMatcher[] = [
  {
    regex: RegExp('^([\\w]+)_too_short_min_?([\\d]+)$'),
    handler: (matches) => `${capitalize(matches[1]!)} must be at least ${matches[2]} character${sIfPlural(matches[2]!, {})}.`
  },
  {
    regex: RegExp('^([\\w]+)_too_long_max_?([\\d]+)$'),
    handler: (matches) => `${capitalize(matches[1]!)} must be less than ${matches[2]} character${sIfPlural(matches[2]!, {})}.`
  },
  {
    regex: RegExp('^global_public_users_require_PUBLISH_USERS_GLOBALLY_permission$'),
    handler: (_matches) => '"Global Public" user visibility requires "Globally Publish Profile" permission.',
  },
  {
    regex: RegExp('^[\\w]+$'),
    handler: (matches) => `${capitalize(matches[0]).replaceAll('_', ' ')}.`
  },
];

export function formatError ( error : Error ) : string { 
  var message = error.message;
  grpcErrorConversions.forEach(({regex, handler}) => {
    let matches = message.match(regex);
    if (matches) {
      message = handler(matches);
    }
  });
  return message;
}

function capitalize(str: string){
  return str.charAt(0).toUpperCase() + str.slice(1);
}
const sIfPlural = (s: string, {suffix = 's'}) => s == '1' ? '' : suffix;
