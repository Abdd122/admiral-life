package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
)

func main() {
	log.Print("starting file server...")

	// Create uploads directory if it doesn't exist
	if _, err := os.Stat("./uploads"); os.IsNotExist(err) {
		os.Mkdir("./uploads", 0755)
	}

	// Endpoint for serving files
	fs := http.FileServer(http.Dir("./uploads"))
	http.Handle("/files/", http.StripPrefix("/files/", fs))

	// Endpoint for uploading files
	http.HandleFunc("/upload", uploadHandler)

	// Determine port for HTTP service.
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
		log.Printf("defaulting to port %s", port)
	}

	// Start HTTP server.
	log.Printf("listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func uploadHandler(w http.ResponseWriter, r *http.Request) {
	// Helper function to send a structured JSON error response
	sendError := func(w http.ResponseWriter, message string, statusCode int) {
		log.Printf("ERROR: %s", message)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(statusCode)
		json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": message})
	}

	if r.Method != http.MethodPost {
		sendError(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the multipart form with a 10MB limit
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		sendError(w, "Could not parse multipart form: "+err.Error(), http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		sendError(w, "Invalid file in form payload", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Generate a random unique name for the file to prevent collisions
	randomBytes := make([]byte, 16)
	if _, err := rand.Read(randomBytes); err != nil {
		sendError(w, "Internal error: could not generate random name", http.StatusInternalServerError)
		return
	}
	randomName := hex.EncodeToString(randomBytes) + filepath.Ext(header.Filename)

	// Create a new file in the uploads directory
	dst, err := os.Create(filepath.Join("./uploads", randomName))
	if err != nil {
		sendError(w, "Internal error: could not create file on server", http.StatusInternalServerError)
		return
	}
	defer dst.Close()

	// Copy the uploaded file to the destination file
	if _, err := io.Copy(dst, file); err != nil {
		sendError(w, "Internal error: could not save file", http.StatusInternalServerError)
		return
	}

	// The file path that the client can use to retrieve the file
	filePath := fmt.Sprintf("/files/%s", randomName)
	log.Printf("File uploaded successfully. Path: %s", filePath)

	// Send success response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "success",
		"filePath": filePath,
	})
}
