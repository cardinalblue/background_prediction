package main

import (
	"bytes"
	"encoding/json"
	"html/template"
	"io"
	"io/ioutil"
	"log"
	"mime/multipart"
	"net/http"
)

func main() {
	jsonError("/Predict", Predict)
	http.HandleFunc("/", Root)
	if err := http.ListenAndServe(":11211", nil); err != nil {
		log.Fatalf("%v", err)
	}
}

var rootTmpl = template.Must(template.ParseFiles("tmpl/Root.html"))

func Root(w http.ResponseWriter, r *http.Request) {
	page := struct {
	}{}
	rootTmpl.Execute(w, page)
}

func Predict(w http.ResponseWriter, r *http.Request) *appError {
	f, fh, err := r.FormFile("f")
	if err != nil {
		return &appError{Message: err.Error(), Code: http.StatusBadRequest}
	}
	defer f.Close()

	reqbody := &bytes.Buffer{}
	writer := multipart.NewWriter(reqbody)
	part, err := writer.CreateFormFile("f", fh.Filename)
	if err != nil {
		return &appError{Message: err.Error(), Code: http.StatusInternalServerError}
	}
	if _, err := io.Copy(part, f); err != nil {
		return &appError{Message: err.Error(), Code: http.StatusInternalServerError}
	}
	if err := writer.Close(); err != nil {
		return &appError{Message: err.Error(), Code: http.StatusInternalServerError}
	}
	resp, err := http.Post("http://127.0.0.1:1463/", writer.FormDataContentType(), reqbody)
	if err != nil {
		return &appError{Message: err.Error(), Code: http.StatusInternalServerError}
	}
	b, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return &appError{Message: err.Error(), Code: http.StatusInternalServerError}
	}
	jresp := struct{ Bg string }{}
	if err := json.Unmarshal(b, &jresp); err != nil {
		return &appError{Message: err.Error(), Code: http.StatusInternalServerError}
	}
	if jresp.Bg == "unknown" {
		w.Write([]byte("unknown"))
		return nil
	}
	log.Printf(jresp.Bg)

	bg, err := ioutil.ReadFile("backgrounds/" + jresp.Bg)
	if err != nil {
		return &appError{Message: err.Error(), Code: http.StatusInternalServerError}
	}
	w.Write(bg)
	return nil
}

type appError struct {
	Message string
	Code    int
}

func (a *appError) Error() string {
	return a.Message
}

func jsonError(path string, fn func(w http.ResponseWriter, r *http.Request) *appError) {
	jsonErrorServeMux(http.DefaultServeMux, path, fn)
}

func jsonErrorServeMux(sm *http.ServeMux, path string, fn func(w http.ResponseWriter, r *http.Request) *appError) {
	sm.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		appErr := fn(w, r)
		if appErr != nil {
			je := struct {
				Error string `json:"error"`
			}{
				Error: appErr.Message,
			}
			b, _ := json.Marshal(&je)
			http.Error(w, string(b), appErr.Code)
		}
	})
}
