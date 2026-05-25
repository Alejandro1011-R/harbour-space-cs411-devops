# Reflection — introduction-to-builds

## What did I do?
I started creating the `main.go` file with the provided code. I ran `apt update` and `apt install -y golang` to get the toolchain. After that, I ran `go build -o main main.go` successfully compiled the source into a binary executable. I ran `./main` in the foreground, and verified it was working by hitting it with `curl` to see the JSON output on port 4444. Then I cross-compiled an ARM64 version (`main-arm64`), stripped the debug symbols to reduce the file size (`main-stripped`), and wrote a Ruby equivalent (`app.rb`) using the Sinatra framework, which required manually installing the Ruby runtime and gems.

## What was most surprising?
The most surprising detail was seeing the actual file size difference between the stripped and non-stripped binaries. Running `du -b` showed that `main` was around 7.8MB while `main-stripped` was only 5.4MB — a reduction of roughly 30%. The trade-off is clear: you gain a smaller deployment artifact but lose the ability to get meaningful stack traces and debugging symbols if the binary crashes in production. It crystallized how much metadata the Go toolchain embeds by default, and why production builds often strip it out.

## Ruby Version 
The concrete difference in deployment requirements was striking: to run the Go binary (`./main`), I needed nothing but the bare operating system — the compiler packed everything into a standalone executable. To run the Ruby script (`app.rb`), I had to install the Ruby interpreter (`ruby-full`) and the Sinatra gem on the machine. An interpreted language requires you to build the execution environment on the host, whereas the compiled Go binary handles all of that upfront.

## What's still unclear?
While I successfully ran the command to cross-compile the application for ARM64, the internal mechanics of Go's cross-compilation remain unclear to me. Specifically, I don't fully understand how the Go linker manages to generate an ARM-compatible binary on an AMD64 machine without me needing to manually install a dedicated, target-specific C-toolchain.