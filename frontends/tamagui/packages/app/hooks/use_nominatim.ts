import { useQuery } from '@tanstack/react-query';

export interface NominatimResult {
  boundingbox: Array<string>;
  category?: string;
  display_name: string;
  importance: number;
  lat: string;
  licence: string;
  lon: string;
  osm_id: number;
  osm_type: string;
  place_id: string;
  place_rank: number;
  type: string;
}

/**
 * Hook that allows you to look up a location from a textual description or address in `Open street map` `Nominatim` service.
 * Nominatim supports structured and free-form search queries.
 * 
 * Read `https://operations.osmfoundation.org/policies/nominatim/` to avoid to get you banned.
 * > [...]
 * > No heavy uses (an absolute maximum of 1 request per second).
 * > [...]
 * 
 * > Unacceptable Use
 * > The following uses are strictly forbidden and will get you banned:
 * > - Auto-complete search: This is not yet supported by Nominatim and you must not implement such a service on the client side using the API.
 * > - Systematic queries: This includes reverse queries in a grid, searching for complete lists of postcodes, towns etc. and downloading all POIs in an area.
 *
 * @param query Free-form query string to search for.
 * Free-form queries are processed first left-to-right and then right-to-left if that fails.
 * So you may search for `pilkington avenue, birmingham` as well as for `birmingham, pilkington avenue`.
 * Commas are optional, but improve performance by reducing the complexity of the search.
 * > See: https://nominatim.org/release-docs/develop/api/Search/#parameters
 *
 * @param countryCodes list of "ISO 3166-1alpha2" country codes.
 * > See: https://nominatim.org/release-docs/develop/api/Search/#result-limitation
 * 
 * @returns A list of `Json2` results.
 * > See: https://nominatim.org/release-docs/develop/api/Output/#jsonv2
 */
export function useNominatim(
  query: string,
  countryCodes: string[],
): [boolean, boolean, Partial<NominatimResult[]> | undefined, () => Promise<NominatimResult[] | undefined>] {
  const { isLoading, isFetching, isError, data, refetch } = useQuery({
    queryKey: ['OpenStreetMapNominatim', query],
    queryFn: () => {
      // console.log('starting query', query);
      if (!query) {
        return [];
      }

      const url = `https://nominatim.openstreetmap.org/search?format=jsonv2&q=${query}&countrycodes=${countryCodes.join(
        ',',
      )}`;

      const result = fetch(url)
        .then((x) => {
          const y = x.json();
          return y;
        })
        .then((x) => {
          return x as NominatimResult[];
        });

      console.log('nominatim result', result);
      return result;
    },
    staleTime: 0,
    enabled: true,
    // cacheTime: 0,
    refetchOnWindowFocus: false,
  },);

  const fetchFn = () => refetch().then((x) => x.data);

  return [isLoading || isFetching, isError, data, fetchFn];
}
