import { useEffect } from "react";

import { createParam } from "solito";

const { useParam: useTokenParam } = createParam<{ anonymousAuthToken: string }>()

// Parse/process and use the anonymousAuthToken query parameter.
//
// The parameter should be of either the form: 
// * <authToken1> 
//    * Here, the occasionId must be in other path components. This is used for saveable links.
// * <occasionId1>-<authToken1>--<occasionId2>-<authToken2>--<occasionId3>-<authToken3>
//    * Here, multiple occasions' auth tokens can be stored in a single query parameter.
//      Multiple EventRsvpManagers on the same page can share the same query parameter
//      and manage multiple simultaenous auth tokens. (Note that each EventRsvpManager
//      on the page is still assumed to have a distinct Occasion.)
export function useAnonymousAuthToken(occasionId: string) {
  const [_queryAnonAuthToken, _setQueryAnonAuthToken] = useTokenParam('anonymousAuthToken');
  const tokenPairSeparator = '--';
  const occasionTokenSeparator = '-';
  // [occasionId, authToken][]
  const anonymousAuthTokens = (_queryAnonAuthToken ?? '').split(tokenPairSeparator)
    .map(t => t.trim().split(occasionTokenSeparator))
    .filter(t => t[0] && t[0].length > 0) as [string, string][];
  function setAnonymousAuthToken(token: string) {
    if (!token) {
      removeAnonymousAuthToken();
      return;
    };

    const updatedTokens = [
      ...anonymousAuthTokens.filter(t => t[0] != occasionId)
        .map(t => t.join(occasionTokenSeparator)),
      `${occasionId}${occasionTokenSeparator}${token}`
    ];
    _setQueryAnonAuthToken(updatedTokens.join(tokenPairSeparator));
  }
  function removeAnonymousAuthToken() {
    const updatedTokens = anonymousAuthTokens.filter(t => occasionId && t[0] === occasionId);
    _setQueryAnonAuthToken(updatedTokens.join(tokenPairSeparator));
  }
  const firstAuthToken = anonymousAuthTokens[0];
  useEffect(() => {
    // console.log("firstAuthToken", firstAuthToken);
    if (firstAuthToken && firstAuthToken[0].length > 0 && !firstAuthToken[1]) {
      const updatedTokens = [
        `${occasionId}${occasionTokenSeparator}${firstAuthToken[0]}`,
        ...anonymousAuthTokens.slice(1).map(t => t.join(occasionTokenSeparator)),
      ];
      _setQueryAnonAuthToken(updatedTokens.join(tokenPairSeparator));
    }
  }, [firstAuthToken]);

  const token = anonymousAuthTokens.find(t => t[0] === occasionId)?.[1];
  const anonymousAuthToken = token && token.length > 0 ? token : undefined;

  return { anonymousAuthToken, setAnonymousAuthToken, removeAnonymousAuthToken };
}
