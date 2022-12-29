#!/bin/bash

# This script is used to launch Jonline and warmup the
# compression cache for large files like main.dart.js.
# It loads the files serially immediately after server startup,
# reducing load on the server seen when a browser requests all the
# data at once on different HTTP threads.

# It would be cleaner to integrate this into Rust code in the server.
# But bash/UNIX forks are super easy, and this is a very simple solution
# that only uses the "jonline" and "curl" commands.

HOST=http://localhost:8000
# HOST=https://jonline.io

function warmup_cache() {
  sleep 7
  echo "Pre-compressing large FE files..."
  curl "$HOST/app/main.dart.js" --output /dev/null
  curl "$HOST/app/manifest.json" --output /dev/null
  curl "$HOST/app/flutter.js" --output /dev/null
  curl "$HOST/app" --output /dev/null

  curl "$HOST/app/assets/fonts/MaterialIcons-Regular.otf" --output /dev/null

  curl "$HOST/app/assets/fonts/PublicSans-Thin.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-ThinItalic.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-ExtraLight.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-ExtraLightItalic.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-Light.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-LightItalic.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-Regular.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-Italic.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-Medium.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-MediumItalic.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-SemiBold.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-SemiBoldItalic.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-Bold.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-BoldItalic.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-ExtraBold.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-ExtraBoldItalic.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-Black.otf" --output /dev/null
  curl "$HOST/app/assets/fonts/PublicSans-BlackItalic.otf" --output /dev/null
}

warmup_cache &
echo "Launching Jonline..."
/opt/jonline
# sleep 10
echo "Jonline has shut down."
