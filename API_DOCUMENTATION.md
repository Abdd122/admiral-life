# Custom Server API Documentation

This document outlines the API endpoints for the custom server that supports the hybrid social app.

---

## **Authentication**

All endpoints that require authentication must include a Firebase ID Token in the `Authorization` header:

`Authorization: Bearer <FirebaseIdToken>`

The server will verify this token to authenticate the user.

---

## **Endpoints**

### 1. Upload Profile Picture

*   **Endpoint:** `POST /upload/profile`
*   **Description:** Uploads a new profile picture for the authenticated user.
*   **Authentication:** Required.
*   **Request:**
    *   **Method:** `POST`
    *   **Content-Type:** `multipart/form-data`
    *   **Body:**
        *   `file`: The image file to upload (e.g., JPEG, PNG).
*   **Success Response (200 OK):**
    *   **Content-Type:** `application/json`
    *   **Body:**
        ```json
        {
          "status": "success",
          "message": "Profile picture uploaded successfully.",
          "data": {
            "imageUrl": "https://your-server.com/path/to/image.jpg"
          }
        }
        ```
*   **Error Response (4xx/5xx):**
    *   **Content-Type:** `application/json`
    *   **Body:**
        ```json
        {
          "status": "error",
          "message": "A description of the error."
        }
        ```

---

### 2. Upload Payment Receipt

*   **Endpoint:** `POST /upload/receipt`
*   **Description:** Uploads a receipt image for a manual payment request. The server will create a `paymentRequest` document in Firestore after a successful upload.
*   **Authentication:** Required.
*   **Request:**
    *   **Method:** `POST`
    *   **Content-Type:** `multipart/form-data`
    *   **Body:**
        *   `file`: The image file of the receipt.
        *   `packageId`: The ID of the `CoinPackage` the user is purchasing.
*   **Success Response (200 OK):**
    *   **Content-Type:** `application/json`
    *   **Body:**
        ```json
        {
          "status": "success",
          "message": "Payment request submitted successfully.",
          "data": {
            "paymentRequestId": "firestore_document_id_of_the_request"
          }
        }
        ```
*   **Error Response (4xx/5xx):**
    *   **Content-Type:** `application/json`
    *   **Body:**
        ```json
        {
          "status": "error",
          "message": "A description of the error."
        }
        ```

---

### 3. Generate Agora Token

*   **Endpoint:** `GET /agora/token`
*   **Description:** Generates an Agora RTC token for a user to join a specific channel.
*   **Authentication:** Required.
*   **Request:**
    *   **Method:** `GET`
    *   **Query Parameters:**
        *   `channelName`: The name of the channel the user wants to join.
*   **Success Response (200 OK):**
    *   **Content-Type:** `application/json`
    *   **Body:**
        ```json
        {
          "status": "success",
          "data": {
            "token": "<GeneratedAgoraToken>"
          }
        }
        ```
*   **Error Response (4xx/5xx):**
    *   **Content-Type:** `application/json`
    *   **Body:**
        ```json
        {
          "status": "error",
          "message": "A description of the error."
        }
        ```

---
