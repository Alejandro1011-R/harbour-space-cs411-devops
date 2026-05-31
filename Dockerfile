FROM golang:1.24
WORKDIR /app
COPY . .
RUN go build -o main main.go
EXPOSE 4444
CMD ["./main"]