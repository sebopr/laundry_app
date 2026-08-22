import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

const ANDROID_PACKAGE = "com.example.lavaplan";

/**
 * Bridges Apple's "Sign in with Apple" web callback back into the Android
 * app. Android has no native Apple ID API, so sign_in_with_apple opens a
 * browser to Apple's login page with this function's URL as the redirect
 * target (must match the Services ID's Return URL in the Apple Developer
 * portal exactly). Apple POSTs the auth result here; we bounce it into the
 * app via the intent:// scheme the package's SignInWithAppleCallback
 * activity listens for.
 */
export const appleSignInCallback = onRequest(
  { region: "europe-west6" },
  (req, res) => {
    const params = (req.method === "POST" ? req.body : req.query) as Record<
      string,
      string
    >;

    if (!params || Object.keys(params).length === 0) {
      logger.warn("Apple sign-in callback received with no parameters");
      res.status(400).send("Missing callback parameters");
      return;
    }

    const query = new URLSearchParams(params).toString();
    const intentUrl =
      `intent://callback?${query}` +
      `#Intent;package=${ANDROID_PACKAGE};scheme=signinwithapple;end`;

    res.redirect(intentUrl);
  }
);
