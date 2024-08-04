package main

import (
        "bufio"
        "flag"
        "fmt"
        "net/http"
        "os"
        "sort"
        "sync"
)

const (
        colorReset  = "\033[0m"
        colorRed    = "\033[31m"
        colorGreen  = "\033[32m"
)

var (
        noColor       bool
        outputFile    string
        emailFile     string
)

func checkURL(email string, wg *sync.WaitGroup, results chan<- string, emailResults chan<- string, sem chan struct{}) {
        defer wg.Done()
        defer func() { <-sem }()
        url := fmt.Sprintf("https://calendar.google.com/calendar/ical/%s/public/basic.ics", email)
        resp, err := http.Get(url)
        if err != nil {
                if !noColor {
                        fmt.Printf("%sError accessing: %s%s\n", colorRed, url, colorReset)
                } else {
                        fmt.Printf("Error accessing: %s\n", url)
                }
                return
        }
        defer resp.Body.Close()

        if resp.StatusCode == http.StatusOK {
                if !noColor {
                        fmt.Printf("%sAccessible: %s%s\n", colorGreen, url, colorReset)
                } else {
                        fmt.Printf("Accessible: %s\n", url)
                }
                results <- url // Send the full URL to results channel
                emailResults <- email // Send the email to emailResults channel
        } else {
                if !noColor {
                        fmt.Printf("%sNot accessible: %s%s\n", colorRed, url, colorReset)
                } else {
                        fmt.Printf("Not accessible: %s\n", url)
                }
        }
}

func main() {
        inputFile := flag.String("file", "", "Input file with email addresses")
        threads := flag.Int("threads", 10, "Number of concurrent threads")
        noColorFlag := flag.Bool("no-color", false, "Disable color output")
        outputFileFlag := flag.String("au", "", "File to save accessible URLs")
        emailFileFlag := flag.String("ae", "", "File to save accessible emails")

        flag.Parse()

        noColor = *noColorFlag
        outputFile = *outputFileFlag
        emailFile = *emailFileFlag

        var scanner *bufio.Scanner

        if *inputFile != "" {
                file, err := os.Open(*inputFile)
                if err != nil {
                        fmt.Println("Error opening file:", err)
                        return
                }
                defer file.Close()
                scanner = bufio.NewScanner(file)
        } else {
                scanner = bufio.NewScanner(os.Stdin)
        }

        var wg sync.WaitGroup
        results := make(chan string)
        emailResults := make(chan string)
        sem := make(chan struct{}, *threads)

        // Use maps to track unique URLs and emails
        urlMap := make(map[string]struct{})
        emailMap := make(map[string]struct{})

        go func() {
                for url := range results {
                        urlMap[url] = struct{}{}
                }
        }()

        go func() {
                for email := range emailResults {
                        emailMap[email] = struct{}{}
                }
        }()

        for scanner.Scan() {
                email := scanner.Text()
                sem <- struct{}{}
                wg.Add(1)
                go checkURL(email, &wg, results, emailResults, sem)
        }

        wg.Wait()
        close(results)
        close(emailResults)

        // Convert maps to slices and sort them
        var urls []string
        for url := range urlMap {
                urls = append(urls, url)
        }
        sort.Strings(urls)

        var emails []string
        for email := range emailMap {
                emails = append(emails, email)
        }
        sort.Strings(emails)

        // Write sorted URLs to file or print them
        if outputFile != "" {
                file, err := os.Create(outputFile)
                if err != nil {
                        fmt.Println("Error creating output file:", err)
                        return
                }
                defer file.Close()
                defer file.Sync()
                for _, url := range urls {
                        if !noColor {
                                file.WriteString(fmt.Sprintf("%sAccessible: %s%s\n", colorGreen, url, colorReset))
                        } else {
                                file.WriteString(fmt.Sprintf("Accessible: %s\n", url))
                        }
                }
        }

        // Write sorted emails to file
        if emailFile != "" {
                file, err := os.Create(emailFile)
                if err != nil {
                        fmt.Println("Error creating email file:", err)
                        return
                }
                defer file.Close()
                defer file.Sync()
                for _, email := range emails {
                        file.WriteString(email + "\n")
                }
        }

        if err := scanner.Err(); err != nil {
                fmt.Println("Error reading input:", err)
        }
}