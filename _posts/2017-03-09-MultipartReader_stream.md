---
layout: post
title: MultipartReader process the request body as a stream example.
description: MultipartReadert has almost no examples on the Internet, especially about parsing request body as stream.
categories:
- 技术
tags:
- go
---

```
		var maxFileSize int64 = 10 * 1000 * 1000 //limit upload file to 10m
		if r.ContentLength > maxFileSize {
			http.Error(w, "request too large", http.StatusExpectationFailed)
			return
		}
		r.Body = http.MaxBytesReader(w, r.Body, maxFileSize)

		multipartReader, err := r.MultipartReader()
		if err != nil {
			logger.Errorln(err)
			return
		}
		var uploadfile *multipart.Part
		var token string
		for i := 0; i < 2; i++ {
			part, err := multipartReader.NextPart()
			if err == io.EOF {
				break
			}

			if part.FormName() == "token" {
				buf := new(bytes.Buffer)
				buf.ReadFrom(part)
				token = buf.String()
			} else if part.FormName() == "uploadfile" {
				uploadfile = part
			}
		}
```

In this time, uploadfile implement io.Reader, so we could read it as stream

```
	r := csv.NewReader(uploadfile)
	record, err := r.Read()
	logger.Debugln("record is ", record)
	if err == io.EOF {
		return err
	}
```
