import { BaseServerDetailsScreen } from '../accounts/server_details_screen';

export function AboutScreen() {
  return BaseServerDetailsScreen(physicallyHostingServerId());
}

export const physicallyHostingServerId=() => `${location.protocol}${location.host.split(':')[0]}`;