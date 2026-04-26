const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {RtcTokenBuilder, RtcRole} = require("agora-token");

admin.initializeApp();

// WARNING: For demonstration purposes, we are hardcoding keys.
// For production, use environment variables or a secure key management system.
const APP_ID = "49b0b00483ea4bd98e4e889bb8f67452";
const APP_CERTIFICATE = "955d775e2e344d0ca24e0192c455bd3f";

/**
 * Generates an Agora RTC token when a user calls this function.
 * 
 * @param {object} data - The data passed to the function, expecting `channelName`.
 * @param {functions.https.CallableContext} context - The context of the call, including auth info.
 * @returns {string} The generated Agora token.
 */
exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
  // Check if the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'The function must be called while authenticated.'
    );
  }

  const channelName = data.channelName;
  if (!channelName) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with a "channelName" argument.'
    );
  }

  // Agora user ID can be an integer or a string. We'll use the Firebase UID.
  const uid = context.auth.uid;
  
  // Token valid for 1 hour (3600 seconds)
  const expirationTimeInSeconds = 3600;
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  // Generate the token
  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
        APP_ID, 
        APP_CERTIFICATE, 
        channelName, 
        uid, // Use Firebase UID as the Agora UID
        RtcRole.PUBLISHER, // The user can publish and subscribe to streams
        privilegeExpiredTs
    );
    
    console.log(`Token generated for channel: ${channelName}, user: ${uid}`);
    return { token: token };

  } catch (error) {
    console.error("Error generating Agora token:", error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate Agora token.'
    );
  }
});