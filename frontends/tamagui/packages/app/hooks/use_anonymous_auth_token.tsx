import { useEffect } from "react";

import { createParam } from "solito";

const { useParam: useTokenParam } = createParam<{ anonymousAuthToken: string }>()

// Parse/process and use the anonymousAuthToken query parameter.
//
// The parameter should be of either the form: 
// * <authToken1> 
//    * Here, the instanceId must be in other path components. This is used for saveable links.
// * <instanceId1>-<authToken1>--<instanceId2>-<authToken2>--<instanceId3>-<authToken3>
//    * Here, multiple instances' auth tokens can be stored in a single query parameter.
//      Multiple EventRsvpManagers on the same page can share the same query parameter
//      and manage multiple simultaenous auth tokens. (Note that each EventRsvpManager
//      on the page is still assumed to have a distinct EventInstance.)
export function useAnonymousAuthToken(eventInstanceId: string) {
  const [_queryAnonAuthToken, _setQueryAnonAuthToken] = useTokenParam('anonymousAuthToken');
  const tokenPairSeparator = '--';
  const instanceTokenSeparator = '-';
  // [instanceId, authToken][]
  const anonymousAuthTokens = (_queryAnonAuthToken ?? '').split(tokenPairSeparator)
    .map(t => t.trim().split(instanceTokenSeparator))
    .filter(t => t[0] && t[0].length > 0) as [string, string][];
  function setAnonymousAuthToken(token: string) {
    if (!token) {
      removeAnonymousAuthToken();
      return;
    };

    const updatedTokens = [
      ...anonymousAuthTokens.filter(t => t[0] != eventInstanceId)
        .map(t => t.join(instanceTokenSeparator)),
      `${eventInstanceId}${instanceTokenSeparator}${token}`
    ];
    _setQueryAnonAuthToken(updatedTokens.join(tokenPairSeparator));
  }
  function removeAnonymousAuthToken() {
    const updatedTokens = anonymousAuthTokens.filter(t => eventInstanceId && t[0] === eventInstanceId);
    _setQueryAnonAuthToken(updatedTokens.join(tokenPairSeparator));
  }
  const firstAuthToken = anonymousAuthTokens[0];
  useEffect(() => {
    // console.log("firstAuthToken", firstAuthToken);
    if (firstAuthToken && firstAuthToken[0].length > 0 && !firstAuthToken[1]) {
      const updatedTokens = [
        `${eventInstanceId}${instanceTokenSeparator}${firstAuthToken[0]}`,
        ...anonymousAuthTokens.slice(1).map(t => t.join(instanceTokenSeparator)),
      ];
      _setQueryAnonAuthToken(updatedTokens.join(tokenPairSeparator));
    }
  }, [firstAuthToken]);
  const anonymousAuthToken = anonymousAuthTokens.find(t => t[0] === eventInstanceId)?.[1];

  return { anonymousAuthToken, setAnonymousAuthToken, removeAnonymousAuthToken };
}
